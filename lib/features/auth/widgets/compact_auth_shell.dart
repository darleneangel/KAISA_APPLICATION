import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

/// One white form surface for both narrow mobile and desktop browser viewports.
class CompactAuthShell extends StatelessWidget {
  final Widget child;
  final String backRoute;
  const CompactAuthShell({
    super.key,
    required this.child,
    this.backRoute = '/welcome',
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 800;
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Montserrat',
    );
    return Theme(
      data: base.copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.forest),
        scaffoldBackgroundColor: const Color(0xFFF6F8F3),
        textTheme: base.textTheme.apply(
          bodyColor: const Color(0xFF203A2D),
          displayColor: const Color(0xFF203A2D),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF7FAF7),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
          labelStyle: const TextStyle(color: Color(0xFF5D7166)),
          prefixIconColor: AppColors.forest,
          suffixIconColor: AppColors.forest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFFD6E3DA)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFFD6E3DA)),
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
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8F3),
        body: Stack(
          children: [
            Positioned(
              top: -90,
              right: -75,
              child: _Glow(
                size: wide ? 310 : 190,
                color: const Color(0xFFD6ECD7),
              ),
            ),
            Positioned(
              bottom: -130,
              left: -80,
              child: _Glow(
                size: wide ? 370 : 230,
                color: const Color(0xFFFFF1B9),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: wide ? 32 : 16,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: wide ? 510 : 500),
                    child: Container(
                      padding: EdgeInsets.fromLTRB(
                        wide ? 36 : 22,
                        20,
                        wide ? 36 : 22,
                        wide ? 32 : 22,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(wide ? 30 : 25),
                        border: Border.all(color: const Color(0xFFE5EBE5)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF154B37,
                            ).withValues(alpha: .09),
                            blurRadius: 45,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'Go back',
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xFFF0F6F0),
                                ),
                                onPressed: () => context.go(backRoute),
                                icon: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: AppColors.forest,
                                ),
                              ),
                              const Spacer(),
                              _Logo(
                                'assets/images/LGU.png',
                                Icons.account_balance_rounded,
                              ),
                              const SizedBox(width: 8),
                              _Logo(
                                'assets/images/kaisa_logo.png',
                                Icons.diversity_3_rounded,
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          child,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final String path;
  final IconData fallback;
  const _Logo(this.path, this.fallback);
  @override
  Widget build(BuildContext context) => Container(
    height: 42,
    width: 42,
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0xFFE0E8E1)),
    ),
    child: Image.asset(
      path,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(fallback, color: AppColors.forest),
    ),
  );
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;
  const _Glow({required this.size, required this.color});
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
  );
}
