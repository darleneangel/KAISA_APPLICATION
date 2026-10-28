import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/kaisa_resident_design.dart';
import 'kaisa_organizations_repository.dart';
import 'kaisa_organization_widgets.dart';

class OrganizationsPage extends StatefulWidget {
  const OrganizationsPage({super.key});
  @override
  State<OrganizationsPage> createState() => _OrganizationsPageState();
}

class _OrganizationsPageState extends State<OrganizationsPage> {
  final search = TextEditingController();
  List<KaisaOrganization> _orgs = [];
  String category = 'All';
  bool loading = true;
  String? error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted)
      setState(() {
        loading = true;
        error = null;
      });
    try {
      final data = await KaisaOrganizationsRepository.instance
          .getOrganizations();
      if (mounted) setState(() => _orgs = data);
    } catch (e) {
      debugPrint('KAISA organizations catalog: $e');
      if (mounted)
        setState(
          () => error =
              'Unable to load organizations. Check the Supabase migration and your connection.',
        );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = search.text.toLowerCase().trim();
    final categories = [
      'All',
      ..._orgs.map((o) => o.category).where((c) => c != 'All').toSet(),
    ];
    final shown = _orgs
        .where(
          (o) =>
              (category == 'All' || o.category == category) &&
              ('${o.name} ${o.category} ${o.description} ${o.location}'
                  .toLowerCase()
                  .contains(query)),
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
                const Expanded(
                  child: KaisaOrganizationHeading(
                    eyebrow: 'MEET YOUR COMMUNITY',
                    title: 'Organizations',
                    subtitle: 'Find communities and causes that matter to you.',
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh organizations',
                  onPressed: _load,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: KaisaResidentDesign.forest,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            KaisaOrganizationHero(
              title: 'Great things start together.',
              subtitle:
                  'Explore LGU-recognized groups, apply for membership, and discover opportunities.',
              action: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => context.push('/resident/my-organizations'),
                    icon: const Icon(Icons.groups_outlined),
                    label: const Text('My Organizations'),
                    style: FilledButton.styleFrom(
                      backgroundColor: KaisaResidentDesign.yellow,
                      foregroundColor: KaisaResidentDesign.forest,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.push('/resident/request-organization'),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Propose a group'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Find organizations',
                hintText: 'Search name, category, location...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 13),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final c in categories)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(c),
                        selected: category == c,
                        onSelected: (_) => setState(() => category = c),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 23),
            KaisaResidentSectionHeading(
              title: 'Discover organizations',
              subtitle: loading
                  ? 'Loading community groups...'
                  : '${shown.length} published organizations',
            ),
            const SizedBox(height: 13),
            if (loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (error != null)
              KaisaOrganizationEmpty(
                title: 'Could not load organizations',
                message: error!,
                action: OutlinedButton(
                  onPressed: _load,
                  child: const Text('Try again'),
                ),
              )
            else if (shown.isEmpty)
              KaisaOrganizationEmpty(
                title: 'No organizations found',
                message: _orgs.isEmpty
                    ? 'No organizations have been published by the LGU yet.'
                    : 'Try a different search or category.',
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 850
                      ? 3
                      : constraints.maxWidth >= 580
                      ? 2
                      : 1;
                  const gap = 14.0;
                  final cardWidth =
                      (constraints.maxWidth - gap * (columns - 1)) / columns;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final org in shown)
                        SizedBox(
                          width: cardWidth,
                          child: KaisaOrganizationCard(
                            org: org,
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
