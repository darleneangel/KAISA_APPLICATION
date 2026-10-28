import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/kaisa_resident_design.dart';
import 'kaisa_organizations_repository.dart';
import 'kaisa_organization_widgets.dart';

class MyOrganizationsPage extends StatefulWidget {
  const MyOrganizationsPage({super.key});
  @override
  State<MyOrganizationsPage> createState() => _MyOrganizationsPageState();
}

class _MyOrganizationsPageState extends State<MyOrganizationsPage> {
  String filter = 'All';
  List<KaisaOrganization> organizations = [];
  bool loading = true;
  String? error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted)
      setState(() {
        loading = true;
        error = null;
      });
    try {
      final items = await KaisaOrganizationsRepository.instance
          .getOrganizations();
      if (mounted)
        setState(
          () => organizations = items
              .where(
                (o) =>
                    o.myStatus != null &&
                    o.myStatus != 'withdrawn' &&
                    o.myStatus != 'rejected',
              )
              .toList(),
        );
    } catch (e) {
      debugPrint('KAISA memberships: $e');
      if (mounted) setState(() => error = 'Unable to load your memberships.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shown = organizations
        .where(
          (o) =>
              filter == 'All' ||
              (filter == 'Pending'
                  ? o.isPending
                  : o.isMember && o.myRole == filter),
        )
        .toList();
    return KaisaOrganizationPageFrame(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Back to organizations',
                  onPressed: () => context.go('/resident/organizations'),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: KaisaResidentDesign.forest,
                  ),
                ),
                const Expanded(
                  child: KaisaOrganizationHeading(
                    eyebrow: 'YOUR COMMUNITY',
                    title: 'My Organizations',
                    subtitle:
                        'Memberships and requests, updated from Supabase.',
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _load,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: KaisaResidentDesign.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            KaisaOrganizationHero(
              title:
                  '${organizations.where((o) => o.isMember).length} active memberships',
              subtitle:
                  'Explore your communities, roles, and pending membership requests.',
              action: FilledButton.icon(
                onPressed: () => context.go('/resident/organizations'),
                icon: const Icon(Icons.explore_outlined),
                label: const Text('Discover more'),
                style: FilledButton.styleFrom(
                  backgroundColor: KaisaResidentDesign.yellow,
                  foregroundColor: KaisaResidentDesign.forest,
                ),
              ),
            ),
            const SizedBox(height: 19),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final f in const [
                    'All',
                    'Member',
                    'Officer',
                    'Admin',
                    'Pending',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f),
                        selected: filter == f,
                        onSelected: (_) => setState(() => filter = f),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 21),
            if (loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (error != null)
              KaisaOrganizationEmpty(
                title: 'Could not load memberships',
                message: error!,
                action: TextButton(
                  onPressed: _load,
                  child: const Text('Retry'),
                ),
              )
            else if (shown.isEmpty)
              KaisaOrganizationEmpty(
                title: 'No matching organizations',
                message:
                    'Membership requests and approved organizations will appear here.',
                action: TextButton(
                  onPressed: () => context.go('/resident/organizations'),
                  child: const Text('Browse organizations'),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 720 ? 2 : 1;
                  const gap = 14.0;
                  final w =
                      (constraints.maxWidth - gap * (columns - 1)) / columns;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final org in shown)
                        SizedBox(
                          width: w,
                          child: KaisaOrganizationCard(
                            org: org,
                            showMembership: true,
                            onTap: () => context.push(
                              '/resident/organization-details',
                              extra: org.toRouteExtra(),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}
