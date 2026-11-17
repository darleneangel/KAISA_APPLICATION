import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/models/organization_model.dart';
import '../../../shared/repositories/organization_repository.dart';

// KAISA · OPERATIONS SUPERADMIN · ORGANIZATION ADMIN ASSIGNMENTS
// These are prototype directory assignments, NOT Supabase Auth grants.
const _deep = Color(0xFF092E23);
const _forest = Color(0xFF14532D);
const _green = Color(0xFF237A50);
const _paper = Color(0xFFF7FAF7);
const _ink = Color(0xFF173D2B);
const _muted = Color(0xFF687B70);
const _stroke = Color(0xFFE2EBE4);
const _soft = Color(0xFFEAF5EE);
const _gold = Color(0xFFFFCF53);

class AdminAssignmentsPage extends StatefulWidget {
  const AdminAssignmentsPage({super.key});

  @override
  State<AdminAssignmentsPage> createState() => _AdminAssignmentsPageState();
}

class _AdminAssignmentsPageState extends State<AdminAssignmentsPage> {
  final OrganizationRepository repository = OrganizationRepository.instance;
  final TextEditingController searchController = TextEditingController();
  String selectedFilter = 'All';
  final List<_AssignmentActivity> _activity = [];

  @override
  void initState() {
    super.initState();
    repository.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    repository.removeListener(_refresh);
    searchController.dispose();
    super.dispose();
  }

