import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/kaisa_ui.dart';

class OrganizationsPage extends StatefulWidget {
  const OrganizationsPage({super.key});
  @override
  State<OrganizationsPage> createState() => _OrganizationsPageState();
}

class _OrganizationsPageState extends State<OrganizationsPage> {
  final search = TextEditingController();
  String category = 'All';
  final orgs = const [
    (
      'KAISA Youth Volunteers',
      'Youth',
      'Empowering young residents through volunteer work, leadership and participation.',
      128,
      Icons.volunteer_activism_rounded,
    ),
    (
      'Community Environment Network',
      'Environment',
      'Community clean-up drives and environmental sustainability projects.',
      94,
      Icons.eco_rounded,
    ),
    (
      'Community Learning Circle',
      'Education',
      'Local learning programs, workshops and knowledge-sharing initiatives.',
      76,
      Icons.school_rounded,
    ),
    (
      'KAISA Sports Club',
      'Sports',
      'Bringing residents together through sports, fitness and community recreation.',
      156,
      Icons.sports_basketball_rounded,
    ),
    (
      'Community Development Council',
      'Community',
      'Programs and initiatives that strengthen the local community.',
      203,
      Icons.groups_rounded,
    ),
  ];
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = orgs
        .where(
          (e) =>
              (category == 'All' || e.$2 == category) &&
              ('${e.$1} ${e.$3}'.toLowerCase().contains(
                search.text.trim().toLowerCase(),
              )),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organizations'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Organization actions',
            onSelected: (v) => context.push(
              v == 'mine'
                  ? '/resident/my-organizations'
                  : '/resident/request-organization',
            ),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'mine', child: Text('My Organizations')),
              PopupMenuItem(
                value: 'request',
                child: Text('Request Organization'),
              ),
            ],
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: KaisaPageLayout(
        children: [
          const KaisaHero(
            eyebrow: 'MEET YOUR COMMUNITY',
            title: 'Great things\nstart together.',
            subtitle:
                'Find local organizations and groups that share your interests.',
            icon: Icons.diversity_3_rounded,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Search organizations',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in [
                'All',
                'Youth',
                'Community',
                'Environment',
                'Education',
                'Sports',
              ])
                ChoiceChip(
                  label: Text(c),
                  selected: category == c,
                  onSelected: (_) => setState(() => category = c),
                ),
            ],
          ),
          const SizedBox(height: 21),
          Text(
            '${matches.length} community organizations',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
          ),
          const SizedBox(height: 14),
          if (matches.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text('No organizations match your search.'),
            ),
          KaisaResponsiveGrid(
            children: [
              for (final e in matches)
                KaisaTile(
                  title: e.$1,
                  subtitle: '${e.$2}  •  ${e.$4} members\n${e.$3}',
                  icon: e.$5,
                  onTap: () => context.push(
                    '/resident/organization-details',
                    extra: {
                      'name': e.$1,
                      'category': e.$2,
                      'description': e.$3,
                      'members': e.$4,
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
