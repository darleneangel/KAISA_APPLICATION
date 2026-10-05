import 'package:flutter/material.dart';

import '../widgets/resident_bottom_nav.dart';
import '../widgets/notification_bell.dart';

import '../../../core/theme/app_colors.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  String selectedFilter = 'All';

  final List<String> filters = [
    'All',
    'Announcements',
    'Events',
    'Organizations',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Community Feed',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Stay connected with your community',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          const NotificationBell(),
          const SizedBox(width: 8),
        ],
      ),

      body: Column(
        children: [
          // ---------------------------------------------------------
          // FILTERS
          // ---------------------------------------------------------
          SizedBox(
            height: 62,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = filters[index];
                final isSelected = selectedFilter == filter;

                return ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      selectedFilter = filter;
                    });
                  },
                );
              },
            ),
          ),

          const Divider(height: 1),

          // ---------------------------------------------------------
          // FEED
          // ---------------------------------------------------------
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
              children: const [
                _FeedPostCard(
                  organizationName: 'KAISA Youth Volunteers',
                  organizationType: 'Youth Organization',
                  time: '2 hours ago',
                  category: 'Announcement',
                  icon: Icons.volunteer_activism_outlined,
                  content:
                      'We are excited to welcome everyone to another week of community activities! Stay tuned for upcoming volunteer opportunities and announcements.',
                  likes: 24,
                  comments: 6,
                ),

                SizedBox(height: 16),

                _FeedPostCard(
                  organizationName: 'Community Environment Network',
                  organizationType: 'Environmental Organization',
                  time: '5 hours ago',
                  category: 'Event',
                  icon: Icons.eco_outlined,
                  content:
                      'Join us for our upcoming Community Clean-Up Drive! Together, we can help make our community cleaner, greener, and more sustainable.',
                  eventTitle: 'Community Clean-Up Drive',
                  eventDate: 'October 12, 2026',
                  eventTime: '8:00 AM',
                  eventLocation: 'Barangay Covered Court',
                  likes: 41,
                  comments: 12,
                ),

                SizedBox(height: 16),

                _FeedPostCard(
                  organizationName: 'KAISA Community Council',
                  organizationType: 'Community Organization',
                  time: 'Yesterday',
                  category: 'Announcement',
                  icon: Icons.groups_2_outlined,
                  content:
                      'Thank you to all residents who continue to participate in our community programs. Your involvement helps strengthen our community.',
                  likes: 67,
                  comments: 15,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const ResidentBottomNav(
        currentIndex: 1,
      ),
    );
  }
}

// ============================================================================
// FEED POST CARD
// ============================================================================

class _FeedPostCard extends StatefulWidget {
  final String organizationName;
  final String organizationType;
  final String time;
  final String category;
  final IconData icon;
  final String content;

  final String? eventTitle;
  final String? eventDate;
  final String? eventTime;
  final String? eventLocation;

  final int likes;
  final int comments;

  const _FeedPostCard({
    required this.organizationName,
    required this.organizationType,
    required this.time,
    required this.category,
    required this.icon,
    required this.content,
    required this.likes,
    required this.comments,
    this.eventTitle,
    this.eventDate,
    this.eventTime,
    this.eventLocation,
  });

  @override
  State<_FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<_FeedPostCard> {
  bool isLiked = false;

  @override
  Widget build(BuildContext context) {
    final displayedLikes =
        isLiked ? widget.likes + 1 : widget.likes;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------------------------------------------------------
            // ORGANIZATION HEADER
            // -------------------------------------------------------
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.blueLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    widget.icon,
                    color: AppColors.blue,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.organizationName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        '${widget.organizationType} • ${widget.time}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  onPressed: () {
                    // More options later.
                  },
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // -------------------------------------------------------
            // CATEGORY
            // -------------------------------------------------------
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: AppColors.blueLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.category,
                style: const TextStyle(
                  color: AppColors.blueDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(height: 14),

            // -------------------------------------------------------
            // POST CONTENT
            // -------------------------------------------------------
            Text(
              widget.content,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textPrimary,
              ),
            ),

            // -------------------------------------------------------
            // EVENT INFORMATION
            // -------------------------------------------------------
            if (widget.eventTitle != null) ...[
              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.eventTitle!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.greenDark,
                      ),
                    ),

                    const SizedBox(height: 10),

                    _EventInfoRow(
                      icon: Icons.calendar_today_outlined,
                      text: widget.eventDate ?? '',
                    ),

                    const SizedBox(height: 6),

                    _EventInfoRow(
                      icon: Icons.schedule_outlined,
                      text: widget.eventTime ?? '',
                    ),

                    const SizedBox(height: 6),

                    _EventInfoRow(
                      icon: Icons.location_on_outlined,
                      text: widget.eventLocation ?? '',
                    ),

                    const SizedBox(height: 12),

                    OutlinedButton(
                      onPressed: () {
                        // Event details later.
                      },
                      child: const Text('View Event'),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // -------------------------------------------------------
            // COUNTS
            // -------------------------------------------------------
            Row(
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  size: 16,
                  color: AppColors.blue,
                ),

                const SizedBox(width: 5),

                Text(
                  '$displayedLikes',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),

                const Spacer(),

                Text(
                  '${widget.comments} comments',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            const Divider(),

            // -------------------------------------------------------
            // ACTIONS
            // -------------------------------------------------------
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        isLiked = !isLiked;
                      });
                    },
                    icon: Icon(
                      isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isLiked
                          ? AppColors.blue
                          : AppColors.textSecondary,
                    ),
                    label: Text(
                      isLiked ? 'Liked' : 'Like',
                    ),
                  ),
                ),

                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      // Comments page/details later.
                    },
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                    ),
                    label: const Text('Comment'),
                  ),
                ),

                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      // Share functionality later.
                    },
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// EVENT INFO
// ============================================================================

class _EventInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EventInfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.greenDark,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.greenDark,
            ),
          ),
        ),
      ],
    );
  }
}