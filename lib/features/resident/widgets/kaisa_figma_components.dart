import 'package:flutter/material.dart';
import 'kaisa_resident_design.dart';

/// Presentation-only components. Feed them data already fetched by KAISA.
/// Never replace Supabase data, registration or QR tokens with demo values.
class KaisaFigmaCard extends StatelessWidget {
  const KaisaFigmaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: KaisaResidentDesign.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x09000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    ),
  );
}

class KaisaFigmaHero extends StatelessWidget {
  const KaisaFigmaHero({
    super.key,
    required this.title,
    required this.subtitle,
    this.eyebrow,
    this.icon = Icons.volunteer_activism_rounded,
    this.trailing,
  });
  final String title, subtitle;
  final String? eyebrow;
  final IconData icon;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(23),
    decoration: BoxDecoration(
      gradient: KaisaResidentDesign.heroGradient,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow!.toUpperCase(),
                  style: KaisaTypography.body(
                    TextStyle(
                      color: KaisaResidentDesign.yellow,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Text(
                title,
                style: KaisaTypography.heading(
                  TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: KaisaTypography.body(
                  TextStyle(
                    color: Colors.white.withValues(alpha: .80),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 15),
        trailing ??
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(icon, color: KaisaResidentDesign.yellow, size: 28),
            ),
      ],
    ),
  );
}

class KaisaFigmaSection extends StatelessWidget {
  const KaisaFigmaSection({
    super.key,
    required this.title,
    this.caption,
    this.actionText,
    this.onAction,
  });
  final String title;
  final String? caption, actionText;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: KaisaTypography.heading(
                TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                  letterSpacing: -.35,
                  color: KaisaResidentDesign.ink,
                ),
              ),
            ),
            if (caption != null) ...[
              const SizedBox(height: 4),
              Text(
                caption!,
                style: KaisaTypography.body(
                  TextStyle(color: KaisaResidentDesign.muted, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
      if (onAction != null && actionText != null)
        TextButton.icon(
          onPressed: onAction,
          label: Text(actionText!),
          iconAlignment: IconAlignment.end,
          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
        ),
    ],
  );
}

class KaisaFigmaStat extends StatelessWidget {
  const KaisaFigmaStat({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.tint = KaisaResidentDesign.forest,
    this.onTap,
  });
  final String label, value;
  final IconData icon;
  final Color tint;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => KaisaFigmaCard(
    padding: const EdgeInsets.all(13),
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: tint, size: 22),
        ),
        const SizedBox(height: 9),
        Text(
          value,
          style: KaisaTypography.data(
            TextStyle(color: tint, fontSize: 28, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: KaisaTypography.body(
            TextStyle(color: KaisaResidentDesign.muted, fontSize: 11),
          ),
        ),
      ],
    ),
  );
}

class KaisaFigmaEventCard extends StatelessWidget {
  const KaisaFigmaEventCard({
    super.key,
    required this.title,
    required this.organizer,
    required this.dateLabel,
    required this.onTap,
    this.category,
    this.imageUrl,
    this.trailing,
  });
  final String title, organizer, dateLabel;
  final String? category, imageUrl;
  final VoidCallback onTap;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => KaisaFigmaCard(
    padding: EdgeInsets.zero,
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: SizedBox(
            height: 128,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imageUrl != null && imageUrl!.isNotEmpty)
                  Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _ImageFallback(),
                  )
                else
                  const _ImageFallback(),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xB3000000)],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 13,
                  left: 14,
                  right: 14,
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: KaisaTypography.heading(
                      TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                if (category != null)
                  Positioned(
                    top: 10,
                    left: 11,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xB3184F30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        category!,
                        style: KaisaTypography.body(
                          TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.groups_2_outlined,
                    size: 16,
                    color: KaisaResidentDesign.forest,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      organizer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KaisaTypography.body(
                        TextStyle(
                          color: KaisaResidentDesign.muted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.event_outlined,
                    size: 16,
                    color: KaisaResidentDesign.forest,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      dateLabel,
                      style: KaisaTypography.body(
                        TextStyle(
                          color: KaisaResidentDesign.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: KaisaResidentDesign.muted,
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

class KaisaFigmaOrganizationCard extends StatelessWidget {
  const KaisaFigmaOrganizationCard({
    super.key,
    required this.name,
    required this.description,
    required this.onTap,
    this.logoUrl,
    this.category,
    this.memberCount,
  });
  final String name, description;
  final VoidCallback onTap;
  final String? logoUrl, category;
  final int? memberCount;
  @override
  Widget build(BuildContext context) => KaisaFigmaCard(
    onTap: onTap,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: KaisaResidentDesign.mint,
            borderRadius: BorderRadius.circular(18),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: logoUrl == null || logoUrl!.isEmpty
                ? const Icon(
                    Icons.apartment_rounded,
                    color: KaisaResidentDesign.forest,
                    size: 29,
                  )
                : Image.network(
                    logoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.apartment_rounded,
                      color: KaisaResidentDesign.forest,
                      size: 29,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: KaisaTypography.heading(
                  TextStyle(
                    color: KaisaResidentDesign.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              if (category != null)
                Text(
                  category!,
                  style: KaisaTypography.body(
                    TextStyle(
                      color: KaisaResidentDesign.forest,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              const SizedBox(height: 7),
              Text(
                description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: KaisaTypography.body(
                  TextStyle(
                    color: KaisaResidentDesign.muted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
              if (memberCount != null) ...[
                const SizedBox(height: 9),
                Row(
                  children: [
                    const Icon(
                      Icons.people_alt_outlined,
                      size: 15,
                      color: KaisaResidentDesign.forest,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$memberCount members',
                      style: KaisaTypography.data(
                        TextStyle(
                          color: KaisaResidentDesign.ink,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const Icon(
          Icons.chevron_right_rounded,
          color: KaisaResidentDesign.muted,
        ),
      ],
    ),
  );
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();
  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: KaisaResidentDesign.mint,
    child: Center(
      child: Icon(
        Icons.landscape_rounded,
        size: 44,
        color: KaisaResidentDesign.forest,
      ),
    ),
  );
}
