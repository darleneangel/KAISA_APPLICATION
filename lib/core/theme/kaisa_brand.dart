import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Single source of truth for logo paths (they were inconsistent before:
/// `lgu_seal.png` vs `LGU.png`). Change here if your file names differ.
abstract final class KaisaAssets {
  static const lguSeal = 'assets/images/LGU.png';
  static const kaisaLogo = 'assets/images/kaisa_logo.png';
}

/// White rounded tile that holds a logo, with an icon/label fallback.
class KaisaLogoTile extends StatelessWidget {
  const KaisaLogoTile({
    super.key,
    required this.asset,
    this.size = 40,
    this.fallbackIcon = Icons.eco_rounded,
    this.fallbackLabel,
  });

  final String asset;
  final double size;
  final IconData fallbackIcon;
  final String? fallbackLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * .14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * .32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .14),
            blurRadius: size * .35,
            offset: Offset(0, size * .12),
          ),
        ],
      ),
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Center(
          child: fallbackLabel != null
              ? Text(
                  fallbackLabel!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: size * .13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.forest,
                  ),
                )
              : Icon(fallbackIcon, size: size * .5, color: AppColors.forest),
        ),
      ),
    );
  }
}

/// Glass pill: LGU seal + KAISA logo + wordmark. Sits on dark hero areas.
class KaisaLockup extends StatelessWidget {
  const KaisaLockup({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 5, 16, 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const KaisaLogoTile(
            asset: KaisaAssets.lguSeal,
            size: 34,
            fallbackIcon: Icons.account_balance_rounded,
          ),
          const SizedBox(width: 5),
          const KaisaLogoTile(
            asset: KaisaAssets.kaisaLogo,
            size: 34,
            fallbackIcon: Icons.diversity_3_rounded,
          ),
          const SizedBox(width: 11),
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.yellow,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          const Text(
            'KAISA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
