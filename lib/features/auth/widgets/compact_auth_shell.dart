import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/kaisa_figma_theme.dart';

/// DESIGN ONLY. The caller's `child` contains all form fields, validation,
/// Google sign-in callbacks, Supabase requests and navigation behavior.
/// This shell never intercepts, replaces or simulates them.
class CompactAuthShell extends StatelessWidget {
  const CompactAuthShell({
    super.key,
    required this.child,
    this.backRoute = '/welcome',
  });
  final Widget child;
  final String backRoute;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      return Theme(
        data: KaisaFigmaTheme.light,
        child: Scaffold(
          backgroundColor: KaisaFigmaPalette.paper,
          body: Row(
            children: [
              if (wide)
                Expanded(
                  flex: 11,
                  child: SizedBox.expand(child: _AuthStoryPanel()),
                ),
              Expanded(
                flex: 10,
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: wide ? 44 : 19,
                        vertical: wide ? 28 : 22,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 470),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!wide) ...[
                              const _AuthBrand(),
                              const SizedBox(height: 28),
                            ],
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: KaisaFigmaPalette.outline,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x11000000),
                                    blurRadius: 35,
                                    offset: Offset(0, 12),
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.fromLTRB(
                                wide ? 33 : 22,
                                22,
                                wide ? 33 : 22,
                                29,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        tooltip: 'Go back',
                                        style: IconButton.styleFrom(
                                          backgroundColor:
                                              KaisaFigmaPalette.mint,
                                        ),
                                        onPressed: () => context.go(backRoute),
                                        icon: const Icon(
                                          Icons.arrow_back_rounded,
                                          color: KaisaFigmaPalette.green,
                                        ),
                                      ),
                                      const Spacer(),
                                      const Icon(
                                        Icons.shield_outlined,
                                        color: KaisaFigmaPalette.green,
                                        size: 19,
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'SECURE ACCESS',
                                        style: TextStyle(
                                          color: KaisaFigmaPalette.muted,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 22),
                                  // Existing LoginPage/SignUpPage subtree unchanged.
                                  child,
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Center(
                              child: Text(
                                'Connecting Communities  •  KAISA',
                                style: TextStyle(
                                  color: KaisaFigmaPalette.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ),
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
    },
  );
}

class _AuthBrand extends StatelessWidget {
  const _AuthBrand();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: KaisaFigmaPalette.action,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.diversity_3_rounded,
          color: KaisaFigmaPalette.yellow,
          size: 27,
        ),
      ),
      const SizedBox(width: 13),
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'KAISA',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: KaisaFigmaPalette.forest,
            ),
          ),
          Text(
            'TOGETHER, WE MAKE AN IMPACT',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: .7,
              color: KaisaFigmaPalette.green,
            ),
          ),
        ],
      ),
    ],
  );
}

class _AuthStoryPanel extends StatelessWidget {
  const _AuthStoryPanel();
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(gradient: KaisaFigmaPalette.hero),
    child: Stack(
      children: [
        Positioned(top: -130, right: -130, child: _Orb(size: 380)),
        Positioned(bottom: -160, left: -160, child: _Orb(size: 440)),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(58),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(21),
                        ),
                        child: const Icon(
                          Icons.diversity_3_rounded,
                          size: 35,
                          color: KaisaFigmaPalette.yellow,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'KAISA',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 33,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                  const Text(
                    'Stronger communities\nstart with us.',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 44,
                      height: 1.13,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Discover local opportunities, join organizations, '
                    'and participate in meaningful community programs.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .82),
                      fontSize: 16,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 42),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: const [
                      _Feature(
                        icon: Icons.calendar_month_rounded,
                        label: 'Community events',
                      ),
                      _Feature(
                        icon: Icons.groups_rounded,
                        label: 'Organizations',
                      ),
                      _Feature(
                        icon: Icons.qr_code_2_rounded,
                        label: 'Verified attendance',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size});
  final double size;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .05),
        shape: BoxShape.circle,
      ),
    ),
  );
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withValues(alpha: .18)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: KaisaFigmaPalette.yellow, size: 17),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}
