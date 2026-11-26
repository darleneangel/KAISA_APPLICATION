import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../events/kaisa_events_repository.dart';
import '../feed/feed_event_filters.dart';
import '../widgets/kaisa_resident_design.dart';
import 'kaisa_organizations_repository.dart';
import 'kaisa_organization_widgets.dart';
import 'organization_profile_widgets.dart';

class OrganizationDetailsPage extends StatefulWidget {
  const OrganizationDetailsPage({
    super.key,
    this.organizationId,
    required this.name,
    required this.category,
    required this.description,
    required this.members,
    this.inDialog = false,
  });
  final String? organizationId;
  final String name, category, description;
  final int members;
  final bool inDialog;
  @override
  State<OrganizationDetailsPage> createState() =>
      _OrganizationDetailsPageState();
}

class _OrganizationDetailsPageState extends State<OrganizationDetailsPage> {
  KaisaOrganization? org;
  bool loading = true, busy = false, tier2 = false;
  String? error;
  Map<String, dynamic>? profile, feedback;
  List<Map<String, dynamic>> posts = [];
  List<KaisaEvent> events = [];
  Set<String>? following;
  final _about = GlobalKey(), _activity = GlobalKey(), _reviews = GlobalKey();
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }
    try {
      if (widget.organizationId == null || widget.organizationId!.isEmpty) {
        throw StateError('Missing organization ID. Check app_router.dart.');
      }
      final id = widget.organizationId!;
      final repository = KaisaOrganizationsRepository.instance;
      final (
        organization,
        verified,
        metadata,
        follows,
        reviews,
        updates,
        catalog,
        links,
      ) = await (
        repository.getOrganization(id),
        repository.isTier2(),
        repository.profiles(id),
        repository.followedOrganizations(),
        repository.feedback(id),
        repository.announcements(id),
        KaisaEventsRepository.instance.listEvents(),
        repository.eventOrganizations(),
      ).wait;
      if (!mounted) return;
      setState(() {
        org = organization;
        tier2 = verified;
        profile = metadata[id];
        following = follows;
        feedback = reviews;
        posts = updates;
        events = catalog.where((event) {
          final linked = links[event.id];
          return linked == null
              ? event.organization.trim().toLowerCase() ==
                    organization?.name.trim().toLowerCase()
              : linked == id;
        }).toList();
        if (org == null) error = 'Organization unavailable or not published.';
      });
    } catch (e) {
      debugPrint('KAISA organization detail: $e');
      if (mounted) {
        setState(
          () => error = e is StateError
              ? e.message
              : 'Unable to load organization details.',
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _notice(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _request() async {
    final current = org;
    if (current == null || busy) return;
    if (!tier2) {
      final router = GoRouter.of(context);
      if (widget.inDialog) Navigator.of(context).pop();
      router.push('/resident/identity-verification');
      return;
    }
    final withdrawing = current.isPending;
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(
          withdrawing
              ? 'Withdraw membership request?'
              : 'Request to join ${current.name}?',
        ),
        content: Text(
          withdrawing
              ? 'Your pending application will be withdrawn.'
              : 'The organization will review your membership request. You will not be a member until approved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(withdrawing ? 'Withdraw' : 'Submit request'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() => busy = true);
    try {
      if (withdrawing) {
        await KaisaOrganizationsRepository.instance.withdrawRequest(current.id);
      } else {
        await KaisaOrganizationsRepository.instance.requestMembership(
          current.id,
        );
      }
      _notice(
        withdrawing
            ? 'Membership request withdrawn.'
            : 'Request submitted for review.',
      );
      await _load();
    } catch (e) {
      debugPrint('KAISA membership action: $e');
      _notice('Unable to update membership: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _scrollTo(GlobalKey key) {
    final target = key.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 250),
      );
    }
  }

  Widget _section(String title, IconData icon, List<Widget> children) =>
      KaisaResidentCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            Row(
              children: [
                Icon(icon, color: KaisaResidentDesign.forest, size: 19),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: KaisaTypography.heading(
                      const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
            ...children,
          ],
        ),
      );

  Widget _stars(double? rating) => Semantics(
    label: rating == null
        ? 'No resident ratings yet'
        : '${rating.toStringAsFixed(1)} out of 5',
    child: ExcludeSemantics(
      child: Wrap(
        spacing: 2,
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(
              (rating ?? 0) >= i
                  ? Icons.star_rounded
                  : (rating ?? 0) >= i - .5
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded,
              size: 20,
              color: const Color(0xFF946900),
            ),
        ],
      ),
    ),
  );

  Future<void> _writeFeedback(KaisaOrganization current) async {
    try {
      final result = await showDialog<(int, String)>(
        context: context,
        builder: (dialog) {
          var score = 0;
          var comment = '';
          return StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: const Text('Submit member feedback'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    children: [
                      for (var i = 1; i <= 5; i++)
                        IconButton(
                          tooltip: 'Rate $i out of 5',
                          icon: Icon(
                            i <= score
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: const Color(0xFF946900),
                          ),
                          onPressed: () => setDialogState(() => score = i),
                        ),
                    ],
                  ),
                  TextField(
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 1200,
                    onChanged: (value) =>
                        setDialogState(() => comment = value.trim()),
                    decoration: const InputDecoration(labelText: 'Comment'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialog).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: score == 0 || comment.isEmpty
                      ? null
                      : () => Navigator.of(dialog).pop((score, comment)),
                  child: const Text('Save feedback'),
                ),
              ],
            ),
          );
        },
      );
      if (result == null || !mounted) return;
      await KaisaOrganizationsRepository.instance.rate(
        current.id,
        result.$1,
        result.$2,
      );
      _notice('Your feedback was saved.');
      await _load();
    } catch (_) {
      _notice('Could not save feedback. Please try again.');
    }
  }

  Widget _profile(KaisaOrganization current) {
    final details = profile ?? const <String, dynamic>{};
    final rating = (feedback?['rating'] as num?)?.toDouble();
    final count = feedback?['count'] as num? ?? 0;
    final comments = (feedback?['comments'] as List?) ?? const [];
    final goals = (details['sdg_goals'] as List?) ?? const [];
    final gallery = (details['gallery_images'] as List? ?? const [])
        .whereType<String>()
        .toList();
    const goalNames = [
      'No Poverty',
      'Zero Hunger',
      'Good Health and Well-being',
      'Quality Education',
      'Gender Equality',
      'Clean Water and Sanitation',
      'Affordable and Clean Energy',
      'Decent Work and Economic Growth',
      'Industry, Innovation and Infrastructure',
      'Reduced Inequalities',
      'Sustainable Cities and Communities',
      'Responsible Consumption and Production',
      'Climate Action',
      'Life Below Water',
      'Life on Land',
      'Peace, Justice and Strong Institutions',
      'Partnerships for the Goals',
    ];
    final now = DateTime.now();
    final upcoming = events.where((event) => event.endsAt.isAfter(now));
    final past = events
        .where((event) => !event.endsAt.isAfter(now))
        .toList()
        .reversed;
    Widget eventTile(KaisaEvent event) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(
        Icons.event_outlined,
        color: KaisaResidentDesign.green,
      ),
      title: Text(event.title),
      subtitle: Text(
        MaterialLocalizations.of(
          context,
        ).formatMediumDate(feedManilaTime(event.startsAt)),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        final router = GoRouter.of(context);
        if (widget.inDialog) Navigator.of(context).pop();
        router.push('/resident/event-details', extra: event.toRouteExtra());
      },
    );
    final about = Column(
      key: _about,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        _section('About the organization', Icons.info_outline, [
          Text(
            current.description.isEmpty
                ? 'No description provided.'
                : current.description,
          ),
          if (current.mission.isNotEmpty) ...[
            const Text(
              'Mission',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(current.mission),
          ],
          if (details['vision'] case final String vision
              when vision.isNotEmpty) ...[
            const Text('Vision', style: TextStyle(fontWeight: FontWeight.w700)),
            Text(vision),
          ],
        ]),
        if (gallery.isNotEmpty)
          _section('Bayanihan in action', Icons.photo_library_outlined, [
            LayoutBuilder(
              builder: (context, bounds) {
                final width = bounds.maxWidth >= 340
                    ? (bounds.maxWidth - 10) / 2
                    : bounds.maxWidth;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final image in gallery)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: width,
                          height: 140,
                          child: OrganizationImage(
                            reference: image,
                            icon: Icons.photo_outlined,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ]),
        _section('SDG alignment', Icons.track_changes_outlined, [
          if (goals.isEmpty) const Text('No SDG alignment published.'),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final goal in goals.whereType<int>().where(
                (goal) => goal >= 1 && goal <= goalNames.length,
              ))
                Chip(
                  avatar: CircleAvatar(
                    backgroundColor: KaisaResidentDesign.forest,
                    foregroundColor: Colors.white,
                    child: Text('$goal'),
                  ),
                  label: Text(goalNames[goal - 1]),
                  backgroundColor: KaisaResidentDesign.mint,
                ),
            ],
          ),
        ]),
        _section('Official office information', Icons.location_city_outlined, [
          if (current.location.isNotEmpty) Text(current.location),
          if (current.contactEmail.isNotEmpty)
            SelectableText(current.contactEmail),
          if (details['office_hours'] case final String hours
              when hours.isNotEmpty)
            Text(hours),
          if (details['website'] case final String website
              when website.isNotEmpty)
            SelectableText(website),
          if (current.location.isEmpty &&
              current.contactEmail.isEmpty &&
              details['office_hours'] == null &&
              details['website'] == null)
            const Text('No office details published.'),
        ]),
      ],
    );
    final activity = Column(
      key: _activity,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        _section('Announcements', Icons.campaign_outlined, [
          if (posts.isEmpty) const Text('No announcements yet.'),
          for (final post in posts.take(6)) ...[
            Text(
              post['title'] as String,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(post['body'] as String),
            const Divider(),
          ],
        ]),
        _section('Upcoming events', Icons.event_available_outlined, [
          if (upcoming.isEmpty) const Text('No upcoming events.'),
          ...upcoming.map(eventTile),
        ]),
        _section('Past events', Icons.history, [
          if (past.isEmpty) const Text('No past events.'),
          ...past.map(eventTile),
        ]),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 220,
            child: OrganizationImage(
              reference: details['cover_image'] as String?,
              icon: kaisaOrganizationIcon(current.category),
            ),
          ),
        ),
        KaisaResidentCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Row(
                children: [
                  ClipOval(
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: OrganizationImage(
                        reference: details['logo_image'] as String?,
                        icon: kaisaOrganizationIcon(current.category),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          current.category,
                          style: const TextStyle(
                            color: KaisaResidentDesign.green,
                          ),
                        ),
                        Text(
                          current.name,
                          style: KaisaTypography.heading(
                            const TextStyle(fontSize: 26),
                          ),
                        ),
                        Text('${current.memberCount} approved members'),
                      ],
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 5,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _stars(rating),
                  Text(
                    rating == null
                        ? 'No resident ratings yet'
                        : '${rating.toStringAsFixed(1)} · $count resident ratings',
                  ),
                  if (following case final follows?)
                    OrganizationFollowButton(
                      key: ValueKey(current.id),
                      organizationId: current.id,
                      following: follows.contains(current.id),
                    ),
                  if (current.isMember)
                    const Chip(
                      avatar: Icon(Icons.verified_outlined),
                      label: Text('Member'),
                    )
                  else
                    FilledButton(
                      onPressed: busy ? null : _request,
                      child: Text(
                        busy
                            ? 'Processing…'
                            : current.isPending
                            ? 'Withdraw request'
                            : tier2
                            ? 'Request to join'
                            : 'Get Tier 2 verified',
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            TextButton.icon(
              onPressed: () => _scrollTo(_about),
              icon: const Icon(Icons.info_outline),
              label: const Text('Overview'),
            ),
            TextButton.icon(
              onPressed: () => _scrollTo(_activity),
              icon: const Icon(Icons.event_outlined),
              label: const Text('Updates & events'),
            ),
            TextButton.icon(
              onPressed: () => _scrollTo(_reviews),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Resident comments'),
            ),
          ],
        ),
        LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth >= 740
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: about),
                    const SizedBox(width: 16),
                    Expanded(flex: 5, child: activity),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 14,
                  children: [activity, about],
                ),
        ),
        KeyedSubtree(
          key: _reviews,
          child: _section('Resident comments', Icons.chat_bubble_outline, [
            if (feedback != null &&
                current.isMember &&
                current.myRole?.toLowerCase() == 'member')
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton.icon(
                  onPressed: () => _writeFeedback(current),
                  icon: const Icon(Icons.rate_review_outlined),
                  label: const Text('Leave or update feedback'),
                ),
              ),
            if (comments.isEmpty)
              Text(
                feedback == null
                    ? 'Resident comments are currently unavailable.'
                    : 'No resident comments yet.',
              ),
            for (final raw in comments) ...[
              const Divider(),
              _stars((raw['rating'] as num?)?.toDouble()),
              const Text('Approved member feedback'),
              Text(raw['comment'] as String),
            ],
          ]),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = org;
    return Theme(
      data: KaisaTypography.homeTheme(context),
      child: KaisaOrganizationPageFrame(
        child: Column(
          children: [
            if (widget.inDialog)
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_outlined,
                    color: KaisaResidentDesign.forest,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Organizations / Profile')),
                  IconButton(
                    tooltip: 'Close organization profile',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    if (!widget.inDialog)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton.icon(
                          onPressed: () => context.canPop()
                              ? context.pop()
                              : context.go('/resident/organizations'),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back to Organizations'),
                        ),
                      ),
                    if (loading)
                      const Center(child: CircularProgressIndicator())
                    else if (error != null)
                      KaisaOrganizationEmpty(
                        title: 'Organization unavailable',
                        message: error!,
                        action: TextButton(
                          onPressed: _load,
                          child: const Text('Try again'),
                        ),
                      )
                    else if (current != null)
                      _profile(current),
                    const SizedBox(height: 70),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
