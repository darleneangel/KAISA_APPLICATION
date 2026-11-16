
import 'package:flutter/material.dart';

const _forest = Color(0xFF14532D);
const _green = Color(0xFF237A50);
const _paper = Color(0xFFF8FAF8);
const _ink = Color(0xFF173D2B);
const _muted = Color(0xFF687B70);
const _stroke = Color(0xFFE2EBE4);
const _soft = Color(0xFFEAF5EE);

class BackupRecoveryPage extends StatefulWidget {
  const BackupRecoveryPage({super.key});

  @override
  State<BackupRecoveryPage> createState() =>
      _BackupRecoveryPageState();
}

class _BackupRecoveryPageState extends State<BackupRecoveryPage> {
  String _filter = 'All';

  // Fictional records for frontend development only.
  static const _backups = <_DemoBackup>[
    _DemoBackup(
      'DEMO-BK-001',
      'Database snapshot',
      'Nov 16, 2026 · 02:00',
      'Completed',
    ),
    _DemoBackup(
      'DEMO-BK-002',
      'Database snapshot',
      'Nov 15, 2026 · 02:00',
      'Completed',
    ),
    _DemoBackup(
      'DEMO-BK-003',
      'Storage backup',
      'Nov 14, 2026 · 02:00',
      'Failed',
    ),
    _DemoBackup(
      'DEMO-BK-004',
      'Database snapshot',
      'Nov 13, 2026 · 02:00',
      'Completed',
    ),
  ];

  static const _recoveryItems = [
    'Document the authorized recovery procedure',
    'Verify the backup retention policy',
    'Identify responsible recovery personnel',
    'Plan a recovery test in a non-production environment',
    'Record approval before any production restoration',
  ];

  final Set<int> _checkedItems = {};

  @override
  Widget build(BuildContext context) {
    final completed =
        _backups.where((item) => item.status == 'Completed').length;

    final failed =
        _backups.where((item) => item.status == 'Failed').length;

    final filtered = _backups
        .where((item) => _filter == 'All' || item.status == _filter)
        .toList();

    return ColoredBox(
      color: _paper,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1260),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'KAISA / LGU ADMINISTRATION / IT',
                    style: TextStyle(
                      color: _green,
                      fontSize: 11,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Backup & Recovery',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 29,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Review backup records, recovery readiness, '
                    'and system continuity procedures.',
                    style: TextStyle(color: _muted, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  _notice(),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns =
                          constraints.maxWidth >= 700 ? 3 : 1;
                      const gap = 12.0;
                      final width =
                          (constraints.maxWidth - gap * (columns - 1)) /
                              columns;

                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          _statCard(
                            'Demo backups',
                            '${_backups.length}',
                            Icons.backup_outlined,
                            width,
                          ),
                          _statCard(
                            'Demo completed',
                            '$completed',
                            Icons.check_circle_outline,
                            width,
                          ),
                          _statCard(
                            'Demo failed',
                            '$failed',
                            Icons.error_outline,
                            width,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 25),
                  _backupHistory(filtered),
                  const SizedBox(height: 25),
                  _recoveryChecklist(),
                  const SizedBox(height: 20),
                  const Text(
                    'Prototype only. Checklist selections remain in '
                    'this page session and do not indicate actual '
                    'recovery readiness. Production backup operations '
                    'must use authorized server-side services.',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
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
              'DEVELOPMENT PREVIEW — All backup records are '
              'fictional. No real Supabase backups are accessed '
              'or modified.',
              style: TextStyle(
                color: Color(0xFF73550E),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    double width,
  ) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: _surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _green, size: 26),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: _forest,
              fontWeight: FontWeight.w900,
              fontSize: 29,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _backupHistory(List<_DemoBackup> backups) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Backup History',
            style: TextStyle(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Example backup records for layout testing.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 190,
            child: DropdownButtonFormField<String>(
              initialValue: _filter,
              decoration: const InputDecoration(
                labelText: 'Filter by status',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'All',
                  child: Text('All'),
                ),
                DropdownMenuItem(
                  value: 'Completed',
                  child: Text('Completed'),
                ),
                DropdownMenuItem(
                  value: 'Failed',
                  child: Text('Failed'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _filter = value);
                }
              },
            ),
          ),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(_soft),
              columns: const [
                DataColumn(label: Text('BACKUP ID')),
                DataColumn(label: Text('TYPE')),
                DataColumn(label: Text('DATE')),
                DataColumn(label: Text('STATUS')),
              ],
              rows: [
                for (final item in backups)
                  DataRow(
                    cells: [
                      DataCell(Text(item.id)),
                      DataCell(Text(item.type)),
                      DataCell(Text(item.date)),
                      DataCell(
                        Text(
                          item.status,
                          style: TextStyle(
                            color: item.status == 'Completed'
                                ? _green
                                : const Color(0xFF9B4E16),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (backups.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('No matching demo backups.'),
            ),
        ],
      ),
    );
  }

  Widget _recoveryChecklist() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recovery Readiness Checklist',
            style: TextStyle(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Interactive planning checklist — not a live audit.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 15),
          LinearProgressIndicator(
            value: _checkedItems.length / _recoveryItems.length,
            backgroundColor: _soft,
            color: _green,
            minHeight: 8,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: 10),
          Text(
            '${_checkedItems.length} of ${_recoveryItems.length} '
            'demo checklist items selected',
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < _recoveryItems.length; i++)
            CheckboxListTile(
              value: _checkedItems.contains(i),
              activeColor: _green,
              title: Text(
                _recoveryItems[i],
                style: const TextStyle(
                  color: _ink,
                  fontSize: 13,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _checkedItems.add(i);
                  } else {
                    _checkedItems.remove(i);
                  }
                });
              },
            ),
        ],
      ),
    );
  }

  BoxDecoration _surface() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _stroke),
      );
}

class _DemoBackup {
  final String id;
  final String type;
  final String date;
  final String status;

  const _DemoBackup(
    this.id,
    this.type,
    this.date,
    this.status,
  );
}
