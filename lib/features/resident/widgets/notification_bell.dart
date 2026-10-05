import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class NotificationBell extends StatelessWidget {
  final int unreadCount;

  const NotificationBell({
    super.key,
    this.unreadCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Notifications',
      onPressed: () {
        context.push('/resident/notifications');
      },
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.notifications_none_rounded,
          ),

          if (unreadCount > 0)
            Positioned(
              right: -5,
              top: -5,
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: 17,
                  minHeight: 17,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                ),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadCount > 9
                      ? '9+'
                      : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}