import 'dart:convert';
import 'dart:async';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Offline scans are provisional. Download roster before losing signal.
/// The cached roster holds token hashes only. Queue is secured at rest by
/// flutter_secure_storage, though an unlocked compromised device remains a risk.
class _LiveAttendanceScannerPage extends StatefulWidget {
  const _LiveAttendanceScannerPage({required this.onMock});
  final VoidCallback? onMock;
  @override
  State<_LiveAttendanceScannerPage> createState() =>
      _LiveAttendanceScannerPageState();
}

class _LiveAttendanceScannerPageState
    extends State<_LiveAttendanceScannerPage> {
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
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _initialize();
    _syncTimer = Timer.periodic(const Duration(seconds: 35), (_) {
      if (!_initializing && !_busy && _pending.isNotEmpty) _sync();
    });
  }

  Future<void> _initialize() async {
    await _restore();
    if (!mounted) return;
    await _loadEvents();
    if (mounted) setState(() => _initializing = false);
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
      if (mounted) {
        setState(() => _message = 'Could not read secure offline cache: $e');
      }
    }
    if (mounted && _pending.isNotEmpty) await _sync();
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
        if (_eventId == null && items.isNotEmpty) {
          _eventId = '${items.first['event_id']}';
        }
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
      if (mounted) {
        setState(
          () => _message =
              'Offline roster saved securely. You can now scan without internet.',
        );
      }
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
    try {
      await _scanner.stop();
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
    if (_initializing) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 80),
            children: [
              if (widget.onMock != null)
                Card(child: SwitchListTile(title: const Text('Mock Data Mode'), subtitle: const Text('Stop camera and finish current operations before switching.'), value: false, onChanged: _busy || _scannerOn || _initializing ? null : (_) => widget.onMock!())),
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
                        : (_roster == null ? 'Online · no roster downloaded' : 'Offline roster cached'),
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

/// Debug previews never instantiate the live scanner or its sync timer.
class KaisaAttendanceScannerPage extends StatefulWidget {
  const KaisaAttendanceScannerPage({super.key});
  @override
  State<KaisaAttendanceScannerPage> createState() => _AttendanceModeState();
}

class _AttendanceModeState extends State<KaisaAttendanceScannerPage> {
  bool mock = kDebugMode && const bool.fromEnvironment('USE_MOCK_DATA');
  @override
  Widget build(BuildContext context) => mock
      ? _MockAttendancePage(onLive: () => setState(() => mock = false))
      : _LiveAttendanceScannerPage(onMock: kDebugMode ? () => setState(() => mock = true) : null);
}

class _DemoParticipant {
  _DemoParticipant(this.id, this.name);
  final String id, name;
  DateTime? checkIn, checkOut;
  String method = '';
  bool get present => checkIn != null;
}

class _DemoEvent {
  _DemoEvent(this.title, this.mode, this.phase, {this.certificates = false, this.checkoutRequired = false});
  final String title, mode, phase;
  final bool certificates, checkoutRequired;
  final List<_DemoParticipant> people = [];
  final List<String> history = [];
  final List<({String id, bool checkout, DateTime time})> pending = [];
  bool roster = false, finalized = false;
  int? headcount;
  String countingMethod = 'Manual entrance count';
  String headcountNote = '';
  bool get writable => phase == 'Ongoing' && !finalized;
  int get present => people.where((p) => p.present).length;
  int get eligible => finalized && certificates ? people.where((p) => p.present && (!checkoutRequired || p.checkOut != null)).length : 0;
}

class _MockAttendancePage extends StatefulWidget {
  const _MockAttendancePage({required this.onLive});
  final VoidCallback onLive;
  @override
  State<_MockAttendancePage> createState() => _MockAttendanceState();
}

class _MockAttendanceState extends State<_MockAttendancePage> {
  static const forest = Color(0xFF00301B), green = Color(0xFF2C6A4A), canvas = Color(0xFFF9F9FF), ink = Color(0xFF151C27), line = Color(0xFFE2E8F8);
  List<_DemoEvent> events = [];
  int selected = 0, tab = 0;
  bool offline = false, checkout = false;
  String query = '', message = '', participantId = '';
  _DemoEvent? get event => events.isEmpty ? null : events[selected];
  @override
  void initState() { super.initState(); _seed(); }
  void _seed() {
    events = [
      _DemoEvent('Youth Leadership Seminar', 'Individual', 'Ongoing', certificates: true, checkoutRequired: true),
      _DemoEvent('Community Health Fair', 'Headcount', 'Ongoing'),
      _DemoEvent('Coastal Clean-Up Drive', 'Headcount', 'Upcoming'),
      _DemoEvent('Livelihood Workshop', 'Individual', 'Completed', certificates: true),
      _DemoEvent('Volunteer Orientation', 'Individual', 'Ongoing'),
      _DemoEvent('Sports Festival', 'None', 'Ongoing'),
      _DemoEvent('Neighborhood Assembly', 'Individual', 'On Hold'),
      _DemoEvent('Community Forum', 'Individual', 'Cancelled'),
    ];
    for (final e in events.where((e) => e.mode == 'Individual')) {
      for (var i = 1; i <= 8; i++) { e.people.add(_DemoParticipant('DEMO-${i.toString().padLeft(3, '0')}', 'Demo Participant $i')); }
      if (e.phase == 'Ongoing' || e.phase == 'Completed') {
        e.people[0].checkIn = DateTime.now().subtract(const Duration(hours: 1));
        e.people[0].method = 'Mock QR';
        e.people[1].checkIn = DateTime.now().subtract(const Duration(minutes: 55));
        e.people[1].method = 'Mock manual';
        e.people[0].checkOut = DateTime.now().subtract(const Duration(minutes: 5));
      }
    }
    selected = 0; tab = 0; offline = false; checkout = false; query = ''; message = ''; participantId = '';
  }
  void _notice(String value) { setState(() => message = value); }
  String _stamp(DateTime? d) => d == null ? '—' : MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(d));
  Widget _panel(Widget child) => Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: line), borderRadius: BorderRadius.circular(12)), child: child);
  Widget _heading(String text) => Text(text, style: const TextStyle(fontFamily: 'Outfit', fontSize: 21, fontWeight: FontWeight.w600, color: forest));
  Widget _metric(String label, String value, IconData icon) => _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: green), const SizedBox(height: 9), Text(value, style: const TextStyle(fontSize: 28, color: forest, fontWeight: FontWeight.bold)), Text(label)]));
  String? _validate(_DemoEvent e, _DemoParticipant p, bool out, {bool includeQueue = false}) {
    if (!e.writable || e.mode != 'Individual') return 'Attendance recording is unavailable for this event.';
    final queuedIn = includeQueue && e.pending.any((q) => q.id == p.id && !q.checkout);
    final queuedOut = includeQueue && e.pending.any((q) => q.id == p.id && q.checkout);
    if (out && !p.present && !queuedIn) return 'Check-in required before check-out.';
    if (out && (p.checkOut != null || queuedOut)) return 'Duplicate check-out prevented.';
    if (!out && (p.present || queuedIn)) return 'Duplicate check-in prevented.';
    return null;
  }
  void _apply(_DemoEvent e, _DemoParticipant p, bool out, DateTime time, String method) {
    if (out) { p.checkOut = time; } else { p.checkIn = time; }
    p.method = method;
    e.history.insert(0, '${p.name} · ${out ? 'Checked out' : 'Checked in'} · $method · ${_stamp(time)}');
  }
  void _scan(_DemoEvent e) {
    final matches = e.people.where((p) => p.id == participantId);
    if (matches.isEmpty) { _notice('Select a fictional participant first.'); return; }
    final p = matches.first;
    final failure = _validate(e, p, checkout, includeQueue: true);
    if (failure != null) { _notice(failure); return; }
    if (offline && !e.roster) { _notice('Prepare a mock offline roster first.'); return; }
    setState(() {
      if (offline) { e.pending.add((id: p.id, checkout: checkout, time: DateTime.now())); message = 'PROVISIONAL · ${p.name} · queued for mock synchronization'; }
      else { _apply(e, p, checkout, DateTime.now(), 'Mock QR'); message = 'MOCK CONFIRMED · ${p.name} · ${checkout ? 'Checked out' : 'Checked in'}'; }
    });
  }
  void _syncMock(_DemoEvent e) {
    if (offline) { _notice('Reconnect the simulated network first.'); return; }
    int synced = 0;
    setState(() {
      for (final q in List.of(e.pending)) {
        final p = e.people.firstWhere((p) => p.id == q.id);
        final failure = _validate(e, p, q.checkout);
        if (failure != null) { message = '$synced synced. Queue retained: $failure'; return; }
        _apply(e, p, q.checkout, q.time, 'Mock offline sync');
        e.pending.removeAt(0); synced++;
      }
      message = '$synced fictional scans synchronized. No server request made.';
    });
  }
  Future<void> _manual(_DemoEvent e, _DemoParticipant p, bool out) async {
    final failure = _validate(e, p, out, includeQueue: true);
    if (failure != null) { _notice(failure); return; }
    final reason = await _reason('Manual ${out ? 'check-out' : 'check-in'}', 'Reason for manual attendance');
    if (!mounted || event != e || reason == null) return;
    final again = _validate(e, p, out, includeQueue: true);
    if (again != null) { _notice(again); return; }
    setState(() { _apply(e, p, out, DateTime.now(), 'Mock manual'); e.history.insert(0, 'Manual entry reason: $reason'); message = 'Manual attendance recorded locally.'; });
  }
  Future<String?> _reason(String title, String label) async {
    String value = '';
    return showDialog<String>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, update) => AlertDialog(title: Text(title), content: TextField(autofocus: true, maxLines: 3, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()), onChanged: (v) => update(() => value = v)), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: value.trim().isEmpty ? null : () => Navigator.pop(ctx, value.trim()), child: const Text('Confirm'))])));
  }
  Future<void> _headcount(_DemoEvent e) async {
    String number = e.headcount?.toString() ?? '', note = e.headcountNote, method = e.countingMethod;
    final result = await showDialog<({int count, String method, String note})>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, update) {
      final n = int.tryParse(number.trim());
      return AlertDialog(title: const Text('Record aggregate attendance'), content: SizedBox(width: 420, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextFormField(initialValue: number, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total attendees'), onChanged: (v) => update(() => number = v)), const SizedBox(height: 12), DropdownButtonFormField<String>(initialValue: method, isExpanded: true, items: ['Manual entrance count', 'Ticket count', 'Organizer estimate'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => update(() => method = v!)), TextFormField(initialValue: note, decoration: const InputDecoration(labelText: 'Notes / counting basis (required)'), maxLines: 3, onChanged: (v) => update(() => note = v))]))), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: n == null || n < 0 || note.trim().isEmpty ? null : () => Navigator.pop(ctx, (count: n, method: method, note: note.trim())), child: const Text('Save mock count'))]);
    }));
    if (!mounted || event != e || result == null || e.finalized || !['Ongoing', 'Completed'].contains(e.phase)) return;
    setState(() { e.headcount = result.count; e.countingMethod = result.method; e.headcountNote = result.note; e.history.insert(0, 'Headcount: ${result.count} · ${result.method} · ${result.note}'); message = 'Aggregate count saved locally.'; });
  }
  Future<void> _finalize(_DemoEvent e) async {
    if (e.finalized || e.phase != 'Completed' || e.mode == 'None' || e.pending.isNotEmpty || (e.mode == 'Headcount' && e.headcount == null)) return;
    final reason = await _reason('Finalize mock attendance', 'Confirmation notes');
    if (!mounted || event != e || reason == null || e.pending.isNotEmpty || e.finalized) return;
    setState(() { e.finalized = true; e.history.insert(0, 'Attendance finalized · $reason'); message = 'Mock attendance finalized. Certificate eligibility is a local preview only.'; });
  }
  Widget _scannerPanel(_DemoEvent e) => _panel(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    _heading('QR scanner simulation'), const Text('No camera, actual QR credentials, or network calls are used.'), const SizedBox(height: 12),
    Container(height: 180, decoration: BoxDecoration(color: forest, borderRadius: BorderRadius.circular(12)), child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.qr_code_scanner, size: 76, color: Colors.white), SizedBox(height: 10), Text('SIMULATED SCANNER', style: TextStyle(color: Colors.white70, letterSpacing: 2))]))), const SizedBox(height: 12),
    Wrap(spacing: 8, children: [ChoiceChip(label: const Text('Check in'), selected: !checkout, onSelected: (_) => setState(() => checkout = false)), ChoiceChip(label: const Text('Check out'), selected: checkout, onSelected: (_) => setState(() => checkout = true))]),
    const SizedBox(height: 12), DropdownButtonFormField<String>(key: ValueKey('${e.title}-$participantId'), initialValue: e.people.any((p) => p.id == participantId) ? participantId : null, isExpanded: true, decoration: const InputDecoration(labelText: 'Fictional participant', border: OutlineInputBorder()), items: e.people.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.name} · ${p.id}', overflow: TextOverflow.ellipsis))).toList(), onChanged: (v) => setState(() => participantId = v ?? '')),
    const SizedBox(height: 12), FilledButton.icon(onPressed: e.writable && participantId.isNotEmpty ? () => _scan(e) : null, icon: const Icon(Icons.qr_code_scanner), label: Text('Simulate ${checkout ? 'check-out' : 'check-in'}')),
    if (!e.writable) const Text('Recording is restricted for this event.'),
  ]));
  Widget _records(_DemoEvent e) => _panel(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    _heading('Individual attendance records'), const SizedBox(height: 10), TextField(key: ValueKey(e.title), onChanged: (v) => setState(() => query = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search name or participant ID', border: OutlineInputBorder())), const SizedBox(height: 12),
    for (final p in e.people.where((p) => '${p.name} ${p.id}'.toLowerCase().contains(query.toLowerCase()))) ...[
      ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(backgroundColor: const Color(0xFFD4F4E0), child: Icon(p.present ? Icons.check : Icons.person_outline, color: forest)), title: Text(p.name), subtitle: Text('${p.id}\nIn: ${_stamp(p.checkIn)} · Out: ${_stamp(p.checkOut)}${p.method.isEmpty ? '' : '\n${p.method}'}'), isThreeLine: true, trailing: Text(p.checkOut != null ? 'Checked out' : p.present ? 'Present' : 'Not checked in', style: const TextStyle(fontSize: 11, color: forest))),
      Align(alignment: Alignment.centerRight, child: TextButton(onPressed: !offline && e.writable && p.checkOut == null ? () => _manual(e, p, p.present) : null, child: Text(p.present ? 'Manual check-out' : 'Manual check-in'))), const Divider(),
    ],
    if (!e.people.any((p) => '${p.name} ${p.id}'.toLowerCase().contains(query.toLowerCase()))) const Text('No matching participants.'),
  ]));
  Widget _offlinePanel(_DemoEvent e) => _panel(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    _heading('Offline synchronization'), SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Simulate offline connection'), value: offline, onChanged: (v) => setState(() => offline = v)),
    Text(e.roster ? 'Mock roster prepared' : 'No mock roster prepared'), const SizedBox(height: 8), OutlinedButton.icon(onPressed: !offline && e.writable ? () => setState(() { e.roster = true; message = 'Fictional roster prepared.'; }) : null, icon: const Icon(Icons.download), label: const Text('Prepare mock roster')),
    const SizedBox(height: 8), Text('${e.pending.length} provisional scan(s) — excluded from confirmed attendance.'),
    for (final q in e.pending) ListTile(dense: true, title: Text('${q.id} · ${q.checkout ? 'Check out' : 'Check in'}'), subtitle: Text(_stamp(q.time))),
    FilledButton.icon(onPressed: offline || e.pending.isEmpty ? null : () => _syncMock(e), icon: const Icon(Icons.sync), label: const Text('Simulate synchronization')),
  ]));
  Widget _summary(_DemoEvent e) => _panel(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    _heading('Attendance summary'), const SizedBox(height: 10), Text(e.mode == 'None' ? 'Actual attendance: Not recorded' : e.mode == 'Headcount' ? 'Actual attendance: ${e.headcount ?? 'Not recorded'}${e.headcount != null ? ' (${e.countingMethod})' : ''}' : 'Confirmed mock attendees: ${e.present} / ${e.people.length} registered'),
    if (e.mode == 'Headcount') ...[Text(e.headcountNote), const SizedBox(height: 10), OutlinedButton(onPressed: !e.finalized && ['Ongoing','Completed'].contains(e.phase) ? () => _headcount(e) : null, child: const Text('Record / edit headcount'))],
    if (e.certificates) ...[const Divider(), Text('Certificate eligibility: ${e.finalized ? e.eligible : 'Pending finalization'}'), Text(e.checkoutRequired ? 'Check-in and check-out required in this example.' : 'Confirmed check-in required in this example.')],
    const SizedBox(height: 12), Text(e.finalized ? 'Finalized — read only' : 'Not finalized'),
    if (e.mode != 'None') FilledButton(onPressed: !e.finalized && e.phase == 'Completed' && e.pending.isEmpty && (e.mode != 'Headcount' || e.headcount != null) ? () => _finalize(e) : null, child: const Text('Finalize attendance')),
    if (!e.finalized && e.mode != 'None') const Text('Finalization requires a completed event and no pending scans.'),
    const Divider(), _heading('Local activity history'), if (e.history.isEmpty) const Text('No mock actions recorded yet.'), for (final entry in e.history) Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Text(entry)),
  ]));
  @override
  Widget build(BuildContext context) {
    final e = event;
    return ColoredBox(color: canvas, child: ListView(padding: const EdgeInsets.all(20), children: [Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1160), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('KAISA / ORGANIZATION MANAGEMENT', style: TextStyle(color: green, fontSize: 12, letterSpacing: 1)), const SizedBox(height: 8), const Text('Attendance Management', style: TextStyle(fontFamily: 'Outfit', color: ink, fontWeight: FontWeight.w600, fontSize: 32)), const Text('Record, monitor and validate community participation.'), const SizedBox(height: 18),
      _panel(Column(children: [SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Mock Data Mode'), subtitle: const Text('Local fictional records only. Switching resets this preview.'), value: true, onChanged: (_) => widget.onLive()), Wrap(spacing: 8, children: [OutlinedButton.icon(onPressed: () => setState(_seed), icon: const Icon(Icons.refresh), label: const Text('Reset mock records')), TextButton(onPressed: () => setState(() { events = []; selected = 0; message = ''; }), child: const Text('Test empty state'))])])), const SizedBox(height: 16),
      if (e == null) _panel(const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No assigned events. Reset mock records to continue.')))) else ...[
        _panel(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [DropdownButtonFormField<int>(key: ValueKey('event-$selected'), initialValue: selected, isExpanded: true, decoration: const InputDecoration(labelText: 'Selected mock event'), items: [for (var i = 0; i < events.length; i++) DropdownMenuItem(value: i, child: Text(events[i].title, overflow: TextOverflow.ellipsis))], onChanged: (v) => setState(() { selected = v!; tab = 0; participantId = ''; query = ''; message = ''; checkout = false; })), const SizedBox(height: 8), Text('${e.phase} · ${e.mode} attendance${e.certificates ? ' · Certificates enabled' : ''}') ])), const SizedBox(height: 16),
        if (e.mode == 'Individual') LayoutBuilder(builder: (_, c) { final n = c.maxWidth >= 760 ? 4 : 2; final w = (c.maxWidth - (n - 1) * 12) / n; return Wrap(spacing: 12, runSpacing: 12, children: [SizedBox(width: w, child: _metric('Registered', '${e.people.length}', Icons.groups)), SizedBox(width: w, child: _metric('Checked in', '${e.present}', Icons.login)), SizedBox(width: w, child: _metric('Checked out', '${e.people.where((p) => p.checkOut != null).length}', Icons.logout)), SizedBox(width: w, child: _metric('Pending sync', '${e.pending.length}', Icons.sync))]); }),
        if (e.mode == 'Individual') ...[const SizedBox(height: 16), Wrap(spacing: 8, runSpacing: 8, children: [for (var i = 0; i < 4; i++) ChoiceChip(label: Text(['QR Scanner','Attendance Records','Offline Sync','Summary'][i]), selected: tab == i, onSelected: (_) => setState(() { tab = i; query = ''; }))]), const SizedBox(height: 12), if (tab == 0) _scannerPanel(e) else if (tab == 1) _records(e) else if (tab == 2) _offlinePanel(e) else _summary(e)] else _summary(e),
        if (message.isNotEmpty) ...[const SizedBox(height: 12), _panel(SelectableText(message))],
      ], const SizedBox(height: 16), const Text('Development preview only. Mock events and attendance are not shared with Events Management or E-Certificate Studio yet.', style: TextStyle(color: Colors.black54, fontSize: 12)),
    ]))) ]));
  }
}
