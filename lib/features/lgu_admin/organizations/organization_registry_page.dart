import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_saver/file_saver.dart';

import '../../../shared/models/organization_model.dart';
import '../../../shared/repositories/organization_repository.dart';

// Same design tokens as the redesigned KAISA LGU dashboard.
const _forest = Color(0xFF14532D);
const _green = Color(0xFF237A50);
const _paper = Color(0xFFF8FAF8);
const _ink = Color(0xFF173D2B);
const _muted = Color(0xFF687B70);
const _stroke = Color(0xFFE2EBE4);
const _gold = Color(0xFFFFCC47);

class OrganizationRegistryPage extends StatefulWidget {
  const OrganizationRegistryPage({super.key});

  @override
  State<OrganizationRegistryPage> createState() =>
      _OrganizationRegistryPageState();
}

class _OrganizationRegistryPageState extends State<OrganizationRegistryPage> {
  final searchController = TextEditingController();

  String categoryFilter = 'All';

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

      final matchesCategory =
          categoryFilter == 'All' || org.category == categoryFilter;

      return matchesSearch && matchesCategory;
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
        title: const Text('Assign organization representative'),
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
                'Draft registry assignment only. This does not create a user, '
                'change an account role, or grant access. IT provisions approved access separately.',
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
    Future<void>.delayed(const Duration(milliseconds: 350), controller.dispose);

    if (!mounted || email == null) return;

