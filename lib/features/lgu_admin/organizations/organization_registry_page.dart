
import 'package:flutter/material.dart';

import '../../../shared/models/organization_model.dart';
import '../../../shared/repositories/organization_repository.dart';

// Same design tokens as the redesigned KAISA LGU dashboard.
const _forest = Color(0xFF14532D);
const _green = Color(0xFF237A50);
const _paper = Color(0xFFF8FAF8);
const _ink = Color(0xFF173D2B);
const _muted = Color(0xFF687B70);
const _stroke = Color(0xFFE2EBE4);


class OrganizationRegistryPage extends StatefulWidget {
  const OrganizationRegistryPage({super.key});

  @override
  State<OrganizationRegistryPage> createState() =>
      _OrganizationRegistryPageState();
}

class _OrganizationRegistryPageState extends State<OrganizationRegistryPage> {
  final searchController = TextEditingController();

  String statusFilter = 'All';

  final OrganizationRepository repository = OrganizationRepository.instance;

  List<RegistryOrganization> get organizations => repository.organizations;

  @override
  void dispose() {
    repository.removeListener(_refresh);
    searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    repository.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  List<RegistryOrganization> get filteredOrganizations {
    final query = searchController.text.trim().toLowerCase();

    return organizations.where((org) {
      final matchesSearch =
          org.name.toLowerCase().contains(query) ||
          org.category.toLowerCase().contains(query) ||
          org.registryReference.toLowerCase().contains(query);

      final matchesStatus = statusFilter == 'All' || org.status == statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  String nextId() => repository.generateId();

  Future<void> openOrganizationForm([RegistryOrganization? existing]) async {
    final result = await showDialog<RegistryOrganization>(
      context: context,
      builder: (context) =>
          _OrganizationFormDialog(organization: existing, newId: nextId()),
    );

    if (!mounted || result == null) return;

    if (existing == null) {
      repository.addOrganization(result);
    } else {
      repository.updateOrganization(result);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          existing == null
              ? 'Organization added to prototype registry.'
              : 'Organization record updated.',
        ),
      ),
    );
  }

  Future<void> assignAdmin(RegistryOrganization org) async {
    final controller = TextEditingController(text: org.adminEmail);
    final formKey = GlobalKey<FormState>();

    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Assign Organization Admin'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(org.name),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Authorized representative email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty ||
                      !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Prototype only: this records an assignment '
                'but does not grant login permissions.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: const Text('Save Assignment'),
          ),
        ],
      ),
    );

    // The dialog may still be animating out when showDialog completes.
    Future<void>.delayed(
      const Duration(milliseconds: 350),
      controller.dispose,
    );

    if (!mounted || email == null) return;

    repository.assignAdmin(org.id, email);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draft admin assignment saved.')),
    );
  }

  Future<void> toggleStatus(RegistryOrganization org) async {
    final newStatus = org.status == 'Active' ? 'Inactive' : 'Active';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$newStatus Organization?'),
        content: Text(
          'Change ${org.name} to $newStatus? '
          'This only changes its prototype registry status.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      repository.setStatus(org.id, newStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final results = filteredOrganizations;
        final total = organizations.length;
        final active = organizations.where((o) => o.status == 'Active').length;
        final unassigned = organizations
            .where((o) => o.adminEmail.trim().isEmpty)
            .length;

        return ColoredBox(
          color: _paper,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 30, 26, compact ? 16 : 30, 48,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1320),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LGU ADMINISTRATION  /  ORGANIZATIONS',
                        style: TextStyle(
                          color: _green,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 9),
                      const Text(
                        'Organization Registry',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 29,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Maintain official organization records, registration status, and assigned representatives.',
                        style: TextStyle(color: _muted, fontSize: 13),
                      ),
                      const SizedBox(height: 25),
                      _summaryStrip(
                        total: total,
                        active: active,
                        unassigned: unassigned,
                        compact: compact,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        decoration: _surfaceDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                              child: Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 16,
                                runSpacing: 14,
                                children: [
                                  const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Registered Organizations',
                                        style: TextStyle(
                                          color: _ink,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Review and manage the organization master list.',
                                        style: TextStyle(color: _muted, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  FilledButton.icon(
                                    onPressed: () => openOrganizationForm(),
                                    icon: const Icon(Icons.add_rounded, size: 18),
                                    label: const Text('Add Organization'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _forest,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(0, 44),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1, color: _stroke),
                            Padding(
                              padding: const EdgeInsets.all(18),
                              child: _filterBar(compact),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${results.length} of $total organizations',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: _muted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      searchController.clear();
                                      setState(() => statusFilter = 'All');
                                    },
                                    icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
                                    label: const Text('Clear filters'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: _green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1, color: _stroke),
                            if (results.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 54, horizontal: 20),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.search_off_outlined, size: 34, color: _muted),
                                      SizedBox(height: 12),
                                      Text('No matching organizations',
                                          style: TextStyle(color: _ink, fontWeight: FontWeight.w700)),
                                      SizedBox(height: 5),
                                      Text('Try a different search or status filter.',
                                          style: TextStyle(color: _muted, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              )
                            else if (compact)
                              ...results.map(_mobileRow)
                            else
                              _organizationTable(results),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Development preview: updates affect prototype records only. Assigning an email does not grant administrator access.',
                        style: TextStyle(color: _muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryStrip({
    required int total,
    required int active,
    required int unassigned,
    required bool compact,
  }) {
    final entries = <(String, int, IconData)>[
      ('Total Organizations', total, Icons.apartment_outlined),
      ('Active Organizations', active, Icons.check_circle_outline),
      ('Unassigned Administrators', unassigned, Icons.person_off_outlined),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 850 ? 3 : constraints.maxWidth >= 460 ? 2 : 1;
        const gap = 12.0;
        final width = (constraints.maxWidth - (columns - 1) * gap) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final entry in entries)
              Container(
                width: width,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
                decoration: _surfaceDecoration(),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F1EA),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(entry.$3, color: _forest, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${entry.$2}', style: const TextStyle(
                            color: _ink, fontSize: 24, fontWeight: FontWeight.w800,
                          )),
                          Text(entry.$1, style: const TextStyle(
                            color: _muted, fontSize: 11,
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _filterBar(bool compact) {
    final search = TextField(
      controller: searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Search name, category or reference...',
        hintStyle: const TextStyle(fontSize: 13, color: _muted),
        prefixIcon: const Icon(Icons.search_rounded, color: _muted, size: 20),
        suffixIcon: searchController.text.isEmpty ? null : IconButton(
          onPressed: () { searchController.clear(); setState(() {}); },
          icon: const Icon(Icons.close_rounded, size: 18),
        ),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
    final filter = DropdownButtonFormField<String>(
      key: ValueKey(statusFilter),
      initialValue: statusFilter,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Status',
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: const ['All', 'Active', 'Inactive'].map((status) =>
          DropdownMenuItem(value: status, child: Text(status))).toList(),
      onChanged: (value) => setState(() => statusFilter = value ?? 'All'),
    );
    if (compact) {
      return Column(children: [search, const SizedBox(height: 12), filter]);
    }
    return Row(children: [
      Expanded(flex: 3, child: search),
      const SizedBox(width: 12),
      SizedBox(width: 180, child: filter),
    ]);
  }

  Widget _organizationTable(List<RegistryOrganization> records) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF2F6F2)),
        dataRowMinHeight: 64,
        dataRowMaxHeight: 76,
        columnSpacing: 22,
        horizontalMargin: 20,
        dividerThickness: .6,
        columns: const [
          DataColumn(label: Text('ORGANIZATION')),
          DataColumn(label: Text('CATEGORY')),
          DataColumn(label: Text('REGISTRY REFERENCE')),
          DataColumn(label: Text('STATUS')),
          DataColumn(label: Text('ASSIGNED ADMIN')),
          DataColumn(label: Text('ACTIONS')),
        ],
        rows: [
          for (final org in records)
            DataRow(cells: [
              DataCell(SizedBox(
                width: 220,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(org.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _ink, fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(org.id, style: const TextStyle(color: _muted, fontSize: 11)),
                  ],
                ),
              )),
              DataCell(Text(org.category, style: const TextStyle(fontSize: 12))),
              DataCell(SizedBox(width: 155, child: Text(org.registryReference,
                overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)))),
              DataCell(_statusTag(org.status)),
              DataCell(SizedBox(width: 185, child: Text(
                org.adminEmail.isEmpty ? 'Not assigned' : org.adminEmail,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12,
                  color: org.adminEmail.isEmpty ? _muted : _ink),
              ))),
              DataCell(_actionsMenu(org)),
            ]),
        ],
      ),
    );
  }

  Widget _mobileRow(RegistryOrganization org) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _stroke)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(org.name,
              style: const TextStyle(color: _ink, fontWeight: FontWeight.w700, fontSize: 14))),
            _actionsMenu(org),
          ]),
          const SizedBox(height: 7),
          Text('${org.id}  •  ${org.category}',
              style: const TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 10),
          _statusTag(org.status),
          const SizedBox(height: 9),
          Text('Reference: ${org.registryReference}',
              style: const TextStyle(color: _muted, fontSize: 12)),
          Text('Admin: ${org.adminEmail.isEmpty ? 'Not assigned' : org.adminEmail}',
              style: const TextStyle(color: _muted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _statusTag(String status) {
    final active = status == 'Active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE7F3E9) : const Color(0xFFFFF3D8),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(status, style: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w700,
        color: active ? _forest : const Color(0xFF94670A),
      )),
    );
  }

  Widget _actionsMenu(RegistryOrganization org) {
    return PopupMenuButton<String>(
      tooltip: 'Organization actions',
      icon: const Icon(Icons.more_horiz_rounded, color: _forest),
      onSelected: (action) {
        switch (action) {
          case 'edit':
            openOrganizationForm(org);
          case 'admin':
            assignAdmin(org);
          case 'status':
            toggleStatus(org);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'edit', child: Text('Edit organization')),
        PopupMenuItem(value: 'admin', child: Text(
          org.adminEmail.isEmpty ? 'Assign administrator' : 'Change administrator')),
        PopupMenuItem(value: 'status', child: Text(
          org.status == 'Active' ? 'Deactivate organization' : 'Activate organization')),
      ],
    );
  }

  BoxDecoration _surfaceDecoration() => BoxDecoration(
    color: Colors.white,
    border: Border.all(color: _stroke),
    borderRadius: BorderRadius.circular(12),
  );
}

