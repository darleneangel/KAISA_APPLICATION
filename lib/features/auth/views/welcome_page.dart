import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

/// KAISA welcome page - Flutter recreation of the Google Stitch Civic Dignity
/// light mobile onboarding and responsive desktop landing screen.
///
/// Uses source-linked Cavite City photos with optional local asset overrides.
/// Requires google_fonts and url_launcher; authentication routes are unchanged.
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
  static const cream = Color(0xFFF9F9FF);
  static const ink = Color(0xFF151C27);
  static const soft = Color(0xFF404942);
  static const line = Color(0xFFDCE3DE);
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
  final ScrollController _scroll = ScrollController();
  Timer? _photoTimer;
  int _current = 0;
  int _activePhoto = 0;

  // Keeping each asset and its fallback URL together prevents the two
  // sources from ever becoming misaligned. The active index is also
  // normalized before reading this list, including after hot reload.
  static const List<_WelcomePhoto> _photos = [
    _WelcomePhoto(
      'assets/images/cavite/regada_2025.jpg',
      'https://media.assettype.com/tribune%2F2025-07-20%2Fg6tgw5si%2FFirefighters-drenching-attendees-with-cool-water-Photo-by-Roel-Hoang-Manipon.jpg',
    ),
    _WelcomePhoto(
      'assets/images/cavite/unlad_pier.png',
      'https://thecaviterising.com/wp-content/uploads/2023/09/Photo-1-Article-180-091623-1024x576.png',
    ),
    _WelcomePhoto(
      'assets/images/cavite/regada_foam_2025.jpg',
      'https://media.assettype.com/tribune%2F2025-07-20%2Fq9frrgh4%2FRevelers-enjoying-a-foam-party-Photo-by-Roel-Hoang-Manipon.jpg',
    ),
  ];
  static const _photoCredits = [
    'Regada 2025 • Roel Hoang Manipon / Daily Tribune',
    'Unlad Pier, 2023 • The Cavite Rising',
    'Regada 2025 • Roel Hoang Manipon / Daily Tribune',
  ];
  static const _photoSources = [
    'https://tribune.net.ph/2025/07/20/cavite-city-strives-to-make-a-splash',
    'https://thecaviterising.com/cavite-city-pier-binuksan-na-sa-publiko/',
    'https://tribune.net.ph/2025/07/20/cavite-city-strives-to-make-a-splash',
  ];

  // The four features from the existing welcome_page.dart are preserved.
  static const List<_WelcomeFeature> _features = [
    _WelcomeFeature(
      title: 'Connect.\nServe.\nThrive.',
      eyebrow: 'LUNGSOD NG CAVITE  •  CIVIC ENGAGEMENT',
      statement: '“Isang Sambayanan, Isang Pagkilos.”',
      description:
          'Lungsod ng Cavite’s unified civic & bayanihan platform—connecting citizens, barangays, and local governance in one place.',
      icon: Icons.diversity_3_rounded,
    ),
    _WelcomeFeature(
      title: 'Find your\npeople.',
      eyebrow: 'ORGANIZATIONS',
      statement: 'One community. More connections.',
      description:
          'Explore local organizations and discover groups that match your interests and goals.',
      icon: Icons.groups_2_rounded,
    ),
    _WelcomeFeature(
      title: 'Join the\nmoment.',
      eyebrow: 'EVENTS & ACTIVITIES',
      statement: 'Be part of something big.',
      description:
          'Browse upcoming programs, workshops, volunteer opportunities, and community events.',
      icon: Icons.event_available_rounded,
    ),
    _WelcomeFeature(
      title: 'Stay\nconnected.',
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
    _scroll.dispose();
    super.dispose();
  }

  void _move(int next) {
    if (next < 0 || next >= _features.length || !_pages.hasClients) return;
    if (MediaQuery.of(context).disableAnimations) {
      _pages.jumpToPage(next);
      return;
    }
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
      backgroundColor: _WelcomePalette.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Theme(
        data: _civicTheme(sheetContext),
        child: ConstrainedBox(
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
                            color: _WelcomePalette.forest,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Pamahalaang Lungsod ng Cavite',
                    style: TextStyle(
                      color: _WelcomePalette.green,
                      fontSize: 12,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Explore documented city projects and community initiatives. These are historical highlights, not live KAISA registrations.',
                    style: TextStyle(color: _WelcomePalette.soft, height: 1.55),
                  ),
                  const SizedBox(height: 16),
                  for (final story in _stories.where(
                    (item) => item.milestone,
                  )) ...[
                    _storyCard(story, compact: true),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      style: FilledButton.styleFrom(
                        backgroundColor: _WelcomePalette.green,
                        foregroundColor: Colors.white,
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
      ),
    );
  }

  void _login() => context.go('/login');
  void _register() => context.go('/signup');

  void _discover(int index) {
    _move(index);
    if (_scroll.hasClients) {
      if (MediaQuery.of(context).disableAnimations) {
        _scroll.jumpTo(0);
      } else {
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  TextStyle _heading(double size, {Color color = _WelcomePalette.forest}) =>
      GoogleFonts.outfit(
        fontSize: size,
        height: 1.03,
        fontWeight: FontWeight.w800,
        letterSpacing: -size * .02,
        color: color,
      );

  Widget _brand({bool compact = false}) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: compact ? 44 : 42,
        height: compact ? 44 : 42,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: _WelcomePalette.green,
          borderRadius: BorderRadius.circular(compact ? 12 : 23),
        ),
        child: Image.asset(
          'assets/images/kaisa_logo.png',
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Icon(
            Icons.account_balance_outlined,
            color: _WelcomePalette.gold,
            size: 24,
          ),
        ),
      ),
      const SizedBox(width: 11),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'KAISA',
            style: _heading(
              compact ? 24 : 22,
            ).copyWith(letterSpacing: compact ? 3 : 1),
          ),
          const SizedBox(height: 3),
          const Text(
            'CAVITE CITY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.6,
              color: _WelcomePalette.soft,
            ),
          ),
        ],
      ),
    ],
  );

  Widget _header(bool desktop, double width) => Container(
    padding: EdgeInsets.symmetric(horizontal: desktop ? 32 : 24, vertical: 18),
    decoration: BoxDecoration(
      border: desktop
          ? const Border(bottom: BorderSide(color: _WelcomePalette.line))
          : null,
    ),
    child: Row(
      children: [
        _brand(compact: !desktop),
        const Spacer(),
        if (desktop && width >= 1050) ...[
          for (final item in [
            (0, 'Discover'),
            (1, 'Organizations'),
            (2, 'Civic Drives'),
            (3, 'About'),
          ])
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: TextButton(
                onPressed: () => _discover(item.$1),
                style: TextButton.styleFrom(
                  foregroundColor: _current == item.$1
                      ? _WelcomePalette.green
                      : _WelcomePalette.ink,
                ),
                child: Text(item.$2),
              ),
            ),
          const Spacer(),
        ],
        if (desktop) ...[
          TextButton(
            onPressed: _login,
            style: TextButton.styleFrom(
              foregroundColor: _WelcomePalette.forest,
            ),
            child: const Text('Sign In'),
          ),
          const SizedBox(width: 12),
          _primary('Register', _register, arrow: false, compact: true),
        ] else
          TextButton.icon(
            onPressed: _login,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.chevron_right, size: 20),
            label: const Text('Skip'),
            style: TextButton.styleFrom(foregroundColor: _WelcomePalette.soft),
          ),
      ],
    ),
  );

  Widget _primary(
    String label,
    VoidCallback action, {
    bool arrow = true,
    bool compact = false,
  }) => FilledButton(
    onPressed: action,
    style: FilledButton.styleFrom(
      backgroundColor: _WelcomePalette.green,
      foregroundColor: Colors.white,
      minimumSize: Size(0, compact ? 42 : 56),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 24 : 26,
        vertical: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 32 : 16),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: compact ? 14 : 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (arrow) ...[
          const SizedBox(width: 12),
          const Icon(Icons.arrow_forward_rounded, size: 22),
        ],
      ],
    ),
  );

  Widget _photo(int index) {
    final photo = _photos[index % _photos.length];
    return Image.asset(
      photo.asset,
      key: ValueKey(photo.asset),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) => Image.network(
        photo.url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => const ColoredBox(
          color: Color(0xFFDCE2F3),
          child: Center(
            child: Icon(
              Icons.groups_outlined,
              color: _WelcomePalette.green,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }

  Widget _photoFrame(
    int index, {
    bool caption = false,
    required _WelcomeFeature feature,
  }) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x2200301B),
          blurRadius: 28,
          offset: Offset(0, 16),
        ),
      ],
    ),
    padding: const EdgeInsets.all(4),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: Duration(
              milliseconds: MediaQuery.of(context).disableAnimations ? 0 : 700,
            ),
            layoutBuilder: (child, previous) => Stack(
              fit: StackFit.expand,
              children: [...previous, if (child != null) child],
            ),
            child: _photo(index),
          ),
          if (caption) ...[
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xE600301B)],
                  stops: [.35, 1],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _WelcomePalette.gold,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'BAYANIHAN IN ACTION',
                      style: TextStyle(
                        fontSize: 10,
                        color: _WelcomePalette.dark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    index % _photos.length == 1
                        ? 'Unlad Pier'
                        : 'Regada Water Festival',
                    style: _heading(20, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _photoCredits[index % _photoCredits.length],
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _impactButton(bool desktop) => Material(
    color: desktop ? Colors.white : _WelcomePalette.green,
    elevation: 5,
    shadowColor: const Color(0x3300301B),
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: _openAchievements,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: desktop
                    ? _WelcomePalette.green
                    : const Color(0xFF2D6039),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.emoji_events_outlined,
                color: _WelcomePalette.gold,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'LGU MILESTONES',
                  style: TextStyle(
                    color: desktop
                        ? _WelcomePalette.green
                        : _WelcomePalette.gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'View achievements',
                  style: TextStyle(
                    color: desktop ? _WelcomePalette.forest : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.north_east_rounded,
              size: 16,
              color: desktop ? _WelcomePalette.green : _WelcomePalette.gold,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _collage(_WelcomeFeature feature, bool desktop) => LayoutBuilder(
    builder: (context, c) {
      final w = c.maxWidth;
      final h = c.maxHeight;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: w * (desktop ? .16 : .025),
            top: h * .10,
            width: w * (desktop ? .80 : .61),
            height: h * .73,
            child: Transform.rotate(
              angle: desktop ? .045 : -.065,
              child: desktop
                  ? Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4E5C7),
                        border: Border.all(color: const Color(0xFFE8C77E)),
                        borderRadius: BorderRadius.circular(25),
                      ),
                    )
                  : _photoFrame(_activePhoto + 1, feature: feature),
            ),
          ),
          Positioned(
            left: w * (desktop ? .08 : .33),
            right: w * .045,
            top: h * .13,
            bottom: h * .15,
            child: Transform.rotate(
              angle: desktop ? 0 : .035,
              child: _photoFrame(
                _activePhoto,
                caption: desktop,
                feature: feature,
              ),
            ),
          ),
          Positioned(
            right: w * .055,
            top: h * .035,
            child: Container(
              width: desktop ? 56 : 52,
              height: desktop ? 56 : 52,
              decoration: BoxDecoration(
                color: _WelcomePalette.gold,
                border: Border.all(color: Colors.white, width: 4),
                borderRadius: BorderRadius.circular(desktop ? 32 : 16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_outlined,
                color: _WelcomePalette.forest,
                size: 27,
              ),
            ),
          ),
          Positioned(
            left: w * .03,
            bottom: h * .045,
            child: _impactButton(desktop),
          ),
        ],
      );
    },
  );

  Widget _copy(_WelcomeFeature feature, bool desktop, int index) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      if (desktop) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFE0E8E5),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            index == 0
                ? '●  CAVITE CITY’S DIGITAL CIVIC GATEWAY'
                : feature.eyebrow,
            style: const TextStyle(
              color: _WelcomePalette.forest,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: .5,
            ),
          ),
        ),
        const SizedBox(height: 22),
      ],
      if (index == 0)
        Text.rich(
          TextSpan(
            style: _heading(desktop ? 68 : 36),
            children: const [
              TextSpan(text: 'Connect.\nServe.\n'),
              TextSpan(
                text: 'Thrive',
                style: TextStyle(color: _WelcomePalette.green),
              ),
              TextSpan(
                text: '.',
                style: TextStyle(color: _WelcomePalette.gold),
              ),
            ],
          ),
        )
      else
        Text(feature.title, style: _heading(desktop ? 68 : 36)),
      const SizedBox(height: 16),
      Text(
        feature.description,
        style: TextStyle(
          color: _WelcomePalette.soft,
          fontSize: desktop ? 18 : 16,
          height: 1.55,
        ),
      ),
    ],
  );

  Widget _dots() => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(
      _features.length,
      (index) => Semantics(
        selected: index == _current,
        button: true,
        label: 'Welcome slide ${index + 1}',
        child: InkWell(
          onTap: () => _move(index),
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: index == _current ? 35 : 22,
            height: 32,
            child: Center(
              child: AnimatedContainer(
                duration: Duration(
                  milliseconds: MediaQuery.of(context).disableAnimations
                      ? 0
                      : 220,
                ),
                width: index == _current ? 26 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: index == _current
                      ? _WelcomePalette.green
                      : const Color(0xFFC5D5D0),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _controls() => Row(
    children: [
      _dots(),
      const Spacer(),
      IconButton(
        tooltip: 'Previous feature',
        onPressed: _current == 0 ? null : () => _move(_current - 1),
        icon: const Icon(Icons.chevron_left_rounded),
        color: _WelcomePalette.green,
      ),
      IconButton(
        tooltip: 'Next feature',
        onPressed: _current == _features.length - 1
            ? null
            : () => _move(_current + 1),
        icon: const Icon(Icons.chevron_right_rounded),
        color: _WelcomePalette.green,
      ),
    ],
  );

  Widget _actions(bool desktop) => desktop
      ? Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            _primary('Get Started', _login),
            OutlinedButton(
              onPressed: _login,
              style: OutlinedButton.styleFrom(
                foregroundColor: _WelcomePalette.forest,
                minimumSize: const Size(0, 56),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                side: const BorderSide(color: _WelcomePalette.line),
                backgroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              child: const Text('Sign In to KAISA'),
            ),
          ],
        )
      : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _primary('Get Started', _login),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _login,
              style: TextButton.styleFrom(
                foregroundColor: _WelcomePalette.green,
                minimumSize: const Size(0, 48),
              ),
              child: const Text(
                'I already have an account',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );

  Widget _slide(int index, bool desktop) {
    final feature = _features[index];
    if (desktop)
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 47,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _copy(feature, true, index),
                    const SizedBox(height: 24),
                    _actions(true),
                  ],
                ),
              ),
            ),
          ),
          Expanded(flex: 53, child: _collage(feature, true)),
        ],
      );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 46,
          child: SingleChildScrollView(child: _copy(feature, false, index)),
        ),
        const SizedBox(height: 10),
        Expanded(flex: 54, child: _collage(feature, false)),
      ],
    );
  }

  Widget _bulletin(double width) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'COMMUNITY BULLETIN',
        style: TextStyle(
          color: _WelcomePalette.green,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.3,
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          Text('Explore civic opportunities', style: _heading(30)),
          TextButton.icon(
            onPressed: () => _discover(2),
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward, size: 18),
            style: TextButton.styleFrom(foregroundColor: _WelcomePalette.green),
            label: const Text('Explore initiatives'),
          ),
        ],
      ),
      const SizedBox(height: 22),
      Wrap(
        spacing: 20,
        runSpacing: 20,
        children: List.generate(3, (i) {
          final feature = _features[i + 1];
          final cardWidth = width >= 800 ? (width - 40) / 3 : width;
          return SizedBox(
            width: cardWidth,
            child: Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: _WelcomePalette.line),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _discover(i + 1),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 72,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5EFE8),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          feature.icon,
                          color: _WelcomePalette.green,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 13),
                      Text(
                        feature.eyebrow,
                        style: const TextStyle(
                          color: _WelcomePalette.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(feature.statement, style: _heading(20)),
                      const SizedBox(height: 6),
                      Text(
                        feature.description,
                        style: const TextStyle(
                          color: _WelcomePalette.soft,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    ],
  );

  ThemeData _civicTheme(BuildContext context) {
    final base = Theme.of(context);
    final body = base.textTheme.apply(
      fontFamily: GoogleFonts.inter().fontFamily,
    );
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(primary: _WelcomePalette.green),
      textTheme: body.copyWith(
        displayLarge: GoogleFonts.outfit(
          textStyle: body.displayLarge,
          fontWeight: FontWeight.w800,
        ),
        headlineMedium: GoogleFonts.outfit(
          textStyle: body.headlineMedium,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: GoogleFonts.outfit(
          textStyle: body.titleLarge,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _openSource(String source) async {
    try {
      if (await launchUrl(Uri.parse(source), mode: LaunchMode.platformDefault))
        return;
    } catch (_) {
      /* Offer the address if the browser is unavailable. */
    }
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Source address'),
        content: SelectableText(source),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _storyImage(_CivicStory story) {
    Widget placeholder() => Container(
      color: const Color(0xFFE5EFE8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(story.icon, color: _WelcomePalette.green, size: 36),
            const SizedBox(height: 6),
            const Text(
              'Event photo unavailable',
              style: TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
    Widget online() => story.image.isEmpty
        ? placeholder()
        : Image.network(
            story.image,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (_, _, _) => placeholder(),
          );
    return Image.asset(
      'assets/images/cavite/${story.id}.jpg',
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => online(),
    );
  }

  Widget _storyCard(_CivicStory story, {bool compact = false}) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _WelcomePalette.line),
      borderRadius: BorderRadius.circular(20),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: compact ? 112 : 172, child: _storyImage(story)),
        Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${story.category.toUpperCase()}  •  ${story.date}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _WelcomePalette.green,
                ),
              ),
              const SizedBox(height: 8),
              Text(story.title, style: _heading(23)),
              const SizedBox(height: 8),
              Text(
                story.description,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.55,
                  color: _WelcomePalette.soft,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                story.publisher,
                style: const TextStyle(
                  fontSize: 11,
                  color: _WelcomePalette.soft,
                ),
              ),
              if (story.credit.isNotEmpty)
                Text(
                  story.credit,
                  style: const TextStyle(
                    fontSize: 10,
                    color: _WelcomePalette.soft,
                  ),
                ),
              TextButton.icon(
                onPressed: () => _openSource(story.source),
                icon: const Icon(Icons.open_in_new, size: 15),
                label: const Text('Read source'),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _communityContent() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'PAMAHALAANG LUNGSOD NG CAVITE',
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
          color: _WelcomePalette.green,
        ),
      ),
      const SizedBox(height: 8),
      Text('Our city, our community.', style: _heading(36)),
      const SizedBox(height: 12),
      const Text(
        'Explore public-service initiatives, cultural celebrations and civic projects from Cavite City, including activities involving Team Unlad Cavite City. This historical bulletin is sourced from public reports; KAISA is a separate community participation platform.',
        style: TextStyle(
          fontSize: 16,
          height: 1.55,
          color: _WelcomePalette.soft,
        ),
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: () => _openSource('https://cavitecity.gov.ph/'),
            icon: const Icon(Icons.account_balance_outlined),
            label: const Text('City government website'),
          ),
          OutlinedButton.icon(
            onPressed: () => _openSource(
              'https://cavitecity.gov.ph/index.php/residents/new-events',
            ),
            icon: const Icon(Icons.campaign_outlined),
            label: const Text('City news & events'),
          ),
        ],
      ),
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: _WelcomePalette.forest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '657 participants',
              style: _heading(38, color: _WelcomePalette.gold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Approximately 657 people joined the September 19, 2026 International Coastal Cleanup at Barangays 8 and 11, according to EMB CALABARZON. This is an event-specific figure, not a KAISA platform metric.',
              style: TextStyle(color: Colors.white, height: 1.55),
            ),
            TextButton(
              onPressed: () => _openSource(_stories[0].source),
              style: TextButton.styleFrom(
                foregroundColor: _WelcomePalette.gold,
              ),
              child: const Text('View official report'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 26),
      Text('Community stories & milestones', style: _heading(30)),
      const SizedBox(height: 8),
      const Text(
        'Past activities • Source-linked public information',
        style: TextStyle(color: _WelcomePalette.soft),
      ),
      const SizedBox(height: 18),
      LayoutBuilder(
        builder: (_, c) {
          final columns = c.maxWidth >= 900
              ? 3
              : c.maxWidth >= 560
              ? 2
              : 1;
          final width = (c.maxWidth - (columns - 1) * 16) / columns;
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final story in _stories)
                SizedBox(width: width, child: _storyCard(story)),
            ],
          );
        },
      ),
      const SizedBox(height: 38),
      Text('Community partners in action', style: _heading(30)),
      const SizedBox(height: 10),
      const Text(
        'The 2026 coastal cleanup report identifies local organizations and public agencies working together. These are reported event participants, not a list of KAISA-accredited organizations.',
        style: TextStyle(height: 1.55, color: _WelcomePalette.soft),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final name in const [
            'Cavite City CENRO',
            'Barangays 8 and 11',
            'Cavite City CDRMO',
            'Kabataang Kabitenyo',
            'Cavite City Leo-Lions Club',
            'Cavite City Club',
            'United OFW Organization',
            'Philippine Coast Guard',
          ])
            Chip(label: Text(name), backgroundColor: Colors.white),
        ],
      ),
      TextButton(
        onPressed: () => _openSource(_stories[0].source),
        child: const Text('See the published participant list'),
      ),
      const SizedBox(height: 32),
      Text('Public service resources', style: _heading(30)),
      const SizedBox(height: 12),
      for (final resource in const [
        (
          'Citizen’s Charter & departments',
          'https://cavitecity.gov.ph/index.php/service-2/citizen-s-charter-new-website',
        ),
        (
          'Health and welfare',
          'https://www.cavitecity.gov.ph/index.php/residents/services/health-welfare',
        ),
        (
          'LGU office directory',
          'https://www.cavitecity.gov.ph/index.php/about-lgu/directory/lgu-offices',
        ),
        (
          'Festivals and tourism',
          'https://cavitecity.gov.ph/index.php/visitors/tourist-information/festivals',
        ),
      ])
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.public, color: _WelcomePalette.green),
          title: Text(resource.$1),
          trailing: const Icon(Icons.open_in_new, size: 18),
          onTap: () => _openSource(resource.$2),
        ),
      const SizedBox(height: 38),
      Text('What is KAISA?', style: _heading(34)),
      const SizedBox(height: 12),
      const Text(
        'KAISA is a multi-platform community engagement and participation management system for Cavite City. It brings residents, organizations and local government together to discover activities, coordinate participation and share community updates.',
        style: TextStyle(
          fontSize: 16,
          height: 1.55,
          color: _WelcomePalette.soft,
        ),
      ),
      const SizedBox(height: 18),
      for (final item in const [
        (
          Icons.groups_outlined,
          'For residents',
          'Discover organizations, explore events, follow updates and manage participation. Identity verification unlocks eligible participation features.',
        ),
        (
          Icons.event_available_outlined,
          'For organizations',
          'Coordinate membership, publish activities, manage registrations and document participation.',
        ),
        (
          Icons.account_balance_outlined,
          'For local government',
          'Oversee authorized organization and event activity, operational reporting and administrative responsibilities.',
        ),
        (
          Icons.school_outlined,
          'Learn and volunteer',
          'Find seminars, livelihood activities, workshops, outreach programs and environmental initiatives.',
        ),
      ]) ...[
        _AchievementTopic(icon: item.$1, title: item.$2, subtitle: item.$3),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFE5EFE8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Be part of the community.', style: _heading(30)),
            const SizedBox(height: 12),
            const Text(
              'Create an account to discover opportunities and stay connected. Event registration and eligibility are determined within KAISA.',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                _primary('Create account', _register),
                OutlinedButton(onPressed: _login, child: const Text('Sign in')),
              ],
            ),
          ],
        ),
      ),
    ],
  );

  Widget _footer() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: _WelcomePalette.line)),
    ),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 18,
      runSpacing: 10,
      children: [
        _brand(),
        const Text(
          'Pamahalaang Lungsod ng Cavite',
          style: TextStyle(color: _WelcomePalette.soft, fontSize: 12),
        ),
        TextButton(
          onPressed: _openAchievements,
          style: TextButton.styleFrom(foregroundColor: _WelcomePalette.green),
          child: const Text('LGU Milestones & Achievements'),
        ),
        const Text(
          '© 2026 KAISA Civic Platform',
          style: TextStyle(color: _WelcomePalette.soft, fontSize: 12),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Theme(
    data: _civicTheme(context),
    child: Scaffold(
      backgroundColor: _WelcomePalette.cream,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final desktop = c.maxWidth >= 850;
            final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
            final heroHeight =
                (desktop
                    ? 510.0
                    : (c.maxHeight - 235).clamp(450.0, 850.0).toDouble()) *
                scale.clamp(1.0, 1.5).toDouble();
            return SingleChildScrollView(
              controller: _scroll,
              child: Column(
                children: [
                  _header(desktop, c.maxWidth),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1320),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          desktop ? 42 : 24,
                          desktop ? 32 : 8,
                          desktop ? 42 : 24,
                          desktop ? 64 : 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: heroHeight,
                              child: PageView.builder(
                                controller: _pages,
                                itemCount: _features.length,
                                onPageChanged: (index) =>
                                    setState(() => _current = index),
                                itemBuilder: (_, index) =>
                                    _slide(index, desktop),
                              ),
                            ),
                            _controls(),
                            if (!desktop) _actions(false),
                            const SizedBox(height: 18),
                            Text(
                              desktop
                                  ? _photoCredits[_activePhoto %
                                        _photoCredits.length]
                                  : '${_photoCredits[_activePhoto % _photoCredits.length]}\n${_photoCredits[(_activePhoto + 1) % _photoCredits.length]}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: _WelcomePalette.soft,
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              children: [
                                TextButton(
                                  onPressed: () => _openSource(
                                    _photoSources[_activePhoto %
                                        _photoSources.length],
                                  ),
                                  child: const Text('Photo source'),
                                ),
                                if (!desktop)
                                  TextButton(
                                    onPressed: () => _openSource(
                                      _photoSources[(_activePhoto + 1) %
                                          _photoSources.length],
                                    ),
                                    child: const Text('Second photo source'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            LayoutBuilder(
                              builder: (_, inner) => _bulletin(inner.maxWidth),
                            ),
                            const SizedBox(height: 44),
                            _communityContent(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _footer(),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
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
      color: Colors.white,
      border: Border.all(color: _WelcomePalette.line),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon, color: _WelcomePalette.green, size: 24),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _WelcomePalette.forest,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _WelcomePalette.soft,
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

class _CivicStory {
  const _CivicStory(
    this.id,
    this.title,
    this.category,
    this.date,
    this.description,
    this.publisher,
    this.source,
    this.icon, {
    this.image = '',
    this.credit = '',
    this.milestone = false,
  });
  final String id,
      title,
      category,
      date,
      description,
      publisher,
      source,
      image,
      credit;
  final IconData icon;
  final bool milestone;
}

const _stories = <_CivicStory>[
  _CivicStory(
    'cleanup_2026',
    'International Coastal Cleanup',
    'Environment',
    '19 SEP 2026',
    'Residents, civic groups and government agencies worked together on the shoreline of Barangays 8 and 11. The cleanup included local clubs, schools and public-service partners.',
    'EMB CALABARZON • Official report',
    'https://calabarzon.emb.gov.ph/emb-calabarzon-joins-simultaneous-cleanup-activity-for-international-coastal-cleanup-day-2026/',
    Icons.eco_outlined,
    milestone: true,
  ),
  _CivicStory(
    'youth_2026',
    'Linggo ng Kabataan',
    'Youth leadership',
    '10–15 AUG 2026',
    'Student leaders from local schools and universities learned about the work of the city government through a youth immersion program.',
    'Homes.ph • Community report',
    'https://homes.ph/restaurant/discover/linggo-ng-kabataan-2026-cavite-city-youth-step-into-public-service',
    Icons.school_outlined,
  ),
  _CivicStory(
    'regada_2025',
    'Regada Water Festival',
    'Culture & tourism',
    'JUN 2025',
    'The annual festival brought residents together through water festivities, arts, traditional games and cultural activities.',
    'Daily Tribune • 20 July 2025',
    'https://tribune.net.ph/2025/07/20/cavite-city-strives-to-make-a-splash',
    Icons.water_drop_outlined,
    image:
        'https://media.assettype.com/tribune%2F2025-07-20%2Fg6tgw5si%2FFirefighters-drenching-attendees-with-cool-water-Photo-by-Roel-Hoang-Manipon.jpg',
    credit: 'Photo: Roel Hoang Manipon / Daily Tribune',
  ),
  _CivicStory(
    'corregidor_2025',
    'Unlad Pier to Corregidor',
    'Tourism',
    'JUN 2025',
    'The City Tourism Office introduced a group-tour route to Corregidor Island from Unlad Pier, supporting access to the historic destination.',
    'The Cavite Rising • 7 June 2025',
    'https://thecaviterising.com/corregidor-tour-via-cavite-city-unlad-pier-sinimulan-na/',
    Icons.directions_boat_outlined,
    image:
        'https://thecaviterising.com/wp-content/uploads/2025/06/Photo-2-Article-143-060625.jpg',
    credit: 'Photo source: The Cavite Rising',
    milestone: true,
  ),
  _CivicStory(
    'carnival_2026',
    'Cavite City Fiesta Carnival',
    'Community celebration',
    '5 SEP 2026',
    'City officials and Team Unlad Cavite City members attended the opening of the carnival, featuring rides, games and family activities.',
    'Cavite Times Journal • 13 September 2026',
    'https://cavitetimesjournal.net/index.php/2026/09/13/cavite-city-fiesta-carnival-2026-officially-opens-with-mayor-denver-chua-leading-the-celebration/',
    Icons.celebration_outlined,
  ),
  _CivicStory(
    'sports_2026',
    'New sports center',
    'Sports & youth',
    'SEP 2026',
    'A new sports center was reported opened to support Cavite City athletes and local youth development, with Team Unlad mentioned in the report.',
    'Cavite News • 11 September 2026',
    'https://cavite.news/2026/09/11/new-sports-center-opens-for-caviteno-athletes-in-cavite-city/',
    Icons.sports_basketball_outlined,
    milestone: true,
  ),
  _CivicStory(
    'linis_2025',
    'Linis Dalampasigan',
    'Volunteerism',
    'JUN 2025',
    'The Regada festivities included a coastal cleanup in Barangay 30 (Bid-bid), bringing environmental action into the cultural program.',
    'Daily Tribune • 20 July 2025',
    'https://tribune.net.ph/2025/07/20/cavite-city-strives-to-make-a-splash',
    Icons.volunteer_activism_outlined,
  ),
  _CivicStory(
    'health',
    'City health and welfare services',
    'Public services',
    'SERVICE DIRECTORY',
    'The City Health Office provides preventive health services, maternal care and immunization programs. Consult the official directory for details and current service arrangements.',
    'City Government of Cavite • Official website',
    'https://www.cavitecity.gov.ph/index.php/residents/services/health-welfare',
    Icons.health_and_safety_outlined,
  ),
];
