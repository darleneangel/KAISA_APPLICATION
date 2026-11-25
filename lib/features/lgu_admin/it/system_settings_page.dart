import 'package:flutter/material.dart';

// KAISA IT Superadmin — least-privilege System Settings.
// Preview-only: nothing here changes Supabase, project configuration,
// authentication, actual notifications, or resident-facing maintenance notices.
const _deep = Color(0xFF103F2D);
const _green = Color(0xFF247951);
const _paper = Color(0xFFF7F9F7);
const _ink = Color(0xFF183729);
const _muted = Color(0xFF718075);
const _line = Color(0xFFE2EBE4);
const _mint = Color(0xFFEAF4ED);
const _yellow = Color(0xFFFFCF4A);

enum _Section { general, notifications, maintenance, security }

class SystemSettingsPage extends StatefulWidget {
  const SystemSettingsPage({super.key});

  @override
  State<SystemSettingsPage> createState() => _SystemSettingsPageState();
}

class _SystemSettingsPageState extends State<SystemSettingsPage> {
  _Section _section = _Section.general;
  bool _securityAlerts = true;
  bool _serviceAlerts = true;
  bool _backupAlerts = true;
  bool _maintenanceDraftEnabled = false;
  DateTime? _maintenanceDate;
  TimeOfDay? _maintenanceTime;
  final _maintenanceMessage = TextEditingController(
    text: 'KAISA may be temporarily unavailable during scheduled maintenance.',
  );
  late Map<String, String> _saved;

  @override
  void initState() {
    super.initState();
    _saved = _snapshot();
  }

  @override
  void dispose() {
    _maintenanceMessage.dispose();
    super.dispose();
  }

  Map<String, String> _snapshot() => {
    'security': _securityAlerts.toString(),
    'service': _serviceAlerts.toString(),
    'backup': _backupAlerts.toString(),
    'maintenance': _maintenanceDraftEnabled.toString(),
    'date': _maintenanceDate?.toIso8601String() ?? '',
    'time': _maintenanceTime == null
        ? ''
        : '${_maintenanceTime!.hour}:${_maintenanceTime!.minute}',
    'message': _maintenanceMessage.text,
  };

  bool get _dirty {
    final now = _snapshot();
    return now.keys.any((key) => now[key] != _saved[key]);
  }

