import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 950) {
            return const _DesktopWelcome();
          }

          return const _MobileWelcome();
        },
      ),
    );
  }
}

// ================================================================
// MOBILE
// ================================================================

class _MobileWelcome extends StatelessWidget {
  const _MobileWelcome();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: _MobileHero()),

            const SliverToBoxAdapter(child: _MobileCategories()),

            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 14),
                child: _SectionHeader(
                  title: 'Featured Opportunity',
                  subtitle: 'Discover something meaningful today',
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _FeaturedOpportunity(
                  opportunity: sampleOpportunities.first,
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 28, 20, 14),
                child: _SectionHeader(
                  title: 'Happening in the Community',
                  subtitle: 'Explore opportunities around Cavite City',
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _MobileOpportunityCard(
                      opportunity: sampleOpportunities[index + 1],
                    ),
                  );
                }, childCount: sampleOpportunities.length - 1),
              ),
            ),

            const SliverToBoxAdapter(child: _CommunityJourney()),

            const SliverToBoxAdapter(child: SizedBox(height: 150)),
          ],
        ),

        const _MobileBottomActions(),
      ],
    );
  }
}

class _MobileHero extends StatelessWidget {
  const _MobileHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.blueDark, AppColors.blue, AppColors.greenDark],
          stops: [0.0, 0.52, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -55,
            top: 40,
            child: _DecorativeCircle(
              size: 180,
              color: Colors.white,
              opacity: 0.06,
            ),
          ),
          Positioned(
            left: -45,
            bottom: -55,
            child: _DecorativeCircle(
              size: 150,
              color: AppColors.yellow,
              opacity: 0.12,
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _MobileBrand(),

                  const SizedBox(height: 38),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.yellow,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Text(
                      'COMMUNITY ENGAGEMENT PLATFORM',
                      style: TextStyle(
                        color: AppColors.blueDark,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .7,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Your community.\nYour opportunities.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      height: 1.08,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                    ),
                  ),

                  const SizedBox(height: 13),

                  const Text(
                    'Discover meaningful ways to volunteer, learn, '
                    'connect, and participate in Cavite City.',
                    style: TextStyle(
                      color: Color(0xFFE5EEFA),
                      fontSize: 14,
                      height: 1.55,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(17),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .10),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        SizedBox(width: 17),
                        Icon(Icons.search_rounded, color: AppColors.blue),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Search opportunities...',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: _FilterButton(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileBrand extends StatelessWidget {
  const _MobileBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Image.asset(
            'assets/images/kaisa_logo.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 13),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'KAISA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                ),
              ),
              SizedBox(height: 1),
              Text(
                'Connect • Participate • Impact',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MobileCategories extends StatelessWidget {
  const _MobileCategories();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 106,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        children: const [
          _CategoryButton(
            icon: Icons.volunteer_activism_rounded,
            label: 'Volunteer',
            color: AppColors.green,
            background: AppColors.greenLight,
          ),
          _CategoryButton(
            icon: Icons.celebration_rounded,
            label: 'Events',
            color: AppColors.blue,
            background: AppColors.blueLight,
          ),
          _CategoryButton(
            icon: Icons.school_rounded,
            label: 'Training',
            color: AppColors.blueDark,
            background: AppColors.blueLight,
          ),
          _CategoryButton(
            icon: Icons.groups_rounded,
            label: 'Community',
            color: AppColors.greenDark,
            background: AppColors.greenLight,
          ),
          _CategoryButton(
            icon: Icons.work_rounded,
            label: 'Career',
            color: AppColors.yellowDark,
            background: AppColors.yellowLight,
          ),
        ],
      ),
    );
  }
}

// ================================================================
// DESKTOP
// ================================================================

class _DesktopWelcome extends StatelessWidget {
  const _DesktopWelcome();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: _DesktopNavigation()),

        const SliverToBoxAdapter(child: _DesktopHero()),

        const SliverToBoxAdapter(child: _DesktopCategories()),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(56, 50, 56, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Happening in Cavite City',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -.5,
                      ),
                    ),
                    SizedBox(height: 7),
                    Text(
                      'Explore opportunities from community organizations.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {},
                  label: const Text('Explore all'),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                ),
              ],
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(56, 10, 56, 55),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate((context, index) {
              return _DesktopOpportunityCard(
                opportunity: sampleOpportunities[index],
              );
            }, childCount: sampleOpportunities.length),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 430,
              mainAxisExtent: 330,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: _DesktopCallToAction()),
      ],
    );
  }
}

