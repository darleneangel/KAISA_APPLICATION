import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// KAISA IT SUPERADMIN — ROLE GOVERNANCE DESIGN PREVIEW.
// All permissions are proposed local definitions. No Supabase reads/writes.
const _forest = Color(0xFF103E2C);
const _deep = Color(0xFF082D22);
const _green = Color(0xFF287E55);
const _paper = Color(0xFFF5F7F3);
const _ink = Color(0xFF173A2A);
const _muted = Color(0xFF748278);
const _stroke = Color(0xFFE3EAE3);
const _soft = Color(0xFFE9F3EC);
const _gold = Color(0xFFF7C948);

enum _AdminRole { it, verification, operations }

extension _RoleInfo on _AdminRole {
  String get label => switch (this) {
    _AdminRole.it => 'IT Superadmin',
    _AdminRole.verification => 'Verification Superadmin',
    _AdminRole.operations => 'Operations Superadmin',
  };
  String get keyName => switch (this) {
    _AdminRole.it => 'lgu_it_admin',
    _AdminRole.verification => 'lgu_verification_admin',
    _AdminRole.operations => 'lgu_operations_admin',
  };
  String get shortName => switch (this) {
    _AdminRole.it => 'IT',
    _AdminRole.verification => 'Verification',
    _AdminRole.operations => 'Operations',
  };
  String get description => switch (this) {
    _AdminRole.it =>
      'Protect platform access, provision accounts, maintain security, and supervise infrastructure.',
    _AdminRole.verification =>
      'Review residents\' identity submissions and make authorized Tier 2 verification decisions.',
    _AdminRole.operations =>
      'Coordinate organizations, authorized org-admin assignments, events, and operational reporting.',
  };
  IconData get icon => switch (this) {
    _AdminRole.it => Icons.shield_rounded,
    _AdminRole.verification => Icons.verified_user_rounded,
    _AdminRole.operations => Icons.domain_rounded,
  };
}

class _Permission {
  final String id;
  final String name;
  final String category;
  final String description;
  final Set<_AdminRole> owners;
  final bool sensitive;

  const _Permission(
    this.id,
    this.name,
    this.category,
    this.description,
    this.owners, {
    this.sensitive = false,
  });
}

class _DraftRequest {
  final _AdminRole role;
  final _Permission permission;
  final bool grant;
  final String justification;
  final DateTime createdAt;

  const _DraftRequest({
    required this.role,
    required this.permission,
    required this.grant,
    required this.justification,
    required this.createdAt,
  });
}

class RolesPermissionsPage extends StatefulWidget {
  const RolesPermissionsPage({super.key});

  @override
  State<RolesPermissionsPage> createState() => _RolesPermissionsPageState();
}

class _RolesPermissionsPageState extends State<RolesPermissionsPage> {
  _AdminRole _selected = _AdminRole.it;
  String _search = '';
  String _category = 'All categories';
  String _access = 'All permissions';
  final List<_DraftRequest> _drafts = [];

