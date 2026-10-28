import 'package:flutter/material.dart';
import '../widgets/kaisa_resident_design.dart';
import 'kaisa_organizations_repository.dart';

class KaisaOrganizationPageFrame extends StatelessWidget {
  const KaisaOrganizationPageFrame({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: KaisaResidentDesign.paper,
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: KaisaResidentDesign.desktopWidth,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            KaisaResidentDesign.pagePadding(MediaQuery.sizeOf(context).width),
            14,
            KaisaResidentDesign.pagePadding(MediaQuery.sizeOf(context).width),
            20,
          ),
          child: child,
        ),
      ),
    ),
  );
}

class KaisaOrganizationHeading extends StatelessWidget {
  const KaisaOrganizationHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });
  final String eyebrow, title, subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        eyebrow,
        style: const TextStyle(
          color: KaisaResidentDesign.green,
          fontSize: 11,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 7),
      Text(
        title,
        style: TextStyle(
          color: KaisaResidentDesign.ink,
          fontSize: MediaQuery.sizeOf(context).width < 600 ? 29 : 35,
          letterSpacing: -.7,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        subtitle,
        style: const TextStyle(
          color: KaisaResidentDesign.muted,
          fontSize: 13,
          height: 1.45,
        ),
      ),
    ],
  );
}

class KaisaOrganizationHero extends StatelessWidget {
  const KaisaOrganizationHero({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
  });
  final String title, subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 22 : 30),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [KaisaResidentDesign.forest, Color(0xFF267A50)],
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Stack(
      children: [
        Positioned(
          right: -18,
          top: -15,
          child: Icon(
            Icons.diversity_3_rounded,
            size: 135,
            color: Colors.white.withValues(alpha: .09),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '✦  KAISA COMMUNITY',
              style: TextStyle(
                color: KaisaResidentDesign.yellow,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 25,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFFE0F0E6),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 17), action!],
          ],
        ),
      ],
    ),
  );
}

IconData kaisaOrganizationIcon(String category) {
  switch (category.toLowerCase()) {
    case 'youth':
      return Icons.volunteer_activism_outlined;
    case 'environment':
      return Icons.eco_outlined;
    case 'education':
      return Icons.school_outlined;
    case 'sports':
      return Icons.sports_basketball_outlined;
    case 'culture & arts':
      return Icons.palette_outlined;
    case 'health & wellness':
      return Icons.health_and_safety_outlined;
    default:
      return Icons.groups_2_outlined;
  }
}

class KaisaOrganizationCard extends StatelessWidget {
  const KaisaOrganizationCard({
    super.key,
    required this.org,
    required this.onTap,
    this.showMembership = false,
  });
  final KaisaOrganization org;
  final VoidCallback onTap;
  final bool showMembership;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(KaisaResidentDesign.cardRadius),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KaisaResidentDesign.cardRadius),
      child: Container(
        padding: const EdgeInsets.all(KaisaResidentDesign.cardPadding),
        decoration: KaisaResidentDesign.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 51,
                  height: 51,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F3EA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    kaisaOrganizationIcon(org.category),
                    color: KaisaResidentDesign.green,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        org.category.toUpperCase(),
                        style: const TextStyle(
                          color: KaisaResidentDesign.green,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        org.name,
                        style: const TextStyle(
                          color: KaisaResidentDesign.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: KaisaResidentDesign.muted,
                ),
              ],
            ),
            const SizedBox(height: 13),
            Text(
              org.description.isEmpty
                  ? 'Discover this community organization.'
                  : org.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: KaisaResidentDesign.muted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 13),
            const Divider(color: KaisaResidentDesign.border),
            Row(
              children: [
                const Icon(
                  Icons.people_outline_rounded,
                  color: KaisaResidentDesign.green,
                  size: 17,
                ),
                const SizedBox(width: 6),
                Text(
                  '${org.memberCount} members',
                  style: const TextStyle(
                    color: KaisaResidentDesign.muted,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if (org.myStatus == 'pending')
                  const Text(
                    'Pending',
                    style: TextStyle(
                      color: Color(0xFF9B7716),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  )
                else if (org.isMember)
                  Text(
                    showMembership ? (org.myRole ?? 'Member') : 'Joined',
                    style: const TextStyle(
                      color: KaisaResidentDesign.green,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class KaisaOrganizationEmpty extends StatelessWidget {
  const KaisaOrganizationEmpty({
    super.key,
    required this.title,
    required this.message,
    this.action,
  });
  final String title, message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(25),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.groups_outlined,
            color: KaisaResidentDesign.green,
            size: 46,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: KaisaResidentDesign.ink,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: KaisaResidentDesign.muted,
              height: 1.5,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    ),
  );
}
