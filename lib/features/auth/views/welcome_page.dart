import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// KAISA welcome page - Flutter recreation of the Google Stitch Civic Dignity
/// landing screen. The original four onboarding pages and route actions remain.
///
/// Uses the same five optional background images as the compact KAISA login.
/// No new Flutter packages or changes to Supabase authentication are required.
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePalette {
  const _WelcomePalette._();

  static const dark = Color(0xFF001C12);
  static const forest = Color(0xFF00301B);
  static const green = Color(0xFF00492C);
  static const gold = Color(0xFFFDBC19);
  static const cream = Color(0xFFF8FAF5);
  static const muted = Color(0xFFC9D8D0);
}

class _WelcomeFeature {
  const _WelcomeFeature({
    required this.title,
    required this.eyebrow,
    required this.statement,
    required this.description,
    required this.icon,
  });

  final String title;
  final String eyebrow;
  final String statement;
  final String description;
  final IconData icon;
}

/// One photo and its network fallback, so both always share an index.
class _WelcomePhoto {
  const _WelcomePhoto(this.asset, this.url);

  final String asset;
  final String url;
}

class _WelcomePageState extends State<WelcomePage> {
  final PageController _pages = PageController();
  Timer? _photoTimer;
  int _current = 0;
  int _activePhoto = 0;

  // Keeping each asset and its fallback URL together prevents the two
  // sources from ever becoming misaligned. The active index is also
  // normalized before reading this list, including after hot reload.
  static const List<_WelcomePhoto> _photos = [
    _WelcomePhoto(
      'assets/images/kaisa_bg_01.jpg',
      'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?auto=format&fit=crop&w=1600&q=82',
    ),
    _WelcomePhoto(
      'assets/images/kaisa_bg_02.jpg',
      'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=1600&q=82',
    ),
    _WelcomePhoto(
      'assets/images/kaisa_bg_03.jpg',
      'https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?auto=format&fit=crop&w=1600&q=82',
    ),
    _WelcomePhoto(
      'assets/images/kaisa_bg_04.jpg',
      'https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?auto=format&fit=crop&w=1600&q=82',
    ),
    _WelcomePhoto(
      'assets/images/kaisa_bg_05.jpg',
      'https://images.unsplash.com/photo-1556761175-b413da4baf72?auto=format&fit=crop&w=1600&q=82',
    ),
  ];

  // The four features from the existing welcome_page.dart are preserved.
  static const List<_WelcomeFeature> _features = [
    _WelcomeFeature(
      title: 'KAISA',
      eyebrow: 'LUNGSOD NG CAVITE  •  CIVIC ENGAGEMENT',
      statement: '“Isang Sambayanan, Isang Pagkilos.”',
      description:
          'Connecting residents, community organizations, and city governance in one unified platform.',
      icon: Icons.diversity_3_rounded,
    ),
    _WelcomeFeature(
      title: 'FIND YOUR PEOPLE',
      eyebrow: 'ORGANIZATIONS',
      statement: 'One community. More connections.',
      description:
          'Explore local organizations and discover groups that match your interests and goals.',
      icon: Icons.groups_2_rounded,
    ),
    _WelcomeFeature(
      title: 'JOIN THE MOMENT',
      eyebrow: 'EVENTS & ACTIVITIES',
      statement: 'Be part of something big.',
      description:
          'Browse upcoming programs, workshops, volunteer opportunities, and community events.',
      icon: Icons.event_available_rounded,
    ),
    _WelcomeFeature(
      title: 'STAY CONNECTED',
      eyebrow: 'COMMUNITY UPDATES',
      statement: 'Stay informed. Stay involved.',
      description:
          'Follow announcements, learn about local initiatives, and stay connected to what matters.',
      icon: Icons.campaign_rounded,
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations) {
      _photoTimer?.cancel();
      _photoTimer = null;
    } else {
      _photoTimer ??= Timer.periodic(const Duration(seconds: 7), (_) {
        if (!mounted || _photos.isEmpty) return;
        setState(() {
          _activePhoto = (_activePhoto + 1) % _photos.length;
        });
      });
    }
  }

  @override
  void dispose() {
    _photoTimer?.cancel();
    _pages.dispose();
    super.dispose();
  }

  void _move(int next) {
    if (next < 0 || next >= _features.length || !_pages.hasClients) return;
    _pages.animateToPage(
      next,
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeInOutCubic,
    );
  }

