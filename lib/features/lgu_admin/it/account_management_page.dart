
import 'package:flutter/material.dart';

const _forest = Color(0xFF14532D);
const _green = Color(0xFF237A50);
const _paper = Color(0xFFF8FAF8);
const _ink = Color(0xFF173D2B);
const _muted = Color(0xFF687B70);
const _stroke = Color(0xFFE2EBE4);
const _soft = Color(0xFFEAF5EE);

class AccountManagementPage extends StatefulWidget {
  const AccountManagementPage({super.key});

  @override
  State<AccountManagementPage> createState() =>
      _AccountManagementPageState();
}

class _AccountManagementPageState
    extends State<AccountManagementPage> {
  String _search = '';
  String _statusFilter = 'All';

  // DEMO DATA ONLY - not from Supabase.
  static const _accounts = [
    _DemoAccount(
      'Demo Resident A',
      'DEMO-001',
      'Resident',
      'Tier 1',
      'Active',
    ),
    _DemoAccount(
      'Demo Organization Admin',
      'DEMO-002',
      'Organization Admin',
      'Tier 2',
      'Active',
    ),
    _DemoAccount(
      'Demo Resident B',
      'DEMO-003',
      'Resident',
      'Tier 2',
      'Suspended',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _accounts.where((account) {
      final query = _search.toLowerCase();

      final matchesSearch =
          account.name.toLowerCase().contains(query) ||
          account.id.toLowerCase().contains(query) ||
          account.role.toLowerCase().contains(query);

      final matchesStatus = _statusFilter == 'All' ||
          account.status == _statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();

    final active = _accounts
        .where((account) => account.status == 'Active')
        .length;

    final suspended = _accounts
        .where((account) => account.status == 'Suspended')
        .length;

    return ColoredBox(
      color: _paper,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: 1260),
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
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 9),
                  const Text(
                    'Account Management',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 29,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Review resident and organization '
                    'administrator accounts.',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Development warning.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8DE),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFF92650D),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Development preview: all accounts '
                            'below are fictional. No real '
                            'account data is displayed or modified.',
                            style: TextStyle(
                              color: Color(0xFF73550E),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 23),

                  // Summary cards.
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cols =
                          constraints.maxWidth >= 650
                              ? 3
                              : 1;
                      const gap = 12.0;
                      final width =
                          (constraints.maxWidth -
                              gap * (cols - 1)) / cols;

                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          _summaryCard(
                            'Demo Accounts',
                            '${_accounts.length}',
                            Icons.people_outline,
                            width,
                          ),
                          _summaryCard(
                            'Active Accounts',
                            '$active',
                            Icons.check_circle_outline,
                            width,
                          ),
                          _summaryCard(
                            'Suspended Accounts',
                            '$suspended',
                            Icons.block_outlined,
                            width,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 25),

                  Container(
                    padding: const EdgeInsets.all(19),
                    decoration: _surface(),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account Directory',
                          style: TextStyle(
                            color: _ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Search and filter demo records.',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 18),

                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: 300,
                              child: TextField(
                                onChanged: (value) =>
                                    setState(() =>
                                        _search = value),
                                decoration:
                                    const InputDecoration(
                                  hintText:
                                      'Search name, ID, or role',
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                  ),
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 170,
                              child: DropdownButtonFormField<String>(
                                initialValue: _statusFilter,
                                decoration:
                                    const InputDecoration(
                                  labelText: 'Status',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'All',
                                    child: Text('All'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Active',
                                    child: Text('Active'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Suspended',
                                    child: Text('Suspended'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() =>
                                        _statusFilter = value);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        if (filtered.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(28),
                            child: Center(
                              child: Text(
                                'No matching demo accounts.',
                                style: TextStyle(color: _muted),
                              ),
                            ),
                          )
                        else
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor:
                                  WidgetStateProperty.all(
                                _soft,
                              ),
                              columns: const [
                                DataColumn(
                                  label: Text('ACCOUNT'),
                                ),
                                DataColumn(
                                  label: Text('ACCOUNT ID'),
                                ),
                                DataColumn(
                                  label: Text('ROLE'),
                                ),
                                DataColumn(
                                  label: Text('TIER'),
                                ),
                                DataColumn(
                                  label: Text('STATUS'),
                                ),
                              ],
                              rows: [
                                for (final account in filtered)
                                  DataRow(
                                    cells: [
                                      DataCell(
                                        Text(account.name),
                                      ),
                                      DataCell(
                                        Text(account.id),
                                      ),
                                      DataCell(
                                        Text(account.role),
                                      ),
                                      DataCell(
                                        Text(account.tier),
                                      ),
                                      DataCell(
                                        _statusTag(account.status),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Future backend features: authorized '
                    'account recovery, suspension requests, '
                    'permission reviews, and audit history.',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 12,
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

  Widget _summaryCard(
    String title,
    String value,
    IconData icon,
    double width,
  ) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: _surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _green, size: 25),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: _forest,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusTag(String status) {
    final active = status == 'Active';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: active
            ? _soft
            : const Color(0xFFFFF0DF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: active
              ? _forest
              : const Color(0xFF9B4E16),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  BoxDecoration _surface() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: _stroke),
    );
  }
}

class _DemoAccount {
  final String name;
  final String id;
  final String role;
  final String tier;
  final String status;

  const _DemoAccount(
    this.name,
    this.id,
    this.role,
    this.tier,
    this.status,
  );
}
