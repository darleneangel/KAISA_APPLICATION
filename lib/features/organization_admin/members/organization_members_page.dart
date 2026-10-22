import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/organization_membership_model.dart';
import '../../../shared/repositories/organization_membership_repository.dart';

class OrganizationMembersPage extends StatefulWidget {
  final String organizationId;

  const OrganizationMembersPage({super.key, required this.organizationId});

  @override
  State<OrganizationMembersPage> createState() =>
      _OrganizationMembersPageState();
}

class _OrganizationMembersPageState extends State<OrganizationMembersPage> {
  final repository = OrganizationMembershipRepository.instance;
  final searchController = TextEditingController();

  String selectedFilter = 'Pending';

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

  List<OrganizationMembership> get filteredMembers {
    final query = searchController.text.trim().toLowerCase();

    final members = repository.forOrganization(widget.organizationId);

    return members.where((membership) {
      final matchesFilter =
          selectedFilter == 'All' || membership.status.label == selectedFilter;

      final matchesSearch =
          membership.residentName.toLowerCase().contains(query) ||
          membership.residentEmail.toLowerCase().contains(query) ||
          membership.residentId.toLowerCase().contains(query);

      return matchesFilter && matchesSearch;
    }).toList()..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
  }

  String _formatDate(DateTime date) {
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

    return '${months[date.month - 1]} '
        '${date.day}, ${date.year}';
  }

  Future<void> _review(OrganizationMembership membership, bool approve) async {
    final decision = approve ? 'Approve' : 'Reject';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$decision Membership?'),
        content: Text(
          '$decision the membership application '
          'of ${membership.residentName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(decision),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    try {
      if (approve) {
        repository.approveMembership(membership.id, widget.organizationId);
      } else {
        repository.rejectMembership(membership.id, widget.organizationId);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve
                ? 'Membership application approved.'
                : 'Membership application rejected.',
          ),
        ),
      );
    } on StateError catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Color _statusColor(MembershipStatus status) {
    switch (status) {
      case MembershipStatus.pending:
        return const Color(0xFFB7791F);
      case MembershipStatus.approved:
        return AppColors.green;
      case MembershipStatus.rejected:
        return const Color(0xFFB45309);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = repository.countByStatus(
      widget.organizationId,
      MembershipStatus.pending,
    );
    final approved = repository.countByStatus(
      widget.organizationId,
      MembershipStatus.approved,
    );
    final rejected = repository.countByStatus(
      widget.organizationId,
      MembershipStatus.rejected,
    );

    final members = filteredMembers;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Member Management',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Review membership applications and '
              'manage your organization members.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 850
                    ? 3
                    : constraints.maxWidth >= 520
                    ? 2
                    : 1;
                const gap = 12.0;

                final width =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;

                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    _summaryCard(
                      'Pending Applications',
                      pending,
                      Icons.pending_actions_rounded,
                      const Color(0xFFB7791F),
                      width,
                    ),
                    _summaryCard(
                      'Active Members',
                      approved,
                      Icons.groups_rounded,
                      AppColors.green,
                      width,
                    ),
                    _summaryCard(
                      'Rejected Applications',
                      rejected,
                      Icons.person_off_rounded,
                      const Color(0xFFB45309),
                      width,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            _panel(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Membership Records',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Search by name, email, or ID',
                      prefixIcon: Icon(Icons.search_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedFilter,
                    decoration: const InputDecoration(
                      labelText: 'Membership Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'All',
                        child: Text('All Records'),
                      ),
                      DropdownMenuItem(
                        value: 'Pending',
                        child: Text('Pending Applications'),
                      ),
                      DropdownMenuItem(
                        value: 'Approved',
                        child: Text('Active Members'),
                      ),
                      DropdownMenuItem(
                        value: 'Rejected',
                        child: Text('Rejected Applications'),
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

            const SizedBox(height: 16),

            if (members.isEmpty)
              _panel(
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No membership records found.'),
                  ),
                ),
              )
            else
              ...members.map(_memberCard),

            const SizedBox(height: 16),
            const Text(
              'Prototype records only. Membership decisions '
              'are currently stored in memory.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(
    String title,
    int value,
    IconData icon,
    Color color,
    double width,
  ) {
    return SizedBox(
      width: width,
      child: _panel(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.10),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              '$value',
              style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _memberCard(OrganizationMembership membership) {
    final color = _statusColor(membership.status);
    final isPending = membership.status == MembershipStatus.pending;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _panel(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.blueLight,
                  child: Icon(Icons.person_rounded, color: AppColors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        membership.residentName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        membership.residentEmail,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        membership.residentId,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(
                  label: Text(membership.status.label),
                  backgroundColor: color.withValues(alpha: 0.12),
                  labelStyle: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Applied: ${_formatDate(membership.requestedAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (membership.reviewedAt != null)
                  Text(
                    'Reviewed: ${_formatDate(membership.reviewedAt!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            if (isPending) ...[
              const Divider(height: 28),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: () => _review(membership, true),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Approve'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _review(membership, false),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Reject'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _panel(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
