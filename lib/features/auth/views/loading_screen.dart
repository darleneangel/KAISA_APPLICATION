import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/kaisa_backdrop.dart';
import '../widgets/auth_ui.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});
  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _next();
  }

  Future<void> _next() async {
    await Future<void>.delayed(const Duration(milliseconds: 2400));
    if (mounted) context.go('/welcome');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        const Positioned.fill(child: KaisaBackdrop()),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) => Transform.scale(
                    scale: .95 + .05 * _controller.value,
                    child: child,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .22),
                      ),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: const AuthBrandHeader(),
                  ),
                ),
                const SizedBox(height: 34),
                const Text(
                  'CONNECT  •  PARTICIPATE  •  IMPACT',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFFFD54F),
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 28),
                const SizedBox(
                  width: 160,
                  child: LinearProgressIndicator(
                    backgroundColor: Color(0xFF2A755C),
                    color: Color(0xFFFFD54F),
                    minHeight: 5,
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