    repository.assignAdmin(org.id, email);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draft admin assignment saved.')),
    );
  }

  bool _exportingPdf = false;

  /// Downloads the current filtered registry as an actual PDF document.
  /// Prototype data only; no organization status is shown or exported.
  Future<void> exportPdf() async {
    if (_exportingPdf) return;
    setState(() => _exportingPdf = true);
    try {
      final records = filteredOrganizations;
      final document = pw.Document();
      document.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(30),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('KAISA  |  OPERATIONS ADMINISTRATION',
                style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('00492C'))),
              pw.SizedBox(height: 6),
              pw.Text('Organization Registry Report',
                style: pw.TextStyle(fontSize: 19, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Text('Filtered organizations: ${records.length} / ${organizations.length}  |  Generated: ${DateTime.now().toLocal().toString().split('.').first}',
                style: const pw.TextStyle(fontSize: 9)),
              pw.Divider(),
              pw.SizedBox(height: 10),
            ],
          ),
          footer: (context) => pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('KAISA prototype registry  |  Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8)),
          ),
          build: (_) => [
            if (records.isEmpty)
              pw.Text('No organizations match the current filters.'),
            if (records.isNotEmpty)
              pw.TableHelper.fromTextArray(
                headers: const [
                  'Organization', 'Category', 'Registry Ref.',
                  'Contact Email', 'Representative',
                ],
                data: [for (final org in records) [
                  org.name, org.category, org.registryReference,
                  org.email, org.adminEmail.isEmpty ? 'Not assigned' : org.adminEmail,
                ]],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
                headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('00492C')),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellPadding: const pw.EdgeInsets.all(7),
                oddRowDecoration: pw.BoxDecoration(color: PdfColor.fromHex('EAF5EE')),
                border: pw.TableBorder.all(color: PdfColor.fromHex('DFE9E0'), width: 0.5),
              ),
          ],
        ),
      );
      final bytes = Uint8List.fromList(await document.save());
      await FileSaver.instance.saveFile(
        name: 'kaisa_organization_registry_${DateTime.now().millisecondsSinceEpoch}',
        bytes: bytes,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Organization Registry PDF exported.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF export failed: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  void showOrganizationDetails(RegistryOrganization org) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Organization record'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detail('Organization', org.name),
                _detail('Record ID', org.id),
                _detail('Category', org.category),
                _detail('LGU registry reference', org.registryReference),
                _detail('Contact email', org.email),
                _detail(
                  'Representative',
                  org.adminEmail.isEmpty ? 'Not assigned' : org.adminEmail,
                ),
                _detail('Description', org.description),
                const SizedBox(height: 12),
                const Text(
                  'Local registry information only. Assignment does not grant application access.',
                  style: TextStyle(fontSize: 11, color: _muted),
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

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _muted, fontSize: 11)),
        const SizedBox(height: 3),
        Text(
          value.isEmpty ? 'Not provided' : value,
          style: const TextStyle(
            color: _ink,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final results = filteredOrganizations;
        final total = organizations.length;
        final unassigned = organizations
            .where((o) => o.adminEmail.trim().isEmpty)
            .length;

        return ColoredBox(
          color: _paper,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 30,
              26,
              compact ? 16 : 30,
              48,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1320),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(compact ? 22 : 29),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF0B3024),
                              Color(0xFF16593E),
                              Color(0xFF288258),
                            ],
                          ),
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          spacing: 16,
                          runSpacing: 13,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 600),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'KAISA  /  OPERATIONS  /  REGISTRY',
                                    style: TextStyle(
                                      color: _gold,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.3,
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Organization Registry',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: compact ? 27 : 33,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 9),
                                  const Text(
                                    'Maintain organization records and responsible representatives, with clear registration references.',
                                    style: TextStyle(
                                      color: Color(0xFFE2EEE5),
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white30),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.shield_outlined,
                                    color: _gold,
                                    size: 19,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'OPERATIONS ADMIN',
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
                      ),
                      const SizedBox(height: 25),
                      _summaryStrip(
                        total: total,
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
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                20,
                                20,
                                16,
                              ),
                              child: Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 16,
                                runSpacing: 14,
                                children: [
                                  const Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        style: TextStyle(
                                          color: _muted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: _exportingPdf ? null : exportPdf,
                                        icon: const Icon(Icons.picture_as_pdf_outlined),
                                        label: Text(_exportingPdf ? 'Exporting...' : 'Export PDF'),
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
                                      setState(() {
                                        categoryFilter = 'All';
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.filter_alt_off_outlined,
                                      size: 16,
                                    ),
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
                                padding: EdgeInsets.symmetric(
                                  vertical: 54,
                                  horizontal: 20,
                                ),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.search_off_outlined,
                                        size: 34,
                                        color: _muted,
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'No matching organizations',
                                        style: TextStyle(
                                          color: _ink,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        'Try a different search or category filter.',
                                        style: TextStyle(
                                          color: _muted,
                                          fontSize: 12,
                                        ),
                                      ),
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
    required int unassigned,
    required bool compact,
  }) {
    final entries = <(String, int, IconData)>[
      ('Total Organizations', total, Icons.apartment_outlined),
      ('Unassigned Administrators', unassigned, Icons.person_off_outlined),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 850
            ? 3
            : constraints.maxWidth >= 460
            ? 2
            : 1;
        const gap = 12.0;
        final width = (constraints.maxWidth - (columns - 1) * gap) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final entry in entries)
              Container(
                width: width,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 17,
                ),
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
                          Text(
                            '${entry.$2}',
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            entry.$1,
                            style: const TextStyle(color: _muted, fontSize: 11),
                          ),
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
        suffixIcon: searchController.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  searchController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
    final categoryOptions = <String>{
      'All',
      ...organizations.map((o) => o.category),
    }.toList()..sort();
    final categorySelect = DropdownButtonFormField<String>(
      key: ValueKey('category-$categoryFilter'),
      initialValue: categoryFilter,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Category',
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: [
        for (final category in categoryOptions)
          DropdownMenuItem(
            value: category,
            child: Text(category, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (value) => setState(() => categoryFilter = value ?? 'All'),
    );
    if (compact) {
      return Column(
        children: [
          search,
          const SizedBox(height: 12),
          categorySelect,
        ],
      );
    }
    return Row(
      children: [
        Expanded(flex: 3, child: search),
        const SizedBox(width: 12),
        SizedBox(width: 180, child: categorySelect),
      ],
    );
  }

  Widget _organizationTable(List<RegistryOrganization> records) {
    return LayoutBuilder(
      builder: (context, bounds) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: bounds.maxWidth < 960 ? 960 : bounds.maxWidth,
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
              DataColumn(label: Text('ASSIGNED ADMIN')),
              DataColumn(label: Text('ACTIONS')),
            ],
            rows: [
              for (final org in records)
                DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 220,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              org.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _ink,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
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
                      Text(org.category, style: const TextStyle(fontSize: 12)),
                    ),
                    DataCell(
                      SizedBox(
                        width: 155,
                        child: Text(
                          org.registryReference,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 185,
                        child: Text(
                          org.adminEmail.isEmpty
                              ? 'Not assigned'
                              : org.adminEmail,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: org.adminEmail.isEmpty ? _muted : _ink,
                          ),
                        ),
                      ),
                    ),
                    DataCell(_actionsMenu(org)),
                  ],
                ),
            ],
          ),
        ),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  org.name,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              _actionsMenu(org),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            '${org.id}  •  ${org.category}',
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Text(
            'Reference: ${org.registryReference}',
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          Text(
            'Admin: ${org.adminEmail.isEmpty ? 'Not assigned' : org.adminEmail}',
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _actionsMenu(RegistryOrganization org) {
    return PopupMenuButton<String>(
      tooltip: 'Organization actions',
      icon: const Icon(Icons.more_horiz_rounded, color: _forest),
      onSelected: (action) {
        switch (action) {
          case 'details':
            showOrganizationDetails(org);
          case 'edit':
            openOrganizationForm(org);
          case 'admin':
            assignAdmin(org);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'details', child: Text('View details')),
        const PopupMenuItem(value: 'edit', child: Text('Edit organization')),
        PopupMenuItem(
          value: 'admin',
          child: Text(
            org.adminEmail.isEmpty
                ? 'Assign representative (draft)'
                : 'Change representative (draft)',
          ),
        ),
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
        status: widget.organization?.status ?? 'Active',
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
        FilledButton(
          onPressed: save,
          style: FilledButton.styleFrom(
            backgroundColor: _green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save organization'),
        ),
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