class _OrganizationFormDialog extends StatefulWidget {
  final RegistryOrganization? organization;
  final String newId;

  const _OrganizationFormDialog({
    required this.organization,
    required this.newId,
  });

  @override
  State<_OrganizationFormDialog> createState() =>
      _OrganizationFormDialogState();
}

class _OrganizationFormDialogState extends State<_OrganizationFormDialog> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController name;
  late final TextEditingController description;
  late final TextEditingController email;
  late final TextEditingController reference;

  String category = 'Youth';
  String status = 'Active';

  static const categories = [
    'Youth',
    'Civic',
    'Health',
    'Environment',
    'Education',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    final org = widget.organization;

    name = TextEditingController(text: org?.name ?? '');
    description = TextEditingController(text: org?.description ?? '');
    email = TextEditingController(text: org?.email ?? '');
    reference = TextEditingController(text: org?.registryReference ?? '');

    category = org?.category ?? 'Youth';
    status = org?.status ?? 'Active';
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    email.dispose();
    reference.dispose();
    super.dispose();
  }

  String? requiredField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  void save() {
    if (!formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      RegistryOrganization(
        id: widget.organization?.id ?? widget.newId,
        name: name.text.trim(),
        category: category,
        description: description.text.trim(),
        email: email.text.trim(),
        registryReference: reference.text.trim(),
        adminEmail: widget.organization?.adminEmail ?? '',
        status: status,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(
        widget.organization == null ? 'Add organization' : 'Edit organization',
        style: const TextStyle(color: _ink, fontWeight: FontWeight.w900),
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(name, 'Organization Name'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => category = v ?? 'Youth'),
                ),
                const SizedBox(height: 12),
                _field(description, 'Description', maxLines: 3),
                const SizedBox(height: 12),
                _field(email, 'Contact Email', emailField: true),
                const SizedBox(height: 12),
                _field(reference, 'LGU Registry Reference'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Active', 'Inactive']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => status = v ?? 'Active'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: save, style: FilledButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white), child: const Text('Save organization')),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    bool emailField = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: emailField
          ? TextInputType.emailAddress
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        alignLabelWithHint: maxLines > 1,
      ),
      validator: (value) {
        final requiredError = requiredField(value);
        if (requiredError != null) return requiredError;

        if (emailField &&
            !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!.trim())) {
          return 'Enter a valid email address';
        }
        return null;
      },
    );
  }
}
