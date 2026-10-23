import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/kaisa_brand.dart';
import '../../../core/theme/kaisa_backdrop.dart';

/// Compact introduction: four feature slides, one persistent CTA.
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});
  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final PageController _pages = PageController();
  int _current = 0;

  static const _slides = <_Feature>[
    _Feature(
      'One community.\nMore possibilities.',
      'Welcome to KAISA',
      'A shared digital space for Cavite City residents to connect, discover, and participate.',
      Icons.diversity_3_rounded,
      Color(0xFF0C6349),
      Color(0xFFFFD75A),
    ),
    _Feature(
      'Find your\npeople.',
      'Organizations',
      'Explore local organizations and discover groups that match your interests and goals.',
      Icons.groups_2_rounded,
      Color(0xFF126A51),
      Color(0xFFB7E497),
    ),
    _Feature(
      'Be part of\nsomething big.',
      'Events & activities',
      'Browse upcoming programs, workshops, volunteer opportunities, and community events.',
      Icons.event_available_rounded,
      Color(0xFF08745A),
      Color(0xFFFFD75A),
    ),
    _Feature(
      'Stay informed.\nStay involved.',
      'Community updates',
      'Follow announcements, learn about initiatives, and stay connected to what matters.',
      Icons.campaign_rounded,
      Color(0xFF135B49),
      Color(0xFFC8E9B3),
    ),
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _move(int next) {
    if (next < 0 || next >= _slides.length) return;
    _pages.animateToPage(
      next,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final desktop = size.width >= 850;
    final side = desktop ? 34.0 : 16.0;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F3),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            side,
            desktop ? 22 : 12,
            side,
            desktop ? 22 : 12,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const KaisaLogoTile(
                    asset: KaisaAssets.lguSeal,
                    size: 42,
                    fallbackIcon: Icons.account_balance_rounded,
                  ),
                  const SizedBox(width: 7),
                  const KaisaLogoTile(
                    asset: KaisaAssets.kaisaLogo,
                    size: 42,
                    fallbackIcon: Icons.diversity_3_rounded,
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KAISA',
                        style: TextStyle(
                          color: Color(0xFF153F30),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        'CAVITE CITY',
                        style: TextStyle(
                          color: Color(0xFF25804B),
                          fontSize: 10,
                          letterSpacing: 1.7,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text(
                      'Log In',
                      style: TextStyle(
                        color: AppColors.forest,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: desktop ? 24 : 12),
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1340),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(desktop ? 34 : 25),
                    child: PageView.builder(
                      controller: _pages,
                      itemCount: _slides.length,
                      onPageChanged: (index) =>
                          setState(() => _current = index),
                      itemBuilder: (context, index) => _FeatureSlide(
                        feature: _slides[index],
                        desktop: desktop,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Previous slide',
                    onPressed: _current == 0 ? null : () => _move(_current - 1),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 19,
                    ),
                  ),
                  ...List.generate(
                    _slides.length,
                    (index) => InkWell(
                      onTap: () => _move(index),
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _current == index ? 27 : 8,
                        decoration: BoxDecoration(
                          color: _current == index
                              ? AppColors.forest
                              : const Color(0xFFBDD6C5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next slide',
                    onPressed: _current == _slides.length - 1
                        ? null
                        : () => _move(_current + 1),
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 19),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: () => context.go('/login'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.forest,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text(
                      'Get Started',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Feature {
  final String title, eyebrow, description;
  final IconData icon;
  final Color background, accent;
  const _Feature(
    this.title,
    this.eyebrow,
    this.description,
    this.icon,
    this.background,
    this.accent,
  );
}

class _FeatureSlide extends StatelessWidget {
  final _Feature feature;
  final bool desktop;
  const _FeatureSlide({required this.feature, required this.desktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [feature.background, const Color(0xFF073C32)],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: KaisaBackdrop()),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final available = constraints.maxHeight;
                final small = available < 530;
                final content = Padding(
                  padding: EdgeInsets.all(desktop ? 50 : (small ? 20 : 26)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          feature.eyebrow.toUpperCase(),
                          style: TextStyle(
                            color: feature.accent,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 1.3,
                          ),
                        ),
                      ),
                      SizedBox(height: desktop ? 26 : 16),
                      Text(
                        feature.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: desktop ? 52 : (small ? 27 : 36),
                          height: 1.04,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        feature.description,
                        style: TextStyle(
                          color: const Color(0xFFE5F2E9),
                          fontSize: small ? 13 : 15,
                          height: 1.55,
                        ),
                      ),
                      if (desktop) ...[
                        const SizedBox(height: 32),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 9, color: feature.accent),
                            const SizedBox(width: 9),
                            const Text(
                              'CONNECT  •  PARTICIPATE  •  IMPACT',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
                final visual = _Illustration(
                  icon: feature.icon,
                  accent: feature.accent,
                  small: small,
                );
                if (desktop)
                  return Row(
                    children: [
                      Expanded(flex: 6, child: content),
                      Expanded(flex: 5, child: visual),
                    ],
                  );
                return Column(
                  children: [
                    Expanded(flex: small ? 3 : 5, child: visual),
                    Expanded(flex: small ? 5 : 6, child: content),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final bool small;
  const _Illustration({
    required this.icon,
    required this.accent,
    required this.small,
  });
  @override
  Widget build(BuildContext context) => Center(
    child: LayoutBuilder(
      builder: (context, size) {
        final diameter = (size.biggest.shortestSide * .72).clamp(
          100.0,
          small ? 180.0 : 330.0,
        );
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: diameter * 1.2,
              height: diameter * 1.2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: accent.withValues(alpha: .20),
                  width: 20,
                ),
              ),
            ),
            Transform.rotate(
              angle: -.12,
              child: Container(
                width: diameter,
                height: diameter,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(diameter * .26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .16),
                      blurRadius: 38,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: diameter * .5,
                  color: const Color(0xFF0B4939),
                ),
              ),
            ),
            Positioned(
              top: 3,
              right: 10,
              child: Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white.withValues(alpha: .85),
                size: small ? 22 : 35,
              ),
            ),
          ],
        );
      },
    ),
  );
}
