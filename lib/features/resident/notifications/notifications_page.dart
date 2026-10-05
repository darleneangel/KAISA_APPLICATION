import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() =>
      _NotificationsPageState();
}

class _NotificationsPageState
    extends State<NotificationsPage> {
  String selectedFilter = 'All';

  final List<String> filters = [
    'All',
    'Unread',
  ];

  // ============================================================
  // PROTOTYPE DATA
  //
  // Later this will come from Supabase.
  // ============================================================

  final List<_NotificationData> notifications = [
    _NotificationData(
      id: 1,
      type: NotificationType.verification,
      title: 'Verification Request Submitted',
      message:
          'Your identity verification request has been submitted '
          'and is currently awaiting review.',
      time: '10 min ago',
      isRead: false,
      route: '/resident/verification-status',
    ),
    _NotificationData(
      id: 2,
      type: NotificationType.event,
      title: 'Upcoming Event Reminder',
      message:
          'Community Clean-Up Drive is coming up soon. '
          'Check the event details for the schedule and location.',
      time: '1 hr ago',
      isRead: false,
      route: '/resident/events',
    ),
    _NotificationData(
      id: 3,
      type: NotificationType.organization,
      title: 'Organization Update',
      message:
          'KAISA Youth Volunteers has posted a new community update.',
      time: '3 hrs ago',
      isRead: false,
      route: '/resident/organizations',
    ),
    _NotificationData(
      id: 4,
      type: NotificationType.event,
      title: 'Event Registration Confirmed',
      message:
          'Your registration for Youth Leadership Workshop '
          'has been confirmed.',
      time: 'Yesterday',
      isRead: true,
      route: '/resident/my-events',
    ),
    _NotificationData(
      id: 5,
      type: NotificationType.organization,
      title: 'Organization Request Update',
      message:
          'Your organization request is currently being reviewed.',
      time: 'Yesterday',
      isRead: true,
      route: '/resident/organizations',
    ),
    _NotificationData(
      id: 6,
      type: NotificationType.announcement,
      title: 'New Community Announcement',
      message:
          'A new community announcement has been posted. '
          'Visit the community feed to learn more.',
      time: '2 days ago',
      isRead: true,
      route: '/resident/feed',
    ),
    _NotificationData(
      id: 7,
      type: NotificationType.system,
      title: 'Welcome to KAISA',
      message:
          'Your account has been successfully created. '
          'Explore organizations, events, and community updates.',
      time: '5 days ago',
      isRead: true,
      route: '/resident/home',
    ),
  ];

  List<_NotificationData> get filteredNotifications {
    if (selectedFilter == 'Unread') {
      return notifications
          .where((notification) => !notification.isRead)
          .toList();
    }

    return notifications;
  }

  int get unreadCount {
    return notifications
        .where((notification) => !notification.isRead)
        .length;
  }

  void _markAsRead(_NotificationData notification) {
    if (notification.isRead) return;

    setState(() {
      notification.isRead = true;
    });
  }

  void _markAllAsRead() {
    final hasUnread =
        notifications.any((notification) => !notification.isRead);

    if (!hasUnread) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'All notifications are already read.',
          ),
        ),
      );
      return;
    }

    setState(() {
      for (final notification in notifications) {
        notification.isRead = true;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'All notifications marked as read.',
        ),
      ),
    );
  }

  void _openNotification(
    _NotificationData notification,
  ) {
    _markAsRead(notification);

    if (notification.route ==
        '/resident/verification-status') {
      context.push(
        notification.route,
        extra: {
          'status': 'Pending',
        },
      );

      return;
    }

    context.push(notification.route);
  }

  void _deleteNotification(
    _NotificationData notification,
  ) {
    setState(() {
      notifications.removeWhere(
        (item) => item.id == notification.id,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Notification removed.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedNotifications =
        filteredNotifications;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
        ),
        title: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (unreadCount > 0)
              Text(
                '$unreadCount unread',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.normal,
                  color:
                      AppColors.textSecondary,
                ),
              ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Notification Options',
            onSelected: (value) {
              if (value == 'mark-all') {
                _markAllAsRead();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark-all',
                child: Row(
                  children: [
                    Icon(
                      Icons.done_all_rounded,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Mark all as read',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),

      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ==================================================
            // FILTERS
            // ==================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                16,
                20,
                10,
              ),
              child: Row(
                children: filters.map((filter) {
                  final selected =
                      selectedFilter == filter;

                  final String label =
                      filter == 'Unread'
                          ? 'Unread ($unreadCount)'
                          : filter;

                  return Padding(
                    padding:
                        const EdgeInsets.only(
                      right: 8,
                    ),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          selectedFilter =
                              filter;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            // ==================================================
            // NOTIFICATIONS
            // ==================================================

            Expanded(
              child:
                  displayedNotifications.isEmpty
                      ? _EmptyNotifications(
                          unreadOnly:
                              selectedFilter ==
                                  'Unread',
                        )
                      : ListView.separated(
                          padding:
                              const EdgeInsets
                                  .fromLTRB(
                            20,
                            8,
                            20,
                            50,
                          ),
                          itemCount:
                              displayedNotifications
                                  .length,
                          separatorBuilder:
                              (_, __) =>
                                  const SizedBox(
                            height: 10,
                          ),
                          itemBuilder:
                              (context, index) {
                            final notification =
                                displayedNotifications[
                                    index];

                            return Dismissible(
                              key: ValueKey(
                                notification.id,
                              ),
                              direction:
                                  DismissDirection
                                      .endToStart,
                              background:
                                  Container(
                                alignment: Alignment
                                    .centerRight,
                                padding:
                                    const EdgeInsets
                                        .only(
                                  right: 22,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color: AppColors
                                      .error,
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    18,
                                  ),
                                ),
                                child:
                                    const Icon(
                                  Icons
                                      .delete_outline_rounded,
                                  color:
                                      Colors.white,
                                ),
                              ),
                              onDismissed: (_) {
                                _deleteNotification(
                                  notification,
                                );
                              },
                              child:
                                  _NotificationCard(
                                notification:
                                    notification,
                                onTap: () {
                                  _openNotification(
                                    notification,
                                  );
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// NOTIFICATION TYPES
// ============================================================================

enum NotificationType {
  verification,
  organization,
  event,
  announcement,
  system,
}

// ============================================================================
// NOTIFICATION DATA
// ============================================================================

class _NotificationData {
  final int id;
  final NotificationType type;
  final String title;
  final String message;
  final String time;
  final String route;

  bool isRead;

  _NotificationData({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
    required this.route,
  });
}

// ============================================================================
// NOTIFICATION CARD
// ============================================================================

class _NotificationCard extends StatelessWidget {
  final _NotificationData notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  IconData get _icon {
    switch (notification.type) {
      case NotificationType.verification:
        return Icons.verified_user_outlined;

      case NotificationType.organization:
        return Icons.groups_outlined;

      case NotificationType.event:
        return Icons.event_outlined;

      case NotificationType.announcement:
        return Icons.campaign_outlined;

      case NotificationType.system:
        return Icons.notifications_none_rounded;
    }
  }

  Color get _iconBackground {
    switch (notification.type) {
      case NotificationType.verification:
        return AppColors.blueLight;

      case NotificationType.organization:
        return AppColors.greenLight;

      case NotificationType.event:
        return AppColors.blueLight;

      case NotificationType.announcement:
        return AppColors.yellowLight;

      case NotificationType.system:
        return AppColors.blueLight;
    }
  }

  Color get _iconColor {
    switch (notification.type) {
      case NotificationType.verification:
        return AppColors.blueDark;

      case NotificationType.organization:
        return AppColors.greenDark;

      case NotificationType.event:
        return AppColors.blue;

      case NotificationType.announcement:
        return AppColors.yellowDark;

      case NotificationType.system:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: notification.isRead
          ? AppColors.surface
          : AppColors.blueLight,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color: notification.isRead
                  ? AppColors.border
                  : AppColors.blue,
              width:
                  notification.isRead ? 1 : 1.2,
            ),
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ----------------------------------------------
              // ICON
              // ----------------------------------------------

              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _iconBackground,
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  _icon,
                  size: 22,
                  color: _iconColor,
                ),
              ),

              const SizedBox(width: 13),

              // ----------------------------------------------
              // CONTENT
              // ----------------------------------------------

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  notification.isRead
                                      ? FontWeight
                                          .w600
                                      : FontWeight
                                          .w800,
                              color: AppColors
                                  .textPrimary,
                            ),
                          ),
                        ),

                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin:
                                const EdgeInsets
                                    .only(
                              top: 5,
                              left: 8,
                            ),
                            decoration:
                                const BoxDecoration(
                              color:
                                  AppColors.blue,
                              shape:
                                  BoxShape.circle,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      notification.message,
                      maxLines: 3,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: AppColors
                            .textSecondary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      notification.time,
                      style: const TextStyle(
                        fontSize: 10,
                        color:
                            AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 5),

              const Padding(
                padding:
                    EdgeInsets.only(top: 15),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// EMPTY STATE
// ============================================================================

class _EmptyNotifications extends StatelessWidget {
  final bool unreadOnly;

  const _EmptyNotifications({
    required this.unreadOnly,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons
                  .notifications_none_rounded,
              size: 60,
              color: AppColors.textMuted,
            ),

            const SizedBox(height: 16),

            Text(
              unreadOnly
                  ? 'You\'re all caught up!'
                  : 'No notifications yet',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              unreadOnly
                  ? 'You have no unread notifications.'
                  : 'Updates from KAISA will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color:
                    AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}