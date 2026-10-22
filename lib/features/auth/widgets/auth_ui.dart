import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/kaisa_backdrop.dart';

class AuthResponsivePage extends StatelessWidget {
  final Widget hero;
  final Widget panel;
  final bool showBack;
  final String? backRoute;

  const AuthResponsivePage({
    super.key,
    required this.hero,
    required this.panel,
    this.showBack = false,
    this.backRoute,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1000;
        final isTablet = constraints.maxWidth >= 700;

        return Scaffold(
          body: Stack(
            children: [
              const Positioned.fill(child: KaisaBackdrop()),
              SafeArea(
                child: isDesktop
                    ? _DesktopAuthLayout(
                        hero: hero,
                        panel: panel,
                        showBack: showBack,
                        backRoute: backRoute,
                      )
                    : _MobileAuthLayout(
                        hero: hero,
                        panel: panel,
                        showBack: showBack,
                        backRoute: backRoute,
                        isTablet: isTablet,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DesktopAuthLayout extends StatelessWidget {
  final Widget hero;
  final Widget panel;
  final bool showBack;
  final String? backRoute;

  const _DesktopAuthLayout({
    required this.hero,
    required this.panel,
    required this.showBack,
    required this.backRoute,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  flex: 11,
                  child: Container(
                    margin: const EdgeInsets.only(right: 18),
                    padding: const EdgeInsets.fromLTRB(38, 34, 38, 34),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF0A3E32),
                          Color(0xFF0F5C46),
                          Color(0xFF146B4C),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .10),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .18),
                          blurRadius: 34,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: hero,
                  ),
                ),
                Expanded(
                  flex: 8,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 720),
                    padding: const EdgeInsets.fromLTRB(30, 26, 30, 30),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FBF7),
                      borderRadius: BorderRadius.circular(34),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .72),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .10),
                          blurRadius: 30,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (showBack)
                                _BackButton(
                                  onTap: () {
                                    if (backRoute != null) {
                                      context.go(backRoute!);
                                    } else {
                                      context.pop();
                                    }
                                  },
                                ),
                              if (showBack) const SizedBox(width: 16),
                              const Expanded(
                                child: AuthBrandHeader(darkText: true),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          AuthFormSurface(child: panel),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileAuthLayout extends StatelessWidget {
  final Widget hero;
  final Widget panel;
  final bool showBack;
  final String? backRoute;
  final bool isTablet;

  const _MobileAuthLayout({
    required this.hero,
    required this.panel,
    required this.showBack,
    required this.backRoute,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isTablet ? 28 : 18,
        18,
        isTablet ? 28 : 18,
        26,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isTablet ? 720 : 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showBack)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _BackButton(
                    onTap: () {
                      if (backRoute != null) {
                        context.go(backRoute!);
                      } else {
                        context.pop();
                      }
                    },
                  ),
                ),
              Container(
                padding: EdgeInsets.fromLTRB(
                  isTablet ? 28 : 20,
                  isTablet ? 28 : 22,
                  isTablet ? 28 : 20,
                  isTablet ? 28 : 22,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0A3E32),
                      Color(0xFF0E5A44),
                      Color(0xFF17694C),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .10),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AuthBrandHeader(),
                    const SizedBox(height: 24),
                    hero,
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: EdgeInsets.fromLTRB(
                  isTablet ? 26 : 20,
                  isTablet ? 24 : 20,
                  isTablet ? 26 : 20,
                  isTablet ? 28 : 22,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FBF7),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .75),
                    width: 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .12),
                      blurRadius: 24,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: AuthFormSurface(child: panel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthBrandHeader extends StatelessWidget {
  final bool darkText;

  const AuthBrandHeader({super.key, this.darkText = false});

  @override
  Widget build(BuildContext context) {
    final titleColor = darkText ? const Color(0xFF14352C) : Colors.white;
    final subtitleColor = darkText ? AppColors.forest : AppColors.yellow;

    return Row(
      children: [
        _LogoPill(
          asset: 'assets/images/LGU.png',
          fallbackIcon: Icons.account_balance_rounded,
        ),
        const SizedBox(width: 10),
        _LogoPill(
          asset: 'assets/images/kaisa_logo.png',
          fallbackIcon: Icons.diversity_3_rounded,
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KAISA',
              style: TextStyle(
                color: titleColor,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'CAVITE CITY',
              style: TextStyle(
                color: subtitleColor,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LogoPill extends StatelessWidget {
  final String asset;
  final IconData fallbackIcon;

  const _LogoPill({required this.asset, required this.fallbackIcon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .10),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              Icon(fallbackIcon, color: AppColors.forest, size: 24),
        ),
      ),
    );
  }
}

class AuthTag extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;

  const AuthTag({
    super.key,
    required this.label,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = color ?? Colors.white.withValues(alpha: .12);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class AuthInfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool light;

  const AuthInfoCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    final background = light
        ? Colors.white
        : Colors.white.withValues(alpha: .08);
    final titleColor = light ? const Color(0xFF14352C) : Colors.white;
    final subtitleColor = light
        ? const Color(0xFF5B6C64)
        : Colors.white.withValues(alpha: .78);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: light
              ? const Color(0xFFE4ECE8)
              : Colors.white.withValues(alpha: .08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: light
                  ? AppColors.forest.withValues(alpha: .10)
                  : Colors.white.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: light ? AppColors.forest : AppColors.yellow,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: subtitleColor, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class AuthGhostButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const AuthGhostButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.forest,
        side: const BorderSide(color: Color(0xFFD7E4DE)),
        backgroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: .10)),
          ),
          child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
      ),
    );
  }
}

/// Keep cream auth forms readable even if the application's global theme is dark.
class AuthFormSurface extends StatelessWidget {
  final Widget child;
  const AuthFormSurface({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Montserrat',
    );
    return Theme(
      data: base.copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.forest,
          brightness: Brightness.light,
        ),
        textTheme: base.textTheme.apply(
          bodyColor: const Color(0xFF183B2D),
          displayColor: const Color(0xFF183B2D),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
          labelStyle: const TextStyle(color: Color(0xFF52695A)),
          hintStyle: const TextStyle(color: Color(0xFF819287)),
          prefixIconColor: AppColors.forest,
          suffixIconColor: AppColors.forest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFFD6E4DA)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFFD6E4DA)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: AppColors.forest, width: 2),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.forest,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.forest),
        ),
      ),
      child: child,
    );
  }
}