class _DesktopNavigation extends StatelessWidget {
  const _DesktopNavigation();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 56),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.blueLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Image.asset(
              'assets/images/kaisa_logo.png',
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(width: 12),

          const Text(
            'KAISA',
            style: TextStyle(
              fontSize: 24,
              color: AppColors.blueDark,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),

          const Spacer(),

          const _DesktopNavItem('Explore'),
          const _DesktopNavItem('Organizations'),
          const _DesktopNavItem('About'),

          const SizedBox(width: 28),

          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Log In'),
          ),

          const SizedBox(width: 8),

          SizedBox(
            width: 150,
            child: ElevatedButton(
              onPressed: () => context.go('/signup'),
              child: const Text('Join KAISA'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopNavItem extends StatelessWidget {
  final String label;

  const _DesktopNavItem(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DesktopHero extends StatelessWidget {
  const _DesktopHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(32, 8, 32, 0),
      constraints: const BoxConstraints(minHeight: 510),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.blueDark, AppColors.blue, AppColors.greenDark],
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -100,
            top: -100,
            child: _DecorativeCircle(
              size: 360,
              color: Colors.white,
              opacity: .05,
            ),
          ),

          Positioned(
            right: 200,
            bottom: -130,
            child: _DecorativeCircle(
              size: 280,
              color: AppColors.yellow,
              opacity: .12,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(64),
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.yellow,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Text(
                          'COMMUNITY ENGAGEMENT PLATFORM',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.blueDark,
                            letterSpacing: .8,
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      const Text(
                        'Discover.\nParticipate.\nMake an impact.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 54,
                          height: 1.02,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.5,
                        ),
                      ),

                      const SizedBox(height: 22),

                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 550),
                        child: Text(
                          'KAISA connects Cavite City residents '
                          'with organizations and meaningful '
                          'community opportunities.',
                          style: TextStyle(
                            color: Color(0xFFE6EEF8),
                            fontSize: 17,
                            height: 1.6,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      Row(
                        children: [
                          SizedBox(
                            width: 205,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.yellow,
                                foregroundColor: AppColors.blueDark,
                              ),
                              onPressed: () => context.go('/signup'),
                              child: const Text('Join KAISA'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          SizedBox(
                            width: 205,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white54),
                              ),
                              onPressed: () {},
                              child: const Text('Explore Opportunities'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 60),

                Expanded(
                  flex: 5,
                  child: _HeroFeatureCard(
                    opportunity: sampleOpportunities.first,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroFeatureCard extends StatelessWidget {
  final OpportunityPreview opportunity;

  const _HeroFeatureCard({required this.opportunity});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: .025,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: .20)),
        ),
        child: Transform.rotate(
          angle: -.025,
          child: _FeaturedOpportunity(opportunity: opportunity, desktop: true),
        ),
      ),
    );
  }
}

class _DesktopCategories extends StatelessWidget {
  const _DesktopCategories();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(56, 50, 56, 0),
      child: Column(
        children: [
          const Text(
            'Find your way to participate',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Explore opportunities based on how you want to get involved.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 26),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            alignment: WrapAlignment.center,
            children: const [
              _DesktopCategory(
                icon: Icons.volunteer_activism_rounded,
                title: 'Volunteer',
                color: AppColors.green,
              ),
              _DesktopCategory(
                icon: Icons.celebration_rounded,
                title: 'Events',
                color: AppColors.blue,
              ),
              _DesktopCategory(
                icon: Icons.school_rounded,
                title: 'Training',
                color: AppColors.blueDark,
              ),
              _DesktopCategory(
                icon: Icons.groups_rounded,
                title: 'Community',
                color: AppColors.greenDark,
              ),
              _DesktopCategory(
                icon: Icons.work_rounded,
                title: 'Career',
                color: AppColors.yellowDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ================================================================
// OPPORTUNITY COMPONENTS
// ================================================================

class _FeaturedOpportunity extends StatelessWidget {
  final OpportunityPreview opportunity;
  final bool desktop;

  const _FeaturedOpportunity({required this.opportunity, this.desktop = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: desktop ? 180 : 150,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  opportunity.color,
                  opportunity.color.withValues(alpha: .70),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -25,
                  bottom: -35,
                  child: Icon(
                    opportunity.icon,
                    size: 155,
                    color: Colors.white.withValues(alpha: .13),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CategoryPill(text: opportunity.category),
                      const Spacer(),
                      Text(
                        opportunity.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: desktop ? 22 : 19,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _VerifiedOrganization(name: opportunity.organization),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _InfoLine(
                        icon: Icons.calendar_today_rounded,
                        text: opportunity.date,
                      ),
                    ),
                    Expanded(
                      child: _InfoLine(
                        icon: Icons.location_on_outlined,
                        text: opportunity.location,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 17,
                      color: opportunity.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${opportunity.spotsLeft} spots available',
                      style: TextStyle(
                        color: opportunity.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'View details',
                      style: TextStyle(
                        color: AppColors.blue,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 15,
                      color: AppColors.blue,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileOpportunityCard extends StatelessWidget {
  final OpportunityPreview opportunity;

  const _MobileOpportunityCard({required this.opportunity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 76,
            height: 90,
            decoration: BoxDecoration(
              color: opportunity.color.withValues(alpha: .11),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(opportunity.icon, color: opportunity.color, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opportunity.category,
                  style: TextStyle(
                    color: opportunity.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .4,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  opportunity.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  opportunity.organization,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      opportunity.date,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 15,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

class _DesktopOpportunityCard extends StatelessWidget {
  final OpportunityPreview opportunity;

  const _DesktopOpportunityCard({required this.opportunity});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            width: double.infinity,
            color: opportunity.color.withValues(alpha: .10),
            child: Stack(
              children: [
                Positioned(
                  right: 20,
                  bottom: 12,
                  child: Icon(
                    opportunity.icon,
                    size: 75,
                    color: opportunity.color.withValues(alpha: .22),
                  ),
                ),
                Positioned(
                  left: 18,
                  top: 18,
                  child: _ColoredCategoryPill(
                    text: opportunity.category,
                    color: opportunity.color,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opportunity.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 9),
                  _VerifiedOrganization(name: opportunity.organization),
                  const Spacer(),
                  _InfoLine(
                    icon: Icons.calendar_today_outlined,
                    text: opportunity.date,
                  ),
                  const SizedBox(height: 7),
                  _InfoLine(
                    icon: Icons.location_on_outlined,
                    text: opportunity.location,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Text(
                        '${opportunity.spotsLeft} spots available',
                        style: TextStyle(
                          color: opportunity.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: AppColors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// COMMUNITY JOURNEY
// ================================================================

class _CommunityJourney extends StatelessWidget {
  const _CommunityJourney();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.blueDark,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your KAISA Journey',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'From discovery to community impact.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _JourneyItem(
                icon: Icons.explore_rounded,
                label: 'Discover',
                color: AppColors.yellow,
              ),
              _JourneyArrow(),
              _JourneyItem(
                icon: Icons.app_registration_rounded,
                label: 'Register',
                color: Colors.white,
              ),
              _JourneyArrow(),
              _JourneyItem(
                icon: Icons.volunteer_activism_rounded,
                label: 'Participate',
                color: AppColors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ================================================================
// BOTTOM CTA
// ================================================================

class _MobileBottomActions extends StatelessWidget {
  const _MobileBottomActions();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .10),
              blurRadius: 25,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Log In'),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.go('/signup'),
                  child: const Text('Join KAISA'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopCallToAction extends StatelessWidget {
  const _DesktopCallToAction();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      padding: const EdgeInsets.symmetric(horizontal: 55, vertical: 48),
      decoration: BoxDecoration(
        color: AppColors.blueDark,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ready to make an impact?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Create your KAISA account and start '
                  'discovering ways to participate.',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 160,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
              ),
              onPressed: () => context.go('/login'),
              child: const Text('Log In'),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 180,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.yellow,
                foregroundColor: AppColors.blueDark,
              ),
              onPressed: () => context.go('/signup'),
              child: const Text('Create Account'),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// SMALL COMPONENTS
// ================================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _CategoryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  const _CategoryButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      margin: const EdgeInsets.only(right: 10),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(icon, color: color, size: 25),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopCategory extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _DesktopCategory({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 175,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 11),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifiedOrganization extends StatelessWidget {
  final String name;

  const _VerifiedOrganization({required this.name});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.verified_rounded, color: AppColors.blue, size: 16),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.circle, size: 0),
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String text;

  const _CategoryPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.blueDark,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: .5,
        ),
      ),
    );
  }
}

class _ColoredCategoryPill extends StatelessWidget {
  final String text;
  final Color color;

  const _ColoredCategoryPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 39,
      height: 39,
      decoration: BoxDecoration(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.tune_rounded, color: AppColors.blue, size: 20),
    );
  }
}

class _JourneyItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _JourneyItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 25),
        const SizedBox(height: 7),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _JourneyArrow extends StatelessWidget {
  const _JourneyArrow();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.arrow_forward_rounded,
      color: Colors.white38,
      size: 17,
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _DecorativeCircle({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
      ),
    );
  }
}

// ================================================================
// TEMPORARY PROTOTYPE MODEL
//
// Later:
// sampleOpportunities
//          ↓
// Supabase
//          ↓
// Repository
//          ↓
// Riverpod provider
//          ↓
// UI
// ================================================================

class OpportunityPreview {
  final String category;
  final String organization;
  final String title;
  final String description;
  final String date;
  final String location;
  final int spotsLeft;
  final Color color;
  final IconData icon;

  const OpportunityPreview({
    required this.category,
    required this.organization,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.spotsLeft,
    required this.color,
    required this.icon,
  });
}

const List<OpportunityPreview> sampleOpportunities = [
  OpportunityPreview(
    category: 'VOLUNTEER',
    organization: 'Cavite Youth Council',
    title: 'Coastal Cleanup & Mangrove Planting',
    description:
        'Join community volunteers for a coastal cleanup '
        'and environmental awareness activity.',
    date: 'Oct 12',
    location: 'San Roque',
    spotsLeft: 24,
    color: AppColors.green,
    icon: Icons.eco_rounded,
  ),
  OpportunityPreview(
    category: 'SEMINAR',
    organization: 'LYDO Cavite City',
    title: 'Digital Skills & Financial Literacy',
    description:
        'Learn practical digital and financial skills '
        'through a community learning session.',
    date: 'Oct 18',
    location: 'City Hall',
    spotsLeft: 12,
    color: AppColors.blue,
    icon: Icons.computer_rounded,
  ),
  OpportunityPreview(
    category: 'TRAINING',
    organization: 'Community Learning Hub',
    title: 'Youth Leadership Training Program',
    description:
        'Develop communication, leadership, and '
        'community-building skills.',
    date: 'Oct 22',
    location: 'Caridad',
    spotsLeft: 18,
    color: AppColors.blueDark,
    icon: Icons.school_rounded,
  ),
  OpportunityPreview(
    category: 'COMMUNITY',
    organization: 'Local Community Organization',
    title: 'Community Health & Wellness Day',
    description:
        'Participate in community wellness activities '
        'and information sessions.',
    date: 'Oct 26',
    location: 'Cavite City',
    spotsLeft: 30,
    color: AppColors.greenDark,
    icon: Icons.favorite_rounded,
  ),
  OpportunityPreview(
    category: 'CAREER',
    organization: 'Local Livelihood Hub',
    title: 'Career Readiness & Employment Workshop',
    description:
        'Build your résumé and prepare for local '
        'employment opportunities.',
    date: 'Nov 02',
    location: 'Cavite City',
    spotsLeft: 15,
    color: AppColors.yellowDark,
    icon: Icons.work_rounded,
  ),
];