  List<RegistryOrganization> get filteredOrganizations {
    final query = searchController.text.trim().toLowerCase();
    final results = repository.organizations.where((org) {
      final assigned = org.adminEmail.trim().isNotEmpty;
      final matchesStatus =
          selectedFilter == 'All' ||
          (selectedFilter == 'Assigned' && assigned) ||
          (selectedFilter == 'Unassigned' && !assigned);
      final matchesSearch =
          query.isEmpty ||
          org.name.toLowerCase().contains(query) ||
          org.category.toLowerCase().contains(query) ||
          org.id.toLowerCase().contains(query) ||
          org.registryReference.toLowerCase().contains(query) ||
          org.adminEmail.toLowerCase().contains(query);
      return matchesStatus && matchesSearch;
    }).toList();
    results.sort((a, b) {
      final aUnassigned = a.adminEmail.trim().isEmpty;
      final bUnassigned = b.adminEmail.trim().isEmpty;
      if (aUnassigned != bUnassigned) return aUnassigned ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return results;
  }

  String _timestamp(DateTime value) {
    const months = [
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
    ];
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    return '${months[value.month - 1]} ${value.day}, ${value.year} · '
        '$hour:${value.minute.toString().padLeft(2, '0')} '
        '${value.hour >= 12 ? 'PM' : 'AM'}';
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _editAssignment(RegistryOrganization org) async {
    final controller = TextEditingController(text: org.adminEmail);
    final formKey = GlobalKey<FormState>();
    final wasAssigned = org.adminEmail.trim().isNotEmpty;
    String? email;
    try {
      email = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            wasAssigned ? 'Change representative' : 'Assign representative',
            style: const TextStyle(color: _ink, fontWeight: FontWeight.w800),
          ),
          content: SizedBox(
            width: 455,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      org.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _forest,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${org.id}  ·  ${org.category}',
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                    const SizedBox(height: 22),
                    TextFormField(
                      controller: controller,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: 'Authorized representative email',
                        hintText: 'representative@example.com',
                        prefixIcon: const Icon(Icons.alternate_email_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (!RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        ).hasMatch(text)) {
                          return 'Enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    _noticeInline(
                      'Directory assignment only. This does not create an account, '
                      'confirm the person’s authority, or grant Supabase access.',
                    ),
                  ],
                ),
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
                if (formKey.currentState!.validate()) {
                  Navigator.pop(
                    dialogContext,
                    controller.text.trim().toLowerCase(),
                  );
                }
              },
              child: const Text('Review assignment'),
            ),
          ],
        ),
      );
    } finally {
      // Leave the field alive while the closing route finishes animating.
      Future<void>.delayed(
        const Duration(milliseconds: 400),
        controller.dispose,
      );
    }
    if (!mounted ||
        email == null ||
        email == org.adminEmail.trim().toLowerCase())
      return;

    final approved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm directory assignment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Organization: ${org.name}'),
            const SizedBox(height: 8),
            Text(
              'Representative: $email',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 13),
            const Text(
              'This only updates the local prototype organization registry. '
              'It does not invite this person or grant an administrator role.',
              style: TextStyle(color: _muted, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _forest),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm assignment'),
          ),
        ],
      ),
    );
    if (!mounted || approved != true) return;
    final previous = org.adminEmail;
    repository.assignAdmin(org.id, email);
    setState(
      () => _activity.insert(
        0,
        _AssignmentActivity(
          org.name,
          wasAssigned ? 'Changed representative' : 'Assigned representative',
          '$previous → $email',
          DateTime.now(),
        ),
      ),
    );
    _toast('Prototype representative assignment saved.');
  }

  Future<void> _removeAssignment(RegistryOrganization org) async {
    if (org.adminEmail.trim().isEmpty) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove representative?'),
        content: Text(
          'Remove ${org.adminEmail} from ${org.name}? '
          'This clears the prototype directory assignment only. '
          'It does not revoke a real Supabase login or role.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF9B472A),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove assignment'),
          ),
        ],
      ),
    );
    if (!mounted || approved != true) return;
    final previous = org.adminEmail;
    repository.assignAdmin(org.id, '');
    setState(
      () => _activity.insert(
        0,
        _AssignmentActivity(
          org.name,
          'Removed representative',
          previous,
          DateTime.now(),
        ),
      ),
    );
    _toast('Prototype directory assignment removed.');
  }

  Future<void> _copyDirectory() async {
    String csv(String value) {
      final protected = RegExp(r'^\s*[=+@\-]').hasMatch(value)
          ? "'$value"
          : value;
      return '"${protected.replaceAll('"', '""')}"';
    }

    final rows = <String>[
      'Organization ID,Organization,Category,Registry Reference,Organization Status,Representative Email,Assignment Status',
      for (final org in filteredOrganizations)
        [
          org.id,
          org.name,
          org.category,
          org.registryReference,
          org.status,
          org.adminEmail,
          org.adminEmail.trim().isEmpty ? 'Unassigned' : 'Assigned',
        ].map(csv).join(','),
    ];
    await Clipboard.setData(ClipboardData(text: rows.join('\r\n')));
    _toast('Filtered prototype directory copied as CSV.');
  }

  @override
  Widget build(BuildContext context) {
    final total = repository.totalOrganizations;
    final unassigned = repository.unassignedOrganizations;
    final assigned = total - unassigned;
    final visible = filteredOrganizations;
    return ColoredBox(
      color: _paper,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;
          return ListView(
            padding: EdgeInsets.fromLTRB(
              compact ? 15 : 28,
              22,
              compact ? 15 : 28,
              44,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1320),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _hero(compact),
                      const SizedBox(height: 16),
                      _noticeInline(
                        'DEVELOPMENT PREVIEW — Assignments are stored in the shared '
                        'prototype OrganizationRepository. They do not change Supabase Auth '
                        'or grant access to an organization.',
                      ),
                      const SizedBox(height: 22),
                      _metrics(total, assigned, unassigned),
                      const SizedBox(height: 20),
                      _directory(visible, total, compact),
                      const SizedBox(height: 18),
                      _helpPanel(),
                      if (_activity.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _activityPanel(),
                      ],
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

  Widget _hero(bool compact) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(compact ? 22 : 30),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [_deep, _forest, Color(0xFF23754E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(23),
    ),
    child: Wrap(
      spacing: 18,
      runSpacing: 16,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: compact ? 300 : 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'KAISA  /  OPERATIONS ADMINISTRATION',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _gold,
                  fontSize: 10,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Admin Assignments',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 28 : 33,
                  letterSpacing: -.6,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Designate organization representatives and identify '
                'records that still need an assigned contact.',
                style: TextStyle(
                  color: Color(0xFFDAEADF),
                  height: 1.5,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.assignment_ind_outlined, color: _gold, size: 19),
              SizedBox(width: 8),
              Text(
                'OPERATIONS ONLY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _metrics(int total, int assigned, int unassigned) => LayoutBuilder(
    builder: (context, box) {
      final columns = box.maxWidth >= 830
          ? 3
          : box.maxWidth >= 510
          ? 2
          : 1;
      const gap = 12.0;
      final width = (box.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          _stat(
            'Registered organizations',
            '$total',
            Icons.apartment_outlined,
            width,
          ),
          _stat(
            'Representatives assigned',
            '$assigned',
            Icons.verified_user_outlined,
            width,
          ),
          _stat(
            'Awaiting assignment',
            '$unassigned',
            Icons.person_search_outlined,
            width,
          ),
        ],
      );
    },
  );

  Widget _stat(String title, String value, IconData icon, double width) =>
      Container(
        width: width,
        padding: const EdgeInsets.all(19),
        decoration: _surface(),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: _soft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _green, size: 23),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: _forest,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _directory(
    List<RegistryOrganization> visible,
    int total,
    bool compact,
  ) => Container(
    decoration: _surface(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Organization representatives',
                style: TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Search the registry and assign or remove a representative.',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
              const SizedBox(height: 17),
              LayoutBuilder(
                builder: (context, c) => Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: c.maxWidth >= 540 ? 310 : c.maxWidth,
                      child: TextField(
                        controller: searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search organization or email',
                          prefixIcon: const Icon(Icons.search_rounded),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: c.maxWidth >= 540 ? 195 : c.maxWidth,
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(selectedFilter),
                        initialValue: selectedFilter,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Assignment',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        items: ['All', 'Assigned', 'Unassigned']
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => selectedFilter = value ?? 'All'),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _copyDirectory,
                      icon: const Icon(Icons.copy_all_outlined, size: 18),
                      label: const Text('Copy CSV'),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        selectedFilter = 'All';
                        searchController.clear();
                      }),
                      child: const Text('Clear filters'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Showing ${visible.length} of $total organizations · '
                'unassigned records first',
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: _stroke),
        if (visible.isEmpty)
          const Padding(
            padding: EdgeInsets.all(34),
            child: Center(
              child: Text(
                'No matching organizations.',
                style: TextStyle(color: _muted),
              ),
            ),
          )
        else if (compact)
          for (final org in visible) _mobileRow(org)
        else
          LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: box.maxWidth < 980 ? 980 : box.maxWidth,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(_soft),
                  columnSpacing: 16,
                  horizontalMargin: 19,
                  dataRowMinHeight: 62,
                  dataRowMaxHeight: 74,
                  columns: const [
                    DataColumn(label: Text('ORGANIZATION')),
                    DataColumn(label: Text('CATEGORY')),
                    DataColumn(label: Text('REPRESENTATIVE EMAIL')),
                    DataColumn(label: Text('ASSIGNMENT')),
                    DataColumn(label: Text('ACTIONS')),
                  ],
                  rows: [
                    for (final org in visible)
                      DataRow(
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 225,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    org.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _ink,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    org.id,
                                    style: const TextStyle(
                                      color: _muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 110,
                              child: Text(
                                org.category,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 225,
                              child: Text(
                                org.adminEmail.trim().isEmpty
                                    ? 'Not assigned'
                                    : org.adminEmail,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: org.adminEmail.trim().isEmpty
                                      ? _muted
                                      : _ink,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            _assignmentBadge(org.adminEmail.trim().isNotEmpty),
                          ),
                          DataCell(_actionButtons(org)),
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

  Widget _mobileRow(RegistryOrganization org) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: _stroke)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                org.name,
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            _assignmentBadge(org.adminEmail.trim().isNotEmpty),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          '${org.id}  ·  ${org.category}',
          style: const TextStyle(color: _muted, fontSize: 12),
        ),
        const SizedBox(height: 9),
        Text(
          org.adminEmail.isEmpty
              ? 'No representative assigned'
              : org.adminEmail,
          style: const TextStyle(color: _ink, fontSize: 12),
        ),
        const SizedBox(height: 12),
        _actionButtons(org),
      ],
    ),
  );

  Widget _assignmentBadge(bool assigned) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: assigned ? _soft : const Color(0xFFFFF3D8),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      assigned ? 'Assigned' : 'Unassigned',
      style: TextStyle(
        color: assigned ? _forest : const Color(0xFF95650B),
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _actionButtons(RegistryOrganization org) {
    final assigned = org.adminEmail.trim().isNotEmpty;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton.icon(
          onPressed: () => _editAssignment(org),
          icon: Icon(
            assigned ? Icons.edit_outlined : Icons.person_add_alt_outlined,
            size: 17,
          ),
          label: Text(assigned ? 'Change' : 'Assign'),
        ),
        if (assigned)
          IconButton(
            tooltip: 'Remove representative',
            onPressed: () => _removeAssignment(org),
            icon: const Icon(
              Icons.person_remove_outlined,
              color: Color(0xFF9B472A),
            ),
          ),
      ],
    );
  }

  Widget _helpPanel() => Container(
    padding: const EdgeInsets.all(20),
    decoration: _surface(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.shield_outlined, color: _green, size: 22),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'Assignment and access are different',
                style: TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        const Text(
          'Operations records the designated organization representative. '
          'IT controls account provisioning and secure role enforcement. '
          'An organization email in this registry does not prove identity or '
          'give anyone access to KAISA.',
          style: TextStyle(color: _muted, fontSize: 12, height: 1.55),
        ),
        const SizedBox(height: 15),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded, color: _green, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Before production, require an approved organization '
                'appointment, an existing verified user, server-enforced organization scope, '
                'and a persistent audit log.',
                style: TextStyle(
                  color: _forest.withValues(alpha: .9),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _activityPanel() => Container(
    padding: const EdgeInsets.all(20),
    decoration: _surface(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'This session’s assignment changes',
          style: TextStyle(
            color: _ink,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Local demo history only. Not a persistent audit log.',
          style: TextStyle(color: _muted, fontSize: 12),
        ),
        const SizedBox(height: 15),
        for (final entry in _activity.take(8))
          Padding(
            padding: const EdgeInsets.only(bottom: 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.history_rounded, size: 19, color: _green),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.action} · ${entry.organization}',
                        style: const TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        entry.detail,
                        style: const TextStyle(color: _muted, fontSize: 11),
                      ),
                      Text(
                        _timestamp(entry.at),
                        style: const TextStyle(color: _muted, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );

  Widget _noticeInline(String message) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF7DE),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFF1E4AF)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline_rounded,
          color: Color(0xFF95690E),
          size: 19,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: Color(0xFF745512),
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ),
      ],
    ),
  );

  BoxDecoration _surface() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: _stroke),
    boxShadow: const [
      BoxShadow(color: Color(0x08134F30), blurRadius: 22, offset: Offset(0, 6)),
    ],
  );
}

class _AssignmentActivity {
  final String organization;
  final String action;
  final String detail;
  final DateTime at;
  const _AssignmentActivity(
    this.organization,
    this.action,
    this.detail,
    this.at,
  );
}