  // Proposed policy catalogue: this is NOT the current Supabase/RLS policy.
  static const _permissions = <_Permission>[
    _Permission(
      'ACC-01',
      'View account directory',
      'Accounts',
      'Search authorized account records, status, and role assignments.',
      {_AdminRole.it},
    ),
    _Permission(
      'ACC-02',
      'Provision administrator accounts',
      'Accounts',
      'Invite approved LGU administrators and provision the authorized role; requires a trusted server-side workflow.',
      {_AdminRole.it},
      sensitive: true,
    ),
    _Permission(
      'ACC-03',
      'Suspend, reactivate & archive',
      'Accounts',
      'Apply documented account lifecycle decisions with a policy reason and audit trail.',
      {_AdminRole.it},
      sensitive: true,
    ),
    _Permission(
      'ACC-04',
      'Start account recovery',
      'Accounts',
      'Start a verified recovery flow without viewing or resetting credentials directly.',
      {_AdminRole.it},
      sensitive: true,
    ),
    _Permission(
      'IAM-01',
      'Review roles & access',
      'Governance',
      'Read the approved role matrix and access-change history.',
      {_AdminRole.it},
    ),
    _Permission(
      'IAM-02',
      'Submit role change requests',
      'Governance',
      'Propose administrator privilege changes for independent approval; no self-escalation.',
      {_AdminRole.it},
      sensitive: true,
    ),
    _Permission(
      'SEC-01',
      'View security audit logs',
      'Security',
      'Inspect authorized authentication and administrator security events.',
      {_AdminRole.it},
      sensitive: true,
    ),
    _Permission(
      'SEC-02',
      'Review platform health',
      'Security',
      'View service availability and errors from an authorized monitoring source.',
      {_AdminRole.it},
    ),
    _Permission(
      'SYS-01',
      'System configuration',
      'Infrastructure',
      'Maintain approved configuration settings with change-control safeguards.',
      {_AdminRole.it},
      sensitive: true,
    ),
    _Permission(
      'SYS-02',
      'Backup & recovery planning',
      'Infrastructure',
      'Review backups and initiate approved recovery procedures.',
      {_AdminRole.it},
      sensitive: true,
    ),
    _Permission(
      'VER-01',
      'View identity review queue',
      'Verification',
      'See pending Tier 2 submissions and required review material.',
      {_AdminRole.verification},
      sensitive: true,
    ),
    _Permission(
      'VER-02',
      'Decide Tier 2 verification',
      'Verification',
      'Approve, reject, or request resubmission with a recorded reason.',
      {_AdminRole.verification},
      sensitive: true,
    ),
    _Permission(
      'VER-03',
      'View verification history & reports',
      'Verification',
      'Read authorized verification outcomes and workload summaries.',
      {_AdminRole.verification},
      sensitive: true,
    ),
    _Permission(
      'OPS-01',
      'Manage organization registry',
      'Operations',
      'Review and maintain authorized organization registry information.',
      {_AdminRole.operations},
    ),
    _Permission(
      'OPS-02',
      'Approve organization assignments',
      'Operations',
      'Review requests to appoint or replace organization administrators.',
      {_AdminRole.operations},
      sensitive: true,
    ),
    _Permission(
      'OPS-03',
      'Monitor events & attendance',
      'Operations',
      'View event activity and approved attendance summaries.',
      {_AdminRole.operations},
    ),
    _Permission(
      'OPS-04',
      'View operational reports',
      'Operations',
      'Review organization and event performance indicators.',
      {_AdminRole.operations},
    ),
  ];

