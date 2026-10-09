import 'package:flutter/material.dart';


import '../../../core/theme/app_colors.dart';

import '../../../shared/models/organization_model.dart';
import '../../../shared/repositories/organization_repository.dart';



class OrganizationRegistryPage extends StatefulWidget {
  const OrganizationRegistryPage({super.key});

  @override
  State<OrganizationRegistryPage> createState() =>
      _OrganizationRegistryPageState();
}

class _OrganizationRegistryPageState extends State<OrganizationRegistryPage> {
  final searchController = TextEditingController();

  String statusFilter = 'All';

  final OrganizationRepository repository =
    OrganizationRepository.instance;

  List<RegistryOrganization> get organizations =>
    repository.organizations;

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

    controller.dispose();

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
    final filtered = filteredOrganizations;
    final isMobile = MediaQuery.sizeOf(context).width < 700;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manage Organizations',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Maintain organization records and '
                      'authorized representatives.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: () => openOrganizationForm(),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(isMobile ? 'Add' : 'Add Organization'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _summaryCard(
                  'Total Organizations',
                  organizations.length,
                  Icons.apartment_rounded,
                ),
                _summaryCard(
                  'Active',
                  organizations.where((o) => o.status == 'Active').length,
                  Icons.verified_rounded,
                ),
                _summaryCard(
                  'Without Assigned Admin',
                  organizations.where((o) => o.adminEmail.isEmpty).length,
                  Icons.person_off_rounded,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search name, category, or reference',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: statusFilter,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: ['All', 'Active', 'Inactive']
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          statusFilter = value ?? 'All';
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (filtered.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: Text('No organizations found.')),
                ),
              )
            else
              ...filtered.map(_organizationCard),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String label, int count, IconData icon) {
    return SizedBox(
      width: 220,
      child: Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.blue),
              const SizedBox(height: 12),
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _organizationCard(RegistryOrganization org) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              runSpacing: 10,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      org.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${org.id} • ${org.category}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Chip(
                  label: Text(org.status),
                  backgroundColor: org.status == 'Active'
                      ? AppColors.greenLight
                      : AppColors.yellowLight,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(org.description),
            const SizedBox(height: 10),
            Text('Registry reference: ${org.registryReference}'),
            Text('Contact: ${org.email}'),
            Text(
              'Assigned admin: ${org.adminEmail.isEmpty ? "None" : org.adminEmail}',
            ),
            const Divider(height: 28),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => openOrganizationForm(org),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
                OutlinedButton.icon(
                  onPressed: () => assignAdmin(org),
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: Text(
                    org.adminEmail.isEmpty ? 'Assign Admin' : 'Change Admin',
                  ),
                ),
                TextButton(
                  onPressed: () => toggleStatus(org),
                  child: Text(
                    org.status == 'Active' ? 'Deactivate' : 'Activate',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
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
      title: Text(
        widget.organization == null ? 'Add Organization' : 'Edit Organization',
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
        FilledButton(onPressed: save, child: const Text('Save Organization')),
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