  void _openAchievements() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFF002719),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.workspace_premium_outlined,
                      color: _WelcomePalette.gold,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'LGU Milestones & Achievements',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Pamahalaang Lungsod ng Cavite',
                  style: TextStyle(
                    color: _WelcomePalette.gold,
                    fontSize: 12,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'This section is prepared for official city milestones, '
                  'community programs, and verified public-service achievements. '
                  'Confirmed information will be displayed here when available.',
                  style: TextStyle(color: _WelcomePalette.muted, height: 1.55),
                ),
                const SizedBox(height: 20),
                const _AchievementTopic(
                  icon: Icons.volunteer_activism_outlined,
                  title: 'Community initiatives',
                  subtitle:
                      'Updates from local programs and volunteer projects',
                ),
                const SizedBox(height: 10),
                const _AchievementTopic(
                  icon: Icons.groups_outlined,
                  title: 'Resident participation',
                  subtitle: 'Published participation highlights and outcomes',
                ),
                const SizedBox(height: 10),
                const _AchievementTopic(
                  icon: Icons.account_balance_outlined,
                  title: 'Public-service milestones',
                  subtitle: 'Verified achievements from the city government',
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: FilledButton.styleFrom(
                      backgroundColor: _WelcomePalette.gold,
                      foregroundColor: _WelcomePalette.dark,
                      minimumSize: const Size(0, 48),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _background(bool reduceMotion) {
    // A previous hot-reload can retain an index from an older slideshow.
    // Never index a list until checking it and normalizing the index.
    if (_photos.isEmpty) {
      return const Positioned.fill(
        child: ColoredBox(color: _WelcomePalette.forest),
      );
    }
    final index = _activePhoto % _photos.length;
    final photo = _photos[index];
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: _WelcomePalette.forest),
            AnimatedSwitcher(
              duration: Duration(milliseconds: reduceMotion ? 0 : 1150),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              layoutBuilder: (currentChild, previousChildren) => Stack(
                fit: StackFit.expand,
                children: <Widget>[...previousChildren, ?currentChild],
              ),
              child: Image.asset(
                photo.asset,
                key: ValueKey<String>(photo.asset),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) => Image.network(
                  photo.url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) =>
                      const ColoredBox(color: _WelcomePalette.forest),
                ),
              ),
            ),
            // The two layers create Stitch's subdued photographic duotone.
            Container(color: _WelcomePalette.forest.withValues(alpha: .72)),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xE6002115),
                    Color(0x4D0B4C36),
                    Color(0xDD001D12),
                    Color(0xF5001A10),
                  ],
                  stops: [0.0, .35, .75, 1.0],
                ),
              ),
            ),
            Positioned(
              right: -125,
              top: -150,
              child: Container(
                width: 390,
                height: 390,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _WelcomePalette.gold.withValues(alpha: .20),
                      _WelcomePalette.gold.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(bool compact) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: compact ? 9 : 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .13),
            border: Border.all(color: Colors.white.withValues(alpha: .18)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 4.5,
                backgroundColor: _WelcomePalette.gold,
              ),
              SizedBox(width: compact ? 6 : 9),
              Text(
                'KAISA PORTAL',
                style: TextStyle(
                  fontSize: compact ? 10 : 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: compact ? .5 : 1,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 11 : 15,
            vertical: compact ? 9 : 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .10),
            border: Border.all(color: Colors.white.withValues(alpha: .14)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.verified_outlined,
                color: _WelcomePalette.gold,
                size: 16,
              ),
              const SizedBox(width: 5),
              Text(
                '2026',
                style: TextStyle(
                  color: _WelcomePalette.cream,
                  fontSize: compact ? 11 : 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Four circular progress dots: tap a dot to jump to its welcome slide.
  Widget _topDots(bool compact) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(_features.length, (index) {
      final selected = _current == index;
      return Tooltip(
        message: 'Welcome slide ${index + 1}: ${_features[index].eyebrow}',
        child: InkWell(
          onTap: () => _move(index),
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: compact ? 22 : 26,
            height: 28,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                width: selected ? 10 : 7,
                height: selected ? 10 : 7,
                decoration: BoxDecoration(
                  color: selected ? _WelcomePalette.gold : Colors.white54,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      );
    }),
  );

  Widget _featurePage(_WelcomeFeature feature, bool desktop, bool shortHeight) {
    final titleSize = feature.title == 'KAISA'
        ? (desktop ? 49.0 : (shortHeight ? 32.0 : 38.0))
        : (desktop ? 34.0 : (shortHeight ? 25.0 : 28.0));

    return Center(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: desktop ? 16 : 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/images/kaisa_logo.png',
                  width: shortHeight ? 50 : (desktop ? 72 : 64),
                  height: shortHeight ? 50 : (desktop ? 72 : 64),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    feature.icon,
                    color: _WelcomePalette.gold,
                    size: shortHeight ? 42 : 56,
                  ),
                ),
              ),
              SizedBox(height: shortHeight ? 8 : (desktop ? 14 : 11)),
              Text(
                feature.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: feature.title == 'KAISA' ? 6 : 1,
                  height: 1.1,
                  shadows: const [
                    Shadow(color: Color(0x66000000), blurRadius: 12),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                feature.eyebrow,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _WelcomePalette.gold,
                  fontSize: desktop ? 11 : 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: desktop ? 1.8 : 1.2,
                  height: 1.55,
                ),
              ),
              SizedBox(height: shortHeight ? 8 : 11),
              SizedBox(
                width: 132,
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.white.withValues(alpha: .25),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(
                        Icons.spa_outlined,
                        color: _WelcomePalette.gold,
                        size: 16,
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.white.withValues(alpha: .25),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: shortHeight ? 8 : 11),
              Text(
                feature.statement,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: desktop ? 18 : (shortHeight ? 15 : 17),
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Text(
                  feature.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _WelcomePalette.muted,
                    fontSize: desktop ? 14 : 12,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButtons(bool desktop) => ConstrainedBox(
    constraints: BoxConstraints(maxWidth: desktop ? 340 : 320),
    child: Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 46,
          child: FilledButton(
            // Matches the current welcome flow: onboarding -> login.
            onPressed: () => context.go('/login'),
            style: FilledButton.styleFrom(
              backgroundColor: _WelcomePalette.gold,
              foregroundColor: _WelcomePalette.dark,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Get Started',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
                SizedBox(width: 9),
                Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 9),
        TextButton.icon(
          onPressed: _openAchievements,
          style: TextButton.styleFrom(
            foregroundColor: _WelcomePalette.gold,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          ),
          icon: const Icon(Icons.emoji_events_outlined, size: 18),
          label: const Text(
            'View LGU Achievements',
            style: TextStyle(
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w700,
              decorationColor: _WelcomePalette.gold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _slideArrows() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      IconButton(
        tooltip: 'Previous feature',
        onPressed: _current == 0 ? null : () => _move(_current - 1),
        color: Colors.white,
        disabledColor: Colors.white30,
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.chevron_left_rounded, size: 23),
      ),
      _topDots(false),
      IconButton(
        tooltip: 'Next feature',
        onPressed: _current == _features.length - 1
            ? null
            : () => _move(_current + 1),
        color: Colors.white,
        disabledColor: Colors.white30,
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.chevron_right_rounded, size: 23),
      ),
    ],
  );

  Widget _footer() => const Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 7,
        children: [
          Icon(
            Icons.account_balance_outlined,
            color: _WelcomePalette.gold,
            size: 16,
          ),
          Text(
            'REPUBLIC OF THE PHILIPPINES  •  CITY GOVERNMENT OF CAVITE',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _WelcomePalette.muted,
              fontSize: 9,
              letterSpacing: 1.2,
              height: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      SizedBox(height: 7),
      Text(
        'Ligtas  •  Makabayan  •  Malasakit sa Bayan',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white54,
          fontSize: 10,
          letterSpacing: .4,
        ),
      ),
    ],
  );

  // Keep the PageView and its navigation behavior identical in both layouts.
  Widget _welcomeSlides(bool desktop, bool shortHeight) => PageView.builder(
    controller: _pages,
    itemCount: _features.length,
    onPageChanged: (index) => setState(() => _current = index),
    itemBuilder: (context, index) =>
        _featurePage(_features[index], desktop, shortHeight),
  );

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Scaffold(
      backgroundColor: _WelcomePalette.forest,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final desktop = width >= 760;
          final compact = width < 420;
          final shortHeight = height < 660;
          final veryShort = height < 590;
          final paddingX = desktop ? 28.0 : (compact ? 16.0 : 22.0);

          // A full-height Column anchors the CTA and achievements link near
          // the bottom edge on typical web and mobile viewports. For very
          // short browser windows, keep everything accessible by scrolling.
          final mainContent = veryShort
              ? SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _topBar(compact),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: desktop ? 275 : 320,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 760),
                            child: _welcomeSlides(desktop, shortHeight),
                          ),
                        ),
                      ),
                      _slideArrows(),
                      const SizedBox(height: 12),
                      _actionButtons(desktop),
                      const SizedBox(height: 13),
                      _footer(),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Top badges now align near the left/right screen edges.
                    _topBar(compact),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: 760,
                            maxHeight: desktop ? 450 : 395,
                          ),
                          child: _welcomeSlides(desktop, shortHeight),
                        ),
                      ),
                    ),
                    _slideArrows(),
                    SizedBox(height: desktop ? 16 : 10),
                    _actionButtons(desktop),
                    SizedBox(height: desktop ? 13 : 9),
                    _footer(),
                  ],
                );

          return Stack(
            children: [
              _background(reduceMotion),
              Positioned.fill(
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      paddingX,
                      desktop ? 14 : 10,
                      paddingX,
                      desktop ? 10 : 8,
                    ),
                    child: mainContent,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AchievementTopic extends StatelessWidget {
  const _AchievementTopic({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .07),
      border: Border.all(color: _WelcomePalette.gold.withValues(alpha: .18)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon, color: _WelcomePalette.gold, size: 24),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _WelcomePalette.muted,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