  void _saveDraft() {
    if (_maintenanceDraftEnabled &&
        (_maintenanceDate == null ||
            _maintenanceTime == null ||
            _maintenanceMessage.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Choose a date and time and enter a maintenance message.',
          ),
        ),
      );
      setState(() => _section = _Section.maintenance);
      return;
    }
    setState(() => _saved = _snapshot());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preview preferences saved for this page session only.'),
      ),
    );
  }

  void _discard() {
    setState(() {
      _securityAlerts = _saved['security'] == 'true';
      _serviceAlerts = _saved['service'] == 'true';
      _backupAlerts = _saved['backup'] == 'true';
      _maintenanceDraftEnabled = _saved['maintenance'] == 'true';
      final date = _saved['date'] ?? '';
      _maintenanceDate = date.isEmpty ? null : DateTime.tryParse(date);
      final time = _saved['time'] ?? '';
      final parts = time.split(':');
      _maintenanceTime = parts.length == 2
          ? TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 0,
              minute: int.tryParse(parts[1]) ?? 0,
            )
          : null;
      _maintenanceMessage.text = _saved['message'] ?? '';
    });
  }

  String _sectionLabel(_Section section) => switch (section) {
    _Section.general => 'General',
    _Section.notifications => 'Notifications',
    _Section.maintenance => 'Maintenance',
    _Section.security => 'Security & access',
  };

  IconData _sectionIcon(_Section section) => switch (section) {
    _Section.general => Icons.tune_rounded,
    _Section.notifications => Icons.notifications_none_rounded,
    _Section.maintenance => Icons.build_outlined,
    _Section.security => Icons.shield_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _paper,
      child: LayoutBuilder(
        builder: (context, dimensions) {
          final compact = dimensions.maxWidth < 650;
          return ListView(
            padding: EdgeInsets.fromLTRB(
              compact ? 15 : 28,
              24,
              compact ? 15 : 28,
              40,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(compact),
                      const SizedBox(height: 17),
                      _notice(),
                      const SizedBox(height: 22),
                      Container(
                        decoration: _surface(),
                        padding: EdgeInsets.all(compact ? 16 : 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  for (final section in _Section.values) ...[
                                    _tab(section),
                                    const SizedBox(width: 8),
                                  ],
                                ],
                              ),
                            ),
                            const Divider(height: 34, color: _line),
                            if (_section == _Section.general) _general(),
                            if (_section == _Section.notifications)
                              _notifications(),
                            if (_section == _Section.maintenance)
                              _maintenance(),
                            if (_section == _Section.security) _security(),
                            const SizedBox(height: 22),
                            const Divider(color: _line),
                            const SizedBox(height: 10),
                            Wrap(
                              alignment: WrapAlignment.end,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                if (_dirty)
                                  OutlinedButton(
                                    onPressed: _discard,
                                    child: const Text('Discard changes'),
                                  ),
                                FilledButton.icon(
                                  onPressed: _dirty ? _saveDraft : null,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _deep,
                                  ),
                                  icon: const Icon(
                                    Icons.save_outlined,
                                    size: 17,
                                  ),
                                  label: const Text('Save preview'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Preview values are temporary. Critical security policies are not configurable from this screen.',
                              style: TextStyle(fontSize: 11, color: _muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _header(bool compact) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(compact ? 22 : 30),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF092D23), _deep, Color(0xFF257A54)],
      ),
      borderRadius: BorderRadius.circular(23),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'KAISA  /  IT ADMINISTRATION',
          style: TextStyle(
            color: _yellow,
            fontSize: 10,
            letterSpacing: 1.8,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'System Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 26 : 32,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Essential operational preferences with least-privilege access.',
          style: TextStyle(color: Color(0xFFDFEDE3), fontSize: 13),
        ),
      ],
    ),
  );

  Widget _notice() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF6DB),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Row(
      children: [
        Icon(Icons.info_outline_rounded, color: Color(0xFF92650D)),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'DEVELOPMENT PREVIEW — Changes stay on this screen only. No Supabase configuration, actual alerts, or public maintenance announcements are changed.',
            style: TextStyle(
              color: Color(0xFF73550E),
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _tab(_Section section) {
    final selected = _section == section;
    return InkWell(
      onTap: () => setState(() => _section = section),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? _mint : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? _green : _line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _sectionIcon(section),
              size: 17,
              color: selected ? _deep : _muted,
            ),
            const SizedBox(width: 7),
            Text(
              _sectionLabel(section),
              style: TextStyle(
                fontSize: 12,
                color: selected ? _deep : _muted,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _intro(String title, String description) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 19,
          color: _ink,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 5),
      Text(description, style: const TextStyle(color: _muted, fontSize: 12)),
      const SizedBox(height: 20),
    ],
  );

  Widget _general() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _intro(
        'General information',
        'Read-only deployment details. Change these through authorized releases.',
      ),
      _info('Application', 'KAISA'),
      _info('Purpose', 'Community engagement and organization management'),
      _info('System owner after deployment', 'Cavite City LGU IT Department'),
      _info(
        'Infrastructure',
        'Supabase — managed by authorized LGU technical personnel',
      ),
      _info(
        'Deployment environment',
        'Use your deployment configuration as the source of truth',
      ),
    ],
  );

  Widget _notifications() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _intro(
        'Administrator notifications',
        'Choose which non-mandatory operational alert categories appear in your personal preview.',
      ),
      _toggle(
        'Security event alerts',
        'Suspicious logins, privileged changes, and security incidents.',
        _securityAlerts,
        (v) => setState(() => _securityAlerts = v),
      ),
      _toggle(
        'Service health alerts',
        'System outages, API errors, and degraded service.',
        _serviceAlerts,
        (v) => setState(() => _serviceAlerts = v),
      ),
      _toggle(
        'Backup failure alerts',
        'Missing or failed backup jobs and recovery test failures.',
        _backupAlerts,
        (v) => setState(() => _backupAlerts = v),
      ),
      const SizedBox(height: 10),
      const Text(
        'Mandatory incident escalation and official security notices must remain enforced by backend policy; these switches cannot disable them.',
        style: TextStyle(fontSize: 11, color: _muted, height: 1.5),
      ),
    ],
  );

  Widget _maintenance() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _intro(
        'Maintenance planning',
        'Prepare an internal maintenance notice draft. Publishing requires an authorized workflow.',
      ),
      _toggle(
        'Prepare maintenance notice',
        'Enable a local draft; this does not put KAISA into maintenance mode.',
        _maintenanceDraftEnabled,
        (v) => setState(() => _maintenanceDraftEnabled = v),
      ),
      if (_maintenanceDraftEnabled) ...[
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _maintenanceDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null && mounted) {
                  setState(() => _maintenanceDate = date);
                }
              },
              icon: const Icon(Icons.event_outlined),
              label: Text(
                _maintenanceDate == null
                    ? 'Choose date'
                    : '${_maintenanceDate!.year}-${_maintenanceDate!.month.toString().padLeft(2, '0')}-${_maintenanceDate!.day.toString().padLeft(2, '0')}',
              ),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final selected = await showTimePicker(
                  context: context,
                  initialTime:
                      _maintenanceTime ?? const TimeOfDay(hour: 22, minute: 0),
                );
                if (selected != null && mounted) {
                  setState(() => _maintenanceTime = selected);
                }
              },
              icon: const Icon(Icons.schedule_outlined),
              label: Text(_maintenanceTime?.format(context) ?? 'Choose time'),
            ),
          ],
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _maintenanceMessage,
          onChanged: (_) => setState(() {}),
          maxLines: 3,
          maxLength: 280,
          decoration: const InputDecoration(
            labelText: 'Draft notice',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: _mint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'INTERNAL PREVIEW · NOT PUBLISHED',
                style: TextStyle(
                  color: _deep,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                _maintenanceMessage.text,
                style: const TextStyle(color: _ink, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    ],
  );

  Widget _security() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _intro(
        'Security & access',
        'Security safeguards are managed by authorized technical personnel, not editable UI toggles.',
      ),
      _info(
        'Five-minute IT admin inactivity logout',
        'Enforced by the existing LGU administrator session guard',
      ),
      _info(
        'Administrator roles',
        'Server-side authorization required; role requests belong in Roles & Permissions',
      ),
      _info(
        'Multi-factor authentication',
        'Configure and enforce via approved authentication policies',
      ),
      _info(
        'Audit logging',
        'Must not be disabled by an application administrator',
      ),
      _info(
        'Database keys, RLS, backups',
        'Managed through restricted LGU Supabase infrastructure access',
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _mint,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: _green),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Least privilege: administrators can view operational guidance here but cannot weaken infrastructure safeguards.',
                style: TextStyle(color: _ink, fontSize: 12, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _info(String title, String description) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 15),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lock_outline_rounded, size: 18, color: _green),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _toggle(
    String title,
    String description,
    bool value,
    ValueChanged<bool> changed,
  ) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch(value: value, onChanged: changed, activeThumbColor: _green),
          ],
        ),
      ),
      const Divider(color: _line),
    ],
  );

  BoxDecoration _surface() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: _line),
    boxShadow: const [
      BoxShadow(color: Color(0x0A00492C), blurRadius: 22, offset: Offset(0, 7)),
    ],
  );
}
