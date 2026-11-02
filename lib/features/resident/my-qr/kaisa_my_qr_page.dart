import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Online 60-second QR OR previously downloaded event-specific offline pass.
/// The offline credential contains no PII; it must be prepared with internet.
class KaisaMyQrPage extends StatefulWidget {
  const KaisaMyQrPage({super.key});
  @override
  State<KaisaMyQrPage> createState() => _KaisaMyQrPageState();
}

class _KaisaMyQrPageState extends State<KaisaMyQrPage> {
  static const _forest = Color(0xFF14532D);
  static const _gold = Color(0xFFFBC02D);
  static const _storage = FlutterSecureStorage();
  final _client = Supabase.instance.client;
  Timer? _timer;
  bool _busy = false;
  bool _offlineMode = false;
  String? _onlineToken, _error;
  DateTime? _onlineExpiry;
  List<Map<String, dynamic>> _events = [];
  String? _selectedEvent;
  Map<String, dynamic>? _offlinePass;
  String get _uid => _client.auth.currentUser?.id ?? '';
  String get _passKey => 'kaisa_offline_pass_$_uid';

  @override
  void initState() {
    super.initState();
    _restorePass();
    _loadEvents();
    _issueOnline();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (!_offlineMode &&
          !_busy &&
          _onlineExpiry != null &&
          DateTime.now().isAfter(
            _onlineExpiry!.subtract(const Duration(seconds: 10)),
          )) {
        _issueOnline();
      }
    });
  }

  Future<void> _restorePass() async {
    try {
      final saved = await _storage.read(key: _passKey);
      if (saved != null && mounted) {
        final pass = Map<String, dynamic>.from(jsonDecode(saved) as Map);
        if (DateTime.parse('${pass['expires_at']}').isAfter(DateTime.now())) {
          setState(() {
            _offlinePass = pass;
            _selectedEvent = '${pass['event_id']}';
          });
        } else {
          await _storage.delete(key: _passKey);
        }
      }
    } catch (_) {
      /* secure storage not accessible, e.g. blocked browser */
    }
  }

  Future<void> _loadEvents() async {
    try {
      final data = await _client.rpc('kaisa_events_catalog');
      final rows = (data as List).cast<Map<String, dynamic>>();
      if (mounted)
        setState(
          () => _events = rows
              .where(
                (row) =>
                    row['my_status'] == 'registered' &&
                    DateTime.tryParse(
                          '${row['ends_at']}',
                        )?.isAfter(DateTime.now()) ==
                        true,
              )
              .toList(),
        );
    } catch (_) {
      /* offline passes still available when network is absent */
    }
  }

  Future<void> _issueOnline() async {
    if (_busy || _offlineMode) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await _client.rpc('kaisa_issue_attendance_qr');
      if (!mounted) return;
      setState(() {
        _onlineToken = '${result['token']}';
        _onlineExpiry = DateTime.parse('${result['expires_at']}').toLocal();
      });
    } catch (_) {
      if (mounted)
        setState(
          () => _error =
              'Online QR unavailable. If you saved an event pass, switch to Offline Pass.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _downloadPass() async {
    if (_busy || _selectedEvent == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final response = await _client.rpc(
        'kaisa_issue_offline_event_pass',
        params: {'p_event_id': _selectedEvent},
      );
      final pass = Map<String, dynamic>.from(response as Map);
      await _storage.write(key: _passKey, value: jsonEncode(pass));
      if (mounted) setState(() => _offlinePass = pass);
    } catch (e) {
      if (mounted)
        setState(() => _error = 'Could not prepare offline pass: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final passValid =
        _offlinePass != null &&
        DateTime.tryParse(
              '${_offlinePass!['expires_at']}',
            )?.isAfter(DateTime.now()) ==
            true;
    final onlineValid =
        _onlineToken != null && _onlineExpiry?.isAfter(DateTime.now()) == true;
    final activeToken = _offlineMode
        ? (passValid ? '${_offlinePass!['token']}' : null)
        : (onlineValid ? _onlineToken : null);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 110),
            children: [
              const Text(
                'MY KAISA QR',
                style: TextStyle(
                  color: Color(0xFF237A50),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your attendance pass',
                style: TextStyle(
                  color: _forest,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _forest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.qr_code_2, color: _gold, size: 35),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Present this pass to an authorized event officer.',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.wifi),
                    label: Text('Online'),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.wifi_off),
                    label: Text('Offline Pass'),
                  ),
                ],
                selected: {_offlineMode},
                onSelectionChanged: (s) =>
                    setState(() => _offlineMode = s.first),
              ),
              const SizedBox(height: 14),
              if (_offlineMode) ...[
                const Text(
                  'Download the pass BEFORE going to the venue. Each pass is valid only for its registered event. It does not require internet to display.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                if (_events.isNotEmpty)
                  DropdownButtonFormField<String>(
                    key: ValueKey(_selectedEvent),
                    initialValue:
                        _events.any((e) => '${e['id']}' == _selectedEvent)
                        ? _selectedEvent
                        : null,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Registered event',
                      border: OutlineInputBorder(),
                    ),
                    items: _events
                        .map(
                          (e) => DropdownMenuItem(
                            value: '${e['id']}',
                            child: Text(
                              '${e['title']}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedEvent = value),
                  ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _busy || _selectedEvent == null
                      ? null
                      : _downloadPass,
                  icon: const Icon(Icons.download),
                  label: const Text('Download / renew event pass'),
                ),
                if (_events.isEmpty)
                  const Text(
                    'No live registration list available. An already downloaded pass can still be shown below.',
                  ),
              ],
              const SizedBox(height: 16),
              Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      if (activeToken != null)
                        QrImageView(
                          data: activeToken,
                          size: 244,
                          backgroundColor: Colors.white,
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.all(60),
                          child: Icon(
                            Icons.qr_code_2,
                            size: 90,
                            color: Colors.grey,
                          ),
                        ),
                      const SizedBox(height: 14),
                      Text(
                        _offlineMode
                            ? (passValid
                                  ? 'Offline pass valid until ${DateTime.parse('${_offlinePass!['expires_at']}').toLocal()}'
                                  : 'No valid saved offline pass')
                            : (onlineValid
                                  ? 'Refreshing online QR automatically'
                                  : 'Online QR unavailable'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _forest,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (!_offlineMode)
                        TextButton.icon(
                          onPressed: _busy ? null : _issueOnline,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh QR'),
                        ),
                    ],
                  ),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 16),
              const ListTile(
                leading: Icon(Icons.lock_outline, color: _forest),
                title: Text('No personal details inside the QR'),
                subtitle: Text(
                  'Registration and identity remain in Supabase. Offline scan results are provisional until synced.',
                ),
              ),
              const ListTile(
                leading: Icon(Icons.warning_amber_rounded, color: _forest),
                title: Text('An offline pass is event-specific'),
                subtitle: Text(
                  'Save it while connected. If revoked or registration changes while offline, the scanner may only discover it during synchronization.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
