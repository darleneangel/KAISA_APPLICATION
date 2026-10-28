import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/kaisa_resident_design.dart';

class KaisaSearchPage extends StatefulWidget {
  const KaisaSearchPage({super.key});
  @override
  State<KaisaSearchPage> createState() => _KaisaSearchPageState();
}

class _KaisaSearchPageState extends State<KaisaSearchPage> {
  final query = TextEditingController();
  final focus = FocusNode();
  Timer? debounce;
  int generation = 0;
  bool busy = false;
  String? error;
  List<Map<String, dynamic>> results = [];

  static const shortcuts = <(String, IconData, String)>[
    ('Events', Icons.calendar_month_outlined, '/resident/events'),
    ('Organizations', Icons.groups_outlined, '/resident/organizations'),
    ('Community Feed', Icons.forum_outlined, '/resident/feed'),
    ('Messages', Icons.chat_bubble_outline, '/resident/messages'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) focus.requestFocus();
    });
  }

  void onType(String value) {
    debounce?.cancel();
    final request = ++generation;
    if (value.trim().isEmpty) {
      setState(() {
        results = [];
        busy = false;
        error = null;
      });
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    debounce = Timer(const Duration(milliseconds: 260), () async {
      try {
        final raw = await Supabase.instance.client.rpc(
          'kaisa_global_search',
          params: {'p_query': value.trim()},
        );
        if (!mounted || request != generation) return;
        setState(() {
          results = (raw as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          busy = false;
        });
      } catch (_) {
        if (!mounted || request != generation) return;
        setState(() {
          error =
              'Search is unavailable. Check the search SQL migration and your connection.';
          busy = false;
        });
      }
    });
  }

  void openResult(Map<String, dynamic> result) {
    final id = '${result['id']}';
    switch ('${result['kind']}') {
      case 'resident':
        context.push('/resident/user/$id');
        break;
      case 'event':
        // Existing Event Details route accepts event_id plus legacy fields.
        context.push(
          '/resident/event-details',
          extra: <String, dynamic>{
            'event_id': id,
            'title': result['title'] ?? 'Event',
            'organization': '',
            'category': '',
            'description': '',
            'date': '',
            'time': '',
            'location': '',
            'participants': 0,
            'capacity': 0,
          },
        );
        break;
      case 'organization':
        context.push(
          '/resident/organization-details',
          extra: <String, dynamic>{
            'organization_id': id,
            'name': result['title'] ?? 'Organization',
            'category': '',
            'description': '',
            'members': 0,
          },
        );
        break;
    }
  }

  @override
  void dispose() {
    debounce?.cancel();
    generation++;
    query.dispose();
    focus.dispose();
    super.dispose();
  }

  IconData iconFor(String kind) => switch (kind) {
    'event' => Icons.event_outlined,
    'organization' => Icons.groups_2_outlined,
    _ => Icons.person_outline_rounded,
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: KaisaResidentDesign.paper,
    body: LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 600;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            mobile ? 18 : 32,
            22,
            mobile ? 18 : 32,
            80,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DISCOVER YOUR COMMUNITY',
                    style: TextStyle(
                      fontSize: 11,
                      color: KaisaResidentDesign.green,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Search KAISA',
                    style: TextStyle(
                      fontSize: 29,
                      fontWeight: FontWeight.w900,
                      color: KaisaResidentDesign.ink,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Find events, organizations, and fellow residents.',
                    style: TextStyle(
                      fontSize: 13,
                      color: KaisaResidentDesign.muted,
                    ),
                  ),
                  const SizedBox(height: 19),
                  TextField(
                    controller: query,
                    focusNode: focus,
                    onChanged: onType,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Try “E”, “Youth”, or a resident name',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: KaisaResidentDesign.forest,
                      ),
                      suffixIcon: query.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear',
                              onPressed: () {
                                query.clear();
                                onType('');
                                focus.requestFocus();
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: KaisaResidentDesign.border,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: KaisaResidentDesign.border,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (query.text.trim().isEmpty) ...[
                    const KaisaResidentSectionHeading(
                      title: 'Explore KAISA',
                      subtitle: 'Quick destinations to get started.',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final item in shortcuts)
                          ActionChip(
                            avatar: Icon(
                              item.$2,
                              color: KaisaResidentDesign.green,
                              size: 19,
                            ),
                            label: Text(item.$1),
                            onPressed: () => context.go(item.$3),
                          ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        const Expanded(
                          child: KaisaResidentSectionHeading(
                            title: 'Results',
                            subtitle: 'Matches from your KAISA community',
                          ),
                        ),
                        if (busy)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (error != null)
                      KaisaResidentCard(
                        child: Text(
                          error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    if (!busy && error == null && results.isEmpty)
                      const KaisaResidentCard(
                        child: Text(
                          'No matching events, organizations, or residents. Try another keyword.',
                        ),
                      ),
                    for (final r in results)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => openResult(r),
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: KaisaResidentDesign.cardDecoration(),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE5F2E9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      iconFor('${r['kind']}'),
                                      color: KaisaResidentDesign.forest,
                                    ),
                                  ),
                                  const SizedBox(width: 13),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${r['title']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: KaisaResidentDesign.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${r['subtitle']}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: KaisaResidentDesign.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: KaisaResidentDesign.muted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