  List<_Permission> get _filtered {
    final query = _search.trim().toLowerCase();
    return _permissions.where((p) {
      if (_category != 'All categories' && p.category != _category) {
        return false;
      }
      if (_access == 'Assigned to selected role' &&
          !p.owners.contains(_selected)) {
        return false;
      }
      if (_access == 'Not assigned to selected role' &&
          p.owners.contains(_selected)) {
        return false;
      }
      if (_access == 'Sensitive only' && !p.sensitive) return false;
      return query.isEmpty ||
          p.id.toLowerCase().contains(query) ||
          p.name.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query) ||
          p.description.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _paper,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          return ListView(
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 26,
              24,
              compact ? 16 : 26,
              42,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1320),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _pageHeader(compact),
                      const SizedBox(height: 20),
                      _notice(),
                      const SizedBox(height: 20),
                      _hero(compact),
                      const SizedBox(height: 24),
                      _sectionHeader(
                        'Administrator roles',
                        'Select a role to inspect its proposed responsibilities.',
                      ),
                      const SizedBox(height: 13),
                      _roleCards(),
                      const SizedBox(height: 23),
                      _selectedRoleDetails(),
                      const SizedBox(height: 23),
                      _sectionHeader(
                        'Permission explorer',
                        'Search the access catalogue and compare all three LGU roles.',
                      ),
                      const SizedBox(height: 13),
                      _matrixPanel(),
                      const SizedBox(height: 23),
                      _draftPanel(),
                      const SizedBox(height: 20),
                      _governanceNotes(),
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

  Widget _pageHeader(bool compact) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 12,
    runSpacing: 12,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KAISA  /  IT ADMINISTRATION  /  ACCESS GOVERNANCE',
            style: TextStyle(
              color: _green,
              fontSize: 10,
              letterSpacing: 1.15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Roles & Permissions',
            style: TextStyle(
              color: _ink,
              fontSize: compact ? 25 : 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Understand who can do what — and why.',
            style: TextStyle(color: _muted, fontSize: 13),
          ),
        ],
      ),
      OutlinedButton.icon(
        onPressed: _copyCsv,
        icon: const Icon(Icons.file_download_outlined, size: 18),
        label: const Text('Copy matrix CSV'),
      ),
    ],
  );

  Widget _notice() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF7DB),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0xFFF3E7BD)),
    ),
    child: const Row(
      children: [
        Icon(Icons.info_outline, color: Color(0xFF956711)),
        SizedBox(width: 11),
        Expanded(
          child: Text(
            'DESIGN PREVIEW — This is a proposed permission catalogue, not a live RBAC or RLS configuration. Draft requests, filters and exports are local only; they do not grant access.',
            style: TextStyle(
              color: Color(0xFF745519),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _hero(bool compact) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(compact ? 20 : 25),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_deep, _forest, Color(0xFF23714A)],
      ),
      borderRadius: BorderRadius.circular(23),
    ),
    child: Wrap(
      spacing: 22,
      runSpacing: 20,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline_rounded, color: _gold, size: 17),
                  SizedBox(width: 8),
                  Text(
                    'ACCESS CONTROL CENTER',
                    style: TextStyle(
                      color: _gold,
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const Text(
                'The right access.\nFor the right people.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  height: 1.17,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Roles group permissions; permissions define specific actions. Keeping them separate reduces accidental access to sensitive resident and LGU data.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .77),
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _heroStat('3', 'Proposed LGU roles'),
            _heroStat('${_permissions.length}', 'Policy entries'),
            _heroStat(
              '${_permissions.where((p) => p.sensitive).length}',
              'Sensitive actions',
            ),
          ],
        ),
      ],
    ),
  );

  Widget _heroStat(String value, String label) => Container(
    width: 137,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.white.withValues(alpha: .12)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: _gold,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            height: 1.4,
          ),
        ),
      ],
    ),
  );

  Widget _sectionHeader(String heading, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        heading,
        style: const TextStyle(
          color: _ink,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 4),
      Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)),
    ],
  );

  Widget _roleCards() => LayoutBuilder(
    builder: (context, c) {
      final count = c.maxWidth >= 920
          ? 3
          : c.maxWidth >= 560
          ? 2
          : 1;
      const gap = 12.0;
      final width = (c.maxWidth - gap * (count - 1)) / count;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final role in _AdminRole.values)
            SizedBox(width: width, child: _roleCard(role)),
        ],
      );
    },
  );

  Widget _roleCard(_AdminRole role) {
    final active = role == _selected;
    final count = _permissions.where((p) => p.owners.contains(role)).length;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(19),
        onTap: () => setState(() => _selected = role),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: active ? _soft : Colors.white,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: active ? _green : _stroke,
              width: active ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: active ? Colors.white : _soft,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(role.icon, color: _forest, size: 23),
                  ),
                  const Spacer(),
                  if (active)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: _green,
                      size: 22,
                    ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                role.label,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                role.keyName,
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
              const SizedBox(height: 14),
              Text(
                '$count proposed permissions',
                style: const TextStyle(
                  color: _green,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectedRoleDetails() {
    final assigned = _permissions
        .where((p) => p.owners.contains(_selected))
        .toList();
    return Container(
      padding: const EdgeInsets.all(21),
      decoration: _surface(),
      child: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 700;
          return Wrap(
            spacing: 28,
            runSpacing: 18,
            children: [
              SizedBox(
                width: wide ? c.maxWidth * .36 : c.maxWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ROLE PROFILE',
                      style: TextStyle(
                        color: _green,
                        fontSize: 10,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _selected.label,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    SelectableText(
                      _selected.keyName,
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selected.description,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 15),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.edit_note_rounded, size: 17),
                      onPressed: _openDraftDialog,
                      label: const Text('Propose access change'),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: wide ? c.maxWidth * .57 : c.maxWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PROPOSED CAPABILITIES',
                      style: TextStyle(
                        color: _green,
                        fontSize: 10,
                        letterSpacing: 1.3,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final p in assigned) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: _green,
                            size: 16,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              p.name,
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (p.sensitive)
                            const Tooltip(
                              message:
                                  'Requires stronger approval and audit controls',
                              child: Icon(
                                Icons.lock_outline,
                                color: _muted,
                                size: 15,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _matrixPanel() {
    final filtered = _filtered;
    const categories = [
      'All categories',
      'Accounts',
      'Governance',
      'Security',
      'Infrastructure',
      'Verification',
      'Operations',
    ];
    const views = [
      'All permissions',
      'Assigned to selected role',
      'Not assigned to selected role',
      'Sensitive only',
    ];
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: _surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 275,
                child: TextField(
                  onChanged: (s) => setState(() => _search = s),
                  decoration: _input(
                    'Search permission or ID',
                    Icons.search_rounded,
                  ),
                ),
              ),
              SizedBox(
                width: 205,
                child: DropdownButtonFormField<String>(
                  initialValue: _category,
                  isExpanded: true,
                  decoration: _input('Category', Icons.category_outlined),
                  items: [
                    for (final x in categories)
                      DropdownMenuItem(
                        value: x,
                        child: Text(x, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (x) {
                    if (x != null) setState(() => _category = x);
                  },
                ),
              ),
              SizedBox(
                width: 235,
                child: DropdownButtonFormField<String>(
                  initialValue: _access,
                  isExpanded: true,
                  decoration: _input('View', Icons.tune_rounded),
                  items: [
                    for (final x in views)
                      DropdownMenuItem(
                        value: x,
                        child: Text(x, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (x) {
                    if (x != null) setState(() => _access = x);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${filtered.length} of ${_permissions.length} proposed permissions',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ),
              const Icon(Icons.lock_outline_rounded, color: _muted, size: 15),
              const SizedBox(width: 5),
              const Text(
                'Sensitive',
                style: TextStyle(color: _muted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 13),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(child: Text('No permissions match these filters.')),
            )
          else
            LayoutBuilder(
              builder: (context, c) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: c.maxWidth),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(_soft),
                    dataRowMinHeight: 58,
                    dataRowMaxHeight: 72,
                    columnSpacing: 26,
                    columns: const [
                      DataColumn(label: Text('PERMISSION / CATEGORY')),
                      DataColumn(label: Text('IT')),
                      DataColumn(label: Text('VERIFICATION')),
                      DataColumn(label: Text('OPERATIONS')),
                      DataColumn(label: Text('DETAILS')),
                    ],
                    rows: [
                      for (final p in filtered)
                        DataRow(
                          cells: [
                            DataCell(
                              SizedBox(
                                width: 235,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: _ink,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${p.id}  ·  ${p.category}${p.sensitive ? '  ·  Sensitive' : ''}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: _muted,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            _accessCell(p, _AdminRole.it),
                            _accessCell(p, _AdminRole.verification),
                            _accessCell(p, _AdminRole.operations),
                            DataCell(
                              IconButton(
                                tooltip: 'Explain ${p.name}',
                                icon: const Icon(
                                  Icons.info_outline_rounded,
                                  color: _green,
                                ),
                                onPressed: () => _showDetails(p),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  DataCell _accessCell(_Permission p, _AdminRole role) {
    final allowed = p.owners.contains(role);
    return DataCell(
      Tooltip(
        message: allowed ? 'Proposed: allowed' : 'Proposed: not assigned',
        child: Icon(
          allowed
              ? Icons.check_circle_rounded
              : Icons.remove_circle_outline_rounded,
          color: allowed ? _green : const Color(0xFFBAC4BD),
          size: 20,
        ),
      ),
    );
  }

  Widget _draftPanel() => Container(
    padding: const EdgeInsets.all(20),
    decoration: _surface(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Draft access-change requests',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_drafts.length} unsaved, local-only proposals',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
            FilledButton.icon(
              onPressed: _openDraftDialog,
              style: FilledButton.styleFrom(backgroundColor: _forest),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('New proposal'),
            ),
          ],
        ),
        const SizedBox(height: 15),
        if (_drafts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
            decoration: BoxDecoration(
              color: _paper,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Column(
              children: [
                Icon(Icons.fact_check_outlined, color: _green, size: 30),
                SizedBox(height: 8),
                Text(
                  'No draft requests yet',
                  style: TextStyle(color: _ink, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 5),
                Text(
                  'Proposals are not applied to the matrix or database.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          )
        else
          for (final draft in _drafts.reversed) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: _soft,
                child: Icon(
                  draft.grant
                      ? Icons.add_moderator_outlined
                      : Icons.remove_moderator_outlined,
                  color: _forest,
                ),
              ),
              title: Text(
                '${draft.grant ? 'Propose grant' : 'Propose revoke'} · ${draft.permission.name}',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                '${draft.role.label} · ${_dateTime(draft.createdAt)}\n${draft.justification}',
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
              isThreeLine: true,
              trailing: IconButton(
                tooltip: 'Discard local draft',
                onPressed: () => setState(() => _drafts.remove(draft)),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFAE5555),
                ),
              ),
            ),
            const Divider(color: _stroke),
          ],
        if (_drafts.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _copyDraftCsv,
              icon: const Icon(Icons.copy_all_outlined),
              label: const Text('Copy draft CSV'),
            ),
          ),
      ],
    ),
  );

  Widget _governanceNotes() => Container(
    padding: const EdgeInsets.all(19),
    decoration: BoxDecoration(
      color: _soft,
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Before activating real permissions',
          style: TextStyle(
            color: _forest,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 9),
        Text(
          '1. Get formal LGU approval for each role and sensitive permission.\n'
          '2. Enforce the same decisions in a trusted backend and Supabase RLS.\n'
          '3. Require independent approval for privileged role changes.\n'
          '4. Log actor, target, reason, timestamp and outcome.\n'
          '5. Test that a user cannot access another role through direct URLs or API calls.',
          style: TextStyle(color: _ink, fontSize: 12, height: 1.8),
        ),
      ],
    ),
  );

  InputDecoration _input(String hint, IconData icon) => InputDecoration(
    labelText: hint,
    prefixIcon: Icon(icon, color: _green, size: 19),
    filled: true,
    fillColor: _paper,
    isDense: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _stroke),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _stroke),
    ),
  );

  BoxDecoration _surface() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: _stroke),
    boxShadow: const [
      BoxShadow(color: Color(0x080B3020), blurRadius: 20, offset: Offset(0, 7)),
    ],
  );

  void _showDetails(_Permission p) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(p.name),
        content: SizedBox(
          width: 430,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${p.id}  ·  ${p.category}',
                  style: const TextStyle(
                    color: _green,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 13),
                Text(p.description),
                const SizedBox(height: 17),
                Text(
                  p.sensitive
                      ? 'SENSITIVE · requires additional safeguards'
                      : 'Standard proposed permission',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Proposed roles',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                for (final role in _AdminRole.values)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(
                      p.owners.contains(role)
                          ? Icons.check_circle
                          : Icons.block_outlined,
                      color: p.owners.contains(role) ? _green : _muted,
                    ),
                    title: Text(
                      role.label,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _openDraftDialog() async {
    var role = _selected;
    var permissionId = _permissions.first.id;
    var grant = true;
    var reasonText = '';
    final result = await showDialog<_DraftRequest>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Propose access change'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DRAFT ONLY — Does not change Supabase access.',
                    style: TextStyle(color: _muted, fontSize: 11),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<_AdminRole>(
                    initialValue: role,
                    decoration: const InputDecoration(
                      labelText: 'Target role',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final r in _AdminRole.values)
                        DropdownMenuItem(value: r, child: Text(r.label)),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialogState(() => role = v);
                    },
                  ),
                  const SizedBox(height: 13),
                  DropdownButtonFormField<String>(
                    initialValue: permissionId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Permission',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final p in _permissions)
                        DropdownMenuItem(
                          value: p.id,
                          child: Text(
                            '${p.id} · ${p.name}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialogState(() => permissionId = v);
                    },
                  ),
                  const SizedBox(height: 13),
                  DropdownButtonFormField<bool>(
                    initialValue: grant,
                    decoration: const InputDecoration(
                      labelText: 'Requested change',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: true,
                        child: Text('Grant access'),
                      ),
                      DropdownMenuItem(
                        value: false,
                        child: Text('Revoke access'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialogState(() => grant = v);
                    },
                  ),
                  const SizedBox(height: 13),
                  TextField(
                    onChanged: (value) => reasonText = value,
                    maxLines: 3,
                    maxLength: 400,
                    decoration: const InputDecoration(
                      labelText: 'Business justification (required)',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _forest),
              onPressed: () {
                final reason = reasonText.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Enter a justification.')),
                  );
                  return;
                }
                final permission = _permissions.firstWhere(
                  (p) => p.id == permissionId,
                );
                if (permission.owners.contains(role) == grant) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'This matches the current proposed matrix. Choose a different change.',
                      ),
                    ),
                  );
                  return;
                }
                Navigator.pop(
                  dialogContext,
                  _DraftRequest(
                    role: role,
                    permission: permission,
                    grant: grant,
                    justification: reason,
                    createdAt: DateTime.now(),
                  ),
                );
              },
              child: const Text('Save local draft'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _drafts.add(result));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Draft saved locally. No role permissions changed.'),
      ),
    );
  }

  String _dateTime(DateTime date) {
    final hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final min = date.minute.toString().padLeft(2, '0');
    final ampm = date.hour < 12 ? 'AM' : 'PM';
    final month = const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ][date.month - 1];
    return '$month ${date.day}, ${date.year} · $hour12:$min $ampm';
  }

  String _csvCell(String input) {
    // Prevent spreadsheet formula evaluation on pasted/exported data.
    final safe = RegExp(r'^[\s]*[=+@\-]').hasMatch(input) ? "'$input" : input;
    return '"${safe.replaceAll('"', '""')}"';
  }

  Future<void> _copyCsv() async {
    final lines = <String>[
      'Permission ID,Category,Permission,Sensitive,IT,Verification,Operations',
      for (final p in _filtered)
        [
          p.id,
          p.category,
          p.name,
          p.sensitive.toString(),
          p.owners.contains(_AdminRole.it)
              ? 'Proposed allowed'
              : 'Not assigned',
          p.owners.contains(_AdminRole.verification)
              ? 'Proposed allowed'
              : 'Not assigned',
          p.owners.contains(_AdminRole.operations)
              ? 'Proposed allowed'
              : 'Not assigned',
        ].map(_csvCell).join(','),
    ];
    await Clipboard.setData(ClipboardData(text: lines.join('\r\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filtered proposed matrix CSV copied to clipboard.'),
      ),
    );
  }

  Future<void> _copyDraftCsv() async {
    final lines = <String>[
      'Role,Permission ID,Change,Justification,Created At,State',
      for (final d in _drafts)
        [
          d.role.keyName,
          d.permission.id,
          d.grant ? 'Grant' : 'Revoke',
          d.justification,
          _dateTime(d.createdAt),
          'Local draft only',
        ].map(_csvCell).join(','),
    ];
    await Clipboard.setData(ClipboardData(text: lines.join('\r\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Local draft CSV copied to clipboard.')),
    );
  }
}