/// Abstract civic landscape artwork inspired by layered editorial mobile UI.
class AuthScenicArtwork extends StatelessWidget {
  const AuthScenicArtwork({super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 165,
    width: double.infinity,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: CustomPaint(painter: _ScenicPainter()),
    ),
  );
}

class _ScenicPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFBCE0C8), Color(0xFF5FB39A), Color(0xFF1C6D5B)],
        ).createShader(rect),
    );
    canvas.drawCircle(
      Offset(size.width * .77, size.height * .26),
      30,
      Paint()..color = const Color(0xFFFFE38A),
    );
    final far = Path()
      ..moveTo(0, size.height * .68)
      ..lineTo(size.width * .18, size.height * .35)
      ..lineTo(size.width * .36, size.height * .70)
      ..lineTo(size.width * .55, size.height * .36)
      ..lineTo(size.width * .73, size.height * .74)
      ..lineTo(size.width, size.height * .40)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(far, Paint()..color = const Color(0xFF4E9E87));
    final front = Path()
      ..moveTo(0, size.height * .78)
      ..quadraticBezierTo(
        size.width * .28,
        size.height * .40,
        size.width * .56,
        size.height * .77,
      )
      ..quadraticBezierTo(
        size.width * .76,
        size.height * .97,
        size.width,
        size.height * .61,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(front, Paint()..color = const Color(0xFF155A48));
    final road = Path()
      ..moveTo(size.width * .48, size.height)
      ..quadraticBezierTo(
        size.width * .55,
        size.height * .83,
        size.width * .66,
        size.height * .75,
      )
      ..quadraticBezierTo(
        size.width * .54,
        size.height * .91,
        size.width * .58,
        size.height,
      )
      ..close();
    canvas.drawPath(
      road,
      Paint()..color = const Color(0xFFFFD54F).withValues(alpha: .75),
    );
    final dot = Paint()..color = Colors.white.withValues(alpha: .30);
    for (double x = 20; x < size.width; x += 56) {
      canvas.drawCircle(Offset(x, 18), 1.3, dot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
