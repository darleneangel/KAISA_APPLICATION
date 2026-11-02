import 'dart:convert';
import 'dart:async';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Offline scans are provisional. Download roster before losing signal.
/// The cached roster holds token hashes only. Queue is secured at rest by
/// flutter_secure_storage, though an unlocked compromised device remains a risk.
class KaisaAttendanceScannerPage extends StatefulWidget {
  const KaisaAttendanceScannerPage({super.key});
  @override
  State<KaisaAttendanceScannerPage> createState() =>
      _KaisaAttendanceScannerPageState();
}

class _KaisaAttendanceScannerPageState
    extends State<KaisaAttendanceScannerPage> {
  static const _forest = Color(0xFF14532D);
  static const _storage = FlutterSecureStorage();
  final _client = Supabase.instance.client;
  final _scanner = MobileScannerController(
    autoStart: false,
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  final _uuid = const Uuid();
  Timer? _syncTimer;
  String get _uid => _client.auth.currentUser?.id ?? '';
  String get _storageKey => 'kaisa_offline_scanner_$_uid';
  List<Map<String, dynamic>> _events = [];
  Map<String, dynamic>? _roster;
  List<Map<String, dynamic>> _pending = [];
  String? _eventId, _message;
  String? _lastScannedToken;
  DateTime? _lastScannedAt;
  String _action = 'check_in';
  bool _busy = false, _scannerOn = false, _offline = false;

  @override
  void initState() {
    super.initState();
    _restore();
    _loadEvents();
    _syncTimer = Timer.periodic(const Duration(seconds: 35), (_) {
      if (!_busy && _pending.isNotEmpty) _sync();
    });
  }

  Future<void> _restore() async {
    try {
      final raw = await _storage.read(key: _storageKey);
      if (raw == null || !mounted) return;
      final data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      setState(() {
        _roster = data['roster'] == null
            ? null
            : Map<String, dynamic>.from(data['roster'] as Map);
        _pending = (data['pending'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _eventId ??= _roster?['event_id']?.toString();
      });
    } catch (e) {
      if (mounted)
        setState(() => _message = 'Could not read secure offline cache: $e');
    }
    if (_pending.isNotEmpty) _sync();
  }

  Future<void> _persist() async {
    await _storage.write(
      key: _storageKey,
      value: jsonEncode({'roster': _roster, 'pending': _pending}),
    );
  }

  Future<void> _loadEvents() async {
    try {
      final result = await _client.rpc('kaisa_scanner_events');
      final items = (result as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (!mounted) return;
      setState(() {
        _events = items;
        if (_eventId == null && items.isNotEmpty)
          _eventId = '${items.first['event_id']}';
        _offline = false;
      });
    } catch (_) {
      if (mounted) setState(() => _offline = true);
    }
  }

  Future<void> _downloadRoster() async {
    if (_busy || _eventId == null) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final response = await _client.rpc(
        'kaisa_offline_roster',
        params: {'p_event_id': _eventId},
      );
      final data = Map<String, dynamic>.from(response as Map);
      // Preserve unsynced scans; do not silently change their event assignment.
      if (!mounted) return;
      setState(() {
        _roster = data;
        _offline = false;
      });
      await _persist();
      if (mounted)
        setState(
          () => _message =
              'Offline roster saved securely. You can now scan without internet.',
        );
    } catch (e) {
      if (mounted) setState(() => _message = 'Roster download failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy || !_scannerOn || _eventId == null) return;
    final code = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .where(
          (raw) => raw.startsWith('KAISA1:') || raw.startsWith('KAISAOFF2:'),
        )
        .firstOrNull;
    if (code == null) return;
    final online = RegExp(r'^KAISA1:[0-9a-f]{64}$').hasMatch(code);
    final offlinePass = RegExp(r'^KAISAOFF2:[0-9a-f]{64}$').hasMatch(code);
    if (!online && !offlinePass) {
      setState(() => _message = 'Unrecognized KAISA QR format.');
      return;
    }
    final now = DateTime.now();
    if (_lastScannedToken == code &&
        _lastScannedAt != null &&
        now.difference(_lastScannedAt!) < const Duration(seconds: 3)) {
      return;
    }
    _lastScannedToken = code;
    _lastScannedAt = now;
    setState(() {
      _busy = true;
      _scannerOn = false;
      _message = null;
    });
    await _scanner.stop();
    try {
      if (online) {
        // Always validate and record online QR credentials on the server.
        // The server checks scanner permissions, event registration,
        // active session times, and consumes successful QR credentials.
        final result = await _client.rpc(
          'kaisa_scan_attendance',
          params: {
            'p_event_id': _eventId,
            'p_token': code,
            'p_action': _action,
          },
        );
        if (!mounted) return;
        final record = Map<String, dynamic>.from(result as Map);
        setState(() {
          _offline = false;
          _message =
              'CONFIRMED · ${record['resident_name'] ?? 'Resident'} · '
              '${_action == 'check_in' ? 'Checked in' : 'Checked out'}';
        });
      } else {
        // Offline credentials must match a pre-downloaded roster.
        // The queue is provisional until server synchronization succeeds.
        final roster = _roster;
        if (roster == null || '${roster['event_id']}' != _eventId) {
          throw StateError(
            'Download the selected event roster before offline scanning.',
          );
        }
        final utcNow = now.toUtc();
        final opens = DateTime.parse('${roster['opens_at']}');
        final closes = DateTime.parse('${roster['closes_at']}');
        if (utcNow.isBefore(opens) || utcNow.isAfter(closes)) {
          throw StateError('Attendance session is not active.');
        }
        final hash = sha256.convert(utf8.encode(code)).toString();
        final entries = roster['entries'] as List? ?? [];
        final valid = entries.any(
          (entry) =>
              entry is Map &&
              '${entry['hash']}' == hash &&
              DateTime.tryParse('${entry['expires_at']}')?.isAfter(utcNow) ==
                  true,
        );
        if (!valid) {
          throw StateError(
            'Offline QR is unknown or expired; refresh the event roster online.',
          );
        }
        final duplicate = _pending.any(
          (entry) =>
              '${entry['hash']}' == hash &&
              '${entry['action']}' == _action &&
              '${entry['event_id']}' == _eventId,
        );
        if (duplicate) throw StateError('This action is already pending sync.');
        final operation = <String, dynamic>{
          'operation_id': _uuid.v4(),
          'event_id': _eventId,
          'token': code,
          'hash': hash,
          'action': _action,
          'scanned_at': utcNow.toIso8601String(),
        };
        _pending.add(operation);
        await _persist();
        if (mounted) {
          setState(
            () => _message =
                'OFFLINE · Pending synchronization (${_pending.length}). '
                'Not yet official attendance.',
          );
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() => _message = 'Scan not recorded: $error');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sync() async {
    if (_busy || _pending.isEmpty) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    var synced = 0;
    String? lastError;
    // Preserve ordering: check-in must reach server before check-out.
    for (final op in List<Map<String, dynamic>>.from(_pending)) {
      try {
        await _client.rpc(
          'kaisa_sync_offline_scan',
          params: {
            'p_operation_id': op['operation_id'],
            'p_event_id': op['event_id'],
            'p_token': op['token'],
            'p_action': op['action'],
            'p_scanned_at': op['scanned_at'],
          },
        );
        _pending.removeWhere((e) => e['operation_id'] == op['operation_id']);
        await _persist();
        synced++;
      } catch (e) {
        lastError = e.toString();
        break; // do not discard rejected scans; staff must review the queue
      }
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _offline = lastError != null;
      _message = lastError == null
          ? '$synced scan(s) confirmed by Supabase. ${_pending.length} remaining.'
          : '$synced synced, ${_pending.length} still pending. Review error: $lastError';
    });
  }

  Future<void> _resume() async {
    if (_busy || _eventId == null) return;
    setState(() {
      _scannerOn = true;
      _message = null;
    });
    try {
      // Let MobileScanner mount before starting its controller.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || !_scannerOn) return;
      await _scanner.start();
    } catch (e) {
      if (mounted) {
        setState(() {
          _scannerOn = false;
          _message = 'Camera error: $e';
        });
      }
    }
  }

  Future<void> _stopCamera() async {
    setState(() => _scannerOn = false);
    await _scanner.stop();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _scanner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rosterEvent = _roster?['event_id']?.toString();
    final eventOptions = <String, String>{
      for (final e in _events) '${e['event_id']}': '${e['title']}',
      if (rosterEvent != null &&
          !_events.any((e) => '${e['event_id']}' == rosterEvent))
        rosterEvent: 'Saved offline event',
    };
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 80),
            children: [
              const Text(
                'EVENT ATTENDANCE',
                style: TextStyle(
                  color: Color(0xFF237A50),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Scan resident QR passes',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: _forest,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: Icon(
                    _offline ? Icons.wifi_off : Icons.wifi,
                    color: _forest,
                  ),
                  title: Text(
                    _offline
                        ? 'Offline / connection unavailable'
                        : 'Roster available for offline use',
                  ),
                  subtitle: Text(
                    'Pending synchronization: ${_pending.length} · Offline results are provisional',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (eventOptions.isNotEmpty)
                DropdownButtonFormField<String>(
                  key: ValueKey(_eventId),
                  initialValue: eventOptions.containsKey(_eventId)
                      ? _eventId
                      : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Assigned event',
                    border: OutlineInputBorder(),
                  ),
                  items: eventOptions.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: _busy
                      ? null
                      : (v) async {
                          if (_scannerOn) await _stopCamera();
                          if (mounted) setState(() => _eventId = v);
                        },
                ),
              if (eventOptions.isEmpty)
                const Text(
                  'No assigned events cached. Connect to the internet to load your assigned events.',
                ),
              const SizedBox(height: 12),
              const Text(
                'Online QR (KAISA1) scans immediately through Supabase. '
                'Offline event passes (KAISAOFF2) require a downloaded roster and remain pending until synced.',
                style: TextStyle(fontSize: 12, color: _forest),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy || _eventId == null ? null : _downloadRoster,
                icon: const Icon(Icons.download_for_offline),
                label: const Text('Prepare / refresh offline roster'),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'check_in',
                    label: Text('Check in'),
                    icon: Icon(Icons.login),
                  ),
                  ButtonSegment(
                    value: 'check_out',
                    label: Text('Check out'),
                    icon: Icon(Icons.logout),
                  ),
                ],
                selected: {_action},
                onSelectionChanged: _busy
                    ? null
                    : (s) => setState(() => _action = s.first),
              ),
              const SizedBox(height: 12),
              if (_eventId != null)
                Container(
                  height: 315,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _scannerOn
                      ? MobileScanner(controller: _scanner, onDetect: _onDetect)
                      : const Center(
                          child: Icon(
                            Icons.qr_code_scanner,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                ),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(_message!),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _busy || _eventId == null
                    ? null
                    : (_scannerOn ? _stopCamera : _resume),
                icon: Icon(
                  _scannerOn
                      ? Icons.stop_circle_outlined
                      : Icons.qr_code_scanner,
                ),
                label: Text(
                  _scannerOn ? 'Stop Camera' : 'Start Camera / Scan Next',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _busy || _pending.isEmpty ? null : _sync,
                icon: const Icon(Icons.sync),
                label: Text('Sync ${_pending.length} pending scan(s)'),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _busy ? null : _loadEvents,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh assigned events'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Before leaving internet coverage: each resident downloads an event pass and each scanner downloads the event roster. Only staff assigned to the event can download its roster. Revocations and remote changes cannot be detected while offline. Scans must sync within 72 hours and may require review.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
