import 'package:flutter/material.dart';
import '../notifications/kaisa_notification_repository.dart';
import 'kaisa_resident_design.dart';

class KaisaNotificationCard extends StatelessWidget {
  const KaisaNotificationCard({
    super.key,
    required this.notification,
    required this.expanded,
    required this.onExpand,
    this.onRead,
    required this.onOpen,
    this.onDelete,
    this.openLabel = 'Open related page',
    required this.busy,
  });
  final KaisaNotification notification;
  final bool expanded, busy;
  final String openLabel;
  final VoidCallback onExpand, onOpen;
  final VoidCallback? onRead, onDelete;
  static String category(String kind) => switch (kind) {
    'event' => 'Events',
    'organization' => 'Organizations',
    'verification' => 'Verification',
    'like' || 'comment' => 'Community feed',
    'message' => 'Messages',
    'certificate' => 'Certificates',
    _ => 'System',
  };
  IconData get _icon => switch (notification.kind) {
    'event' => Icons.event_available_outlined,
    'organization' => Icons.groups_outlined,
    'verification' => Icons.verified_user_outlined,
    'like' => Icons.favorite_border,
    'comment' => Icons.chat_bubble_outline,
    'message' => Icons.mail_outline,
    'certificate' => Icons.workspace_premium_outlined,
    _ => Icons.notifications_none_rounded,
  };
  String _date(BuildContext context) {
    final d = notification.createdAt;
    if (d == null) return 'Date unavailable';
    final loc = MaterialLocalizations.of(context);
    return '${loc.formatMediumDate(d)} · ${loc.formatTimeOfDay(TimeOfDay.fromDateTime(d))}';
  }

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark ? const Color(0xFF9ED6B3) : KaisaResidentDesign.forest;
    final surface = scheme.surface;
    final muted = scheme.onSurfaceVariant;
    final radius = BorderRadius.circular(12);
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.topCenter,
      child: Material(
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: n.isRead
                ? scheme.outlineVariant
                : accent.withValues(alpha: .45),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: busy ? null : onExpand,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_icon, color: accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category(n.kind).toUpperCase(),
                            style: KaisaTypography.body(
                              TextStyle(
                                color: accent,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: .7,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            n.title,
                            style: KaisaTypography.heading(
                              TextStyle(
                                fontSize: 17,
                                fontWeight: n.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (!expanded && n.body.isNotEmpty)
                            Text(
                              n.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: KaisaTypography.body(
                                TextStyle(
                                  fontSize: 13,
                                  color: muted,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          const SizedBox(height: 6),
                          Text(
                            _date(context),
                            style: KaisaTypography.data(
                              TextStyle(fontSize: 11, color: muted),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      children: [
                        if (!n.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Icon(
                          expanded ? Icons.expand_less : Icons.expand_more,
                          color: muted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (expanded) ...[
              Divider(height: 1, color: scheme.outlineVariant),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notification details',
                      style: KaisaTypography.heading(
                        TextStyle(fontSize: 15, color: scheme.onSurface),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      n.body.isEmpty
                          ? 'No additional details were recorded for this notification. Open the related section to review your records.'
                          : n.body,
                      style: KaisaTypography.body(
                        TextStyle(
                          fontSize: 14,
                          height: 1.55,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (n.targetPath.isNotEmpty)
                          FilledButton.icon(
                            onPressed: busy ? null : onOpen,
                            icon: const Icon(Icons.arrow_outward, size: 16),
                            label: Text(openLabel),
                            style: FilledButton.styleFrom(
                              backgroundColor: KaisaResidentDesign.forest,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        if (!n.isRead && onRead != null)
                          TextButton(
                            onPressed: busy ? null : onRead,
                            child: const Text('Mark as read'),
                          ),
                        if (onDelete != null)
                          TextButton.icon(
                            onPressed: busy ? null : onDelete,
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Remove'),
                            style: TextButton.styleFrom(
                              foregroundColor: scheme.error,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
