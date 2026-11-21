import 'dart:async';

import 'package:flutter/material.dart';

/// The SAME background assets, seven-second rotation, 1350ms crossfade,
/// and dark forest scrim used on the KAISA Login and Welcome screens.
///
/// The slideshow is completely independent of authentication. Missing local
/// assets fall back to the original URLs, then to an opaque forest backdrop.
/// The composite photo list + normalized index avoids the previous RangeError.
class KaisaAuthSlideshowBackground extends StatefulWidget {
  const KaisaAuthSlideshowBackground({super.key});

  @override
  State<KaisaAuthSlideshowBackground> createState() =>
      _KaisaAuthSlideshowBackgroundState();
}

class _KaisaPhoto {
  const _KaisaPhoto(this.asset, this.url);

  final String asset;
  final String url;
}

class _KaisaAuthSlideshowBackgroundState
    extends State<KaisaAuthSlideshowBackground> {
  static const Color _dark = Color(0xFF002818);
  static const List<_KaisaPhoto> _photos = [
    _KaisaPhoto(
      'assets/images/kaisa_bg_01.jpg',
      'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?auto=format&fit=crop&w=1600&q=82',
    ),
    _KaisaPhoto(
      'assets/images/kaisa_bg_02.jpg',
      'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=1600&q=82',
    ),
    _KaisaPhoto(
      'assets/images/kaisa_bg_03.jpg',
      'https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?auto=format&fit=crop&w=1600&q=82',
    ),
    _KaisaPhoto(
      'assets/images/kaisa_bg_04.jpg',
      'https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?auto=format&fit=crop&w=1600&q=82',
    ),
    _KaisaPhoto(
      'assets/images/kaisa_bg_05.jpg',
      'https://images.unsplash.com/photo-1556761175-b413da4baf72?auto=format&fit=crop&w=1600&q=82',
    ),
  ];

  Timer? _timer;
  int _active = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion || _photos.isEmpty) {
      _timer?.cancel();
      _timer = null;
    } else {
      _timer ??= Timer.periodic(const Duration(seconds: 7), (_) {
        if (!mounted || _photos.isEmpty) return;
        setState(() => _active = (_active + 1) % _photos.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_photos.isEmpty) return const ColoredBox(color: _dark);

    final index = _active % _photos.length;
    final photo = _photos[index];
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: _dark),
          AnimatedSwitcher(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 1350),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            layoutBuilder: (current, previous) => Stack(
              fit: StackFit.expand,
              children: [...previous, if (current != null) current],
            ),
            child: Image.asset(
              photo.asset,
              key: ValueKey<int>(index),
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) => Image.network(
                photo.url,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, error, stackTrace) =>
                    const ColoredBox(color: _dark),
              ),
            ),
          ),
          ColoredBox(color: _dark.withValues(alpha: 0.50)),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xA6002015),
                  Color(0x1A002818),
                  Color(0xAA002015),
                ],
                stops: [0.0, 0.48, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
