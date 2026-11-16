
import 'package:flutter/material.dart';

const _forest = Color(0xFF14532D);
const _green = Color(0xFF237A50);
const _paper = Color(0xFFF8FAF8);
const _ink = Color(0xFF173D2B);
const _muted = Color(0xFF687B70);
const _stroke = Color(0xFFE2EBE4);
const _soft = Color(0xFFEAF5EE);

class SystemSettingsPage extends StatefulWidget {
  const SystemSettingsPage({super.key});

  @override
  State<SystemSettingsPage> createState() =>
      _SystemSettingsPageState();
}

class _SystemSettingsPageState
    extends State<SystemSettingsPage> {
  final _nameController =
      TextEditingController(text: 'KAISA');

  final _descriptionController = TextEditingController(
    text: 'Community engagement and organization management',
  );

  bool _maintenanceNotice = false;
  bool _securityNotifications = true;
  bool _systemNotifications = true;

  String _environment = 'Development';
  String _maintenanceWindow = 'No maintenance scheduled';

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _savePreview() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Preview updated locally. No settings were saved '
          'to Supabase.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _paper,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: 1150),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'KAISA / LGU ADMINISTRATION / IT',
                    style: TextStyle(
                      color: _green,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'System Settings',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 29,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Preview platform configuration, '
                    'notifications, and maintenance preferences.',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _notice(),
                  const SizedBox(height: 25),

                  _sectionCard(
                    'General Configuration',
                    Icons.tune_rounded,
                    [
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Application Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Application Description',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _environment,
                        decoration: const InputDecoration(
                          labelText: 'Preview Environment',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Development',
                            child: Text('Development'),
                          ),
                          DropdownMenuItem(
                            value: 'Staging',
                            child: Text('Staging'),
                          ),
                          DropdownMenuItem(
                            value: 'Production',
                            child: Text('Production'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _environment = value);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Environment selection is a display '
                        'preference only. It does not change '
                        'the connected Supabase project.',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  _sectionCard(
                    'Administrator Notifications',
                    Icons.notifications_active_outlined,
                    [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Security Notifications',
                          style: TextStyle(
                            color: _ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: const Text(
                          'Preview alerts for account and '
                          'authentication activity.',
                        ),
                        activeThumbColor: _green,
                        value: _securityNotifications,
                        onChanged: (value) => setState(
                          () => _securityNotifications = value,
                        ),
                      ),
                      const Divider(color: _stroke),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'System Notifications',
                          style: TextStyle(
                            color: _ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: const Text(
                          'Preview infrastructure and '
                          'maintenance announcements.',
                        ),
                        activeThumbColor: _green,
                        value: _systemNotifications,
                        onChanged: (value) => setState(
                          () => _systemNotifications = value,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  _sectionCard(
                    'Maintenance Planning',
                    Icons.build_circle_outlined,
                    [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Display Maintenance Notice',
                          style: TextStyle(
                            color: _ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: const Text(
                          'Preview a maintenance notice '
                          'inside this settings page only.',
                        ),
                        value: _maintenanceNotice,
                        activeThumbColor: _green,
                        onChanged: (value) => setState(
                          () => _maintenanceNotice = value,
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _maintenanceWindow,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Sample Maintenance Window',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'No maintenance scheduled',
                            child: Text('No maintenance scheduled'),
                          ),
                          DropdownMenuItem(
                            value: 'Saturday, 10:00 PM',
                            child: Text('Saturday, 10:00 PM'),
                          ),
                          DropdownMenuItem(
                            value: 'Sunday, 12:00 AM',
                            child: Text('Sunday, 12:00 AM'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(
                              () => _maintenanceWindow = value,
                            );
                          }
                        },
                      ),
                      if (_maintenanceNotice) ...[
                        const SizedBox(height: 15),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8DE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'DEMO MAINTENANCE NOTICE\n'
                            'Selected window: $_maintenanceWindow\n'
                            'No live maintenance mode is enabled.',
                            style: const TextStyle(
                              color: Color(0xFF73550E),
                              fontSize: 12,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 18),

                  _sectionCard(
                    'Security Configuration',
                    Icons.security_outlined,
                    [
                      _readOnlySetting(
                        'Administrative role enforcement',
                        'Requires backend permission policies',
                      ),
                      const Divider(color: _stroke),
                      _readOnlySetting(
                        'Authentication policy',
                        'Managed through authorized Supabase settings',
                      ),
                      const Divider(color: _stroke),
                      _readOnlySetting(
                        'Audit logging',
                        'Backend integration pending',
                      ),
                      const Divider(color: _stroke),
                      _readOnlySetting(
                        'Backup & recovery policy',
                        'Configured outside the Flutter client',
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _savePreview,
                      style: FilledButton.styleFrom(
                        backgroundColor: _forest,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 23,
                          vertical: 16,
                        ),
                      ),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text(
                        'Apply Preview Changes',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8DE),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFF1E3A7),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF92650D),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'DEVELOPMENT PREVIEW — These controls only '
              'change local interface values. They do not '
              'update Supabase, application-wide settings, '
              'or security policies.',
              style: TextStyle(
                color: Color(0xFF73550E),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _green, size: 22),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 21),
          ...children,
        ],
      ),
    );
  }

  Widget _readOnlySetting(
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            color: _green,
            size: 20,
          ),
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
