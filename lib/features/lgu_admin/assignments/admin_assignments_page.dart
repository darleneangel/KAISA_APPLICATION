import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/organization_model.dart';
import '../../../shared/repositories/organization_repository.dart';

class AdminAssignmentsPage extends StatefulWidget {
  const AdminAssignmentsPage({super.key});

  @override
  State<AdminAssignmentsPage> createState() => _AdminAssignmentsPageState();
}

class _AdminAssignmentsPageState extends State<AdminAssignmentsPage> {
  final OrganizationRepository repository = OrganizationRepository.instance;

  final TextEditingController searchController = TextEditingController();

  String selectedFilter = 'All';

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

    return repository.organizations.where((org) {
      final assigned = org.adminEmail.trim().isNotEmpty;

      final matchesFilter = switch (selectedFilter) {
        'Assigned' => assigned,
        'Unassigned' => !assigned,
        _ => true,
      };

      final matchesSearch =
          org.name.toLowerCase().contains(query) ||
          org.category.toLowerCase().contains(query) ||
          org.id.toLowerCase().contains(query) ||
          org.adminEmail.toLowerCase().contains(query);

      return matchesFilter && matchesSearch;
    }).toList();
  }

  Future<void> _editAssignment(RegistryOrganization organization) async {
    final controller = TextEditingController(text: organization.adminEmail);

    final formKey = GlobalKey<FormState>();

    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            organization.adminEmail.isEmpty
                ? 'Assign Administrator'
                : 'Change Administrator',
          ),
          content: SizedBox(
            width: 440,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    organization.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    organization.id,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: controller,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Administrator Email',
                      hintText: 'admin@example.com',
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';

                      if (!RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      ).hasMatch(email)) {
                        return 'Enter a valid email address.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Prototype only. Assigning an email does '
                    'not grant account access yet.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
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
            FilledButton.icon(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, controller.text.trim());
                }
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Assignment'),
            ),
          ],
        );
      },
    );

    // Defer disposal until the dialog's closing animation
    // has finished.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(
        const Duration(milliseconds: 350),
        controller.dispose,
      );
    });

    if (!mounted || email == null) return;

    repository.assignAdmin(organization.id, email);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Administrator assignment saved.')),
    );
  }

  Future<void> _removeAssignment(RegistryOrganization organization) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Administrator?'),
        content: Text(
          'Remove ${organization.adminEmail} as the '
          'assigned administrator of ${organization.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    repository.assignAdmin(organization.id, '');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Administrator assignment removed.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final organizations = filteredOrganizations;
    final total = repository.totalOrganizations;
    final unassigned = repository.unassignedOrganizations;
    final assigned = total - unassigned;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Admin Assignments',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Manage authorized representatives for '
              'registered community organizations.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 800 ? 3 : 1;
                const spacing = 12.0;
                final width =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    _summaryCard(
                      'Total Organizations',
                      total,
                      Icons.apartment_rounded,
                      AppColors.blue,
                      width,
                    ),
                    _summaryCard(
                      'Assigned Administrators',
                      assigned,
                      Icons.verified_user_rounded,
                      AppColors.green,
                      width,
                    ),
                    _summaryCard(
                      'Pending Assignments',
                      unassigned,
                      Icons.person_off_rounded,
                      const Color(0xFFB7791F),
                      width,
                    ),
                  ],
                );
              },
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
                        hintText: 'Search organizations or administrators',
                        prefixIcon: Icon(Icons.search_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedFilter,
                      decoration: const InputDecoration(
                        labelText: 'Assignment Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'All',
                          child: Text('All Organizations'),
                        ),
                        DropdownMenuItem(
                          value: 'Assigned',
                          child: Text('Assigned'),
                        ),
                        DropdownMenuItem(
                          value: 'Unassigned',
                          child: Text('Unassigned'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedFilter = value ?? 'All';
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (organizations.isEmpty)
              const Card(
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Text('No matching organizations found.'),
                  ),
                ),
              )
            else
              ...organizations.map(_assignmentCard),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(
    String title,
    int count,
    IconData icon,
    Color color,
    double width,
  ) {
    return SizedBox(
      width: width,
      child: Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.10),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _assignmentCard(RegistryOrganization organization) {
    final assigned = organization.adminEmail.isNotEmpty;

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
              runSpacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      organization.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${organization.id} • '
                      '${organization.category}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Chip(
                  label: Text(assigned ? 'Assigned' : 'Unassigned'),
                  backgroundColor: assigned
                      ? AppColors.greenLight
                      : AppColors.yellowLight,
                ),
              ],
            ),
            const Divider(height: 28),
            const Text(
              'Authorized Administrator',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  size: 20,
                  color: AppColors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    assigned
                        ? organization.adminEmail
                        : 'No administrator assigned',
                    style: TextStyle(
                      fontWeight: assigned
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => _editAssignment(organization),
                  icon: Icon(
                    assigned
                        ? Icons.edit_outlined
                        : Icons.person_add_alt_1_rounded,
                  ),
                  label: Text(
                    assigned ? 'Change Administrator' : 'Assign Administrator',
                  ),
                ),
                if (assigned)
                  OutlinedButton.icon(
                    onPressed: () => _removeAssignment(organization),
                    icon: const Icon(Icons.person_remove_outlined),
                    label: const Text('Remove'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
