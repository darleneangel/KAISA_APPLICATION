import 'package:flutter/material.dart';
import '../widgets/kaisa_resident_design.dart';
import 'kaisa_events_repository.dart';

class KaisaEventsHeading extends StatelessWidget {
  const KaisaEventsHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.action,
  });
  final String eyebrow, title, subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                color: KaisaResidentDesign.green,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
                fontSize: MediaQuery.sizeOf(context).width < 600 ? 28 : 35,
                color: KaisaResidentDesign.ink,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: const TextStyle(
                color: KaisaResidentDesign.muted,
                height: 1.5,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      if (action != null) action!,
    ],
  );
}

class KaisaEventsHero extends StatelessWidget {
  const KaisaEventsHero({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.action,
  });
  final String title, subtitle;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(narrow ? 22 : 30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [KaisaResidentDesign.forest, Color(0xFF267A50)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -15,
            top: -15,
            child: Icon(
              icon,
              color: Colors.white.withValues(alpha: .10),
              size: narrow ? 125 : 150,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '✦  KAISA COMMUNITY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: KaisaResidentDesign.yellow,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: narrow ? 23 : 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.18,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Color(0xFFE0F0E6),
                ),
              ),
              if (action != null) ...[const SizedBox(height: 18), action!],
            ],
          ),
        ],
      ),
    );
  }
}

class KaisaEventCard extends StatelessWidget {
  const KaisaEventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.showStatus = false,
  });
  final KaisaEvent event;
  final VoidCallback onTap;
  final bool showStatus;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(KaisaResidentDesign.cardRadius),
    child: InkWell(
      borderRadius: BorderRadius.circular(KaisaResidentDesign.cardRadius),
      onTap: onTap,
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
                  width: 54,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F2E9),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Column(
                    children: [
                      Text(
                        event.monthShort,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: KaisaResidentDesign.green,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${event.startsAt.day}',
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          color: KaisaResidentDesign.forest,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.category.toUpperCase(),
                        style: const TextStyle(
                          color: KaisaResidentDesign.green,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: KaisaResidentDesign.ink,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        event.organization,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: KaisaResidentDesign.muted,
                          fontSize: 12,
                        ),
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
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.schedule_outlined,
                  color: KaisaResidentDesign.green,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    event.timeLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: KaisaResidentDesign.muted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                const Icon(
                  Icons.place_outlined,
                  color: KaisaResidentDesign.green,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    event.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: KaisaResidentDesign.muted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            const Divider(color: KaisaResidentDesign.border),
            Row(
              children: [
                Icon(
                  showStatus
                      ? Icons.verified_outlined
                      : Icons.people_outline_rounded,
                  size: 16,
                  color: KaisaResidentDesign.green,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    showStatus
                        ? event.statusLabel
                        : '${event.registeredCount} of ${event.capacity} registered',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: KaisaResidentDesign.ink,
                    ),
                  ),
                ),
                if (!showStatus)
                  Text(
                    event.isFull
                        ? 'Full'
                        : '${event.capacity - event.registeredCount} slots left',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: event.isFull
                          ? Colors.red.shade700
                          : KaisaResidentDesign.green,
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
