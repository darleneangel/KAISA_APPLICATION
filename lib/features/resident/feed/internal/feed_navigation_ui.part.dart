part of '../feed_page.dart';

// Avatar, quick links and responsive sidebar panels.
mixin _FeedNavigationUi on _FeedStateCore {
  @override
  Widget _avatar({double radius = 22}) {
    final fallback = displayName.trim().isEmpty
        ? 'R'
        : displayName.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE3F1E7),
      backgroundImage: avatarPath.isEmpty
          ? null
          : NetworkImage(
              db.storage.from('kaisa-avatars').getPublicUrl(avatarPath),
            ),
      child: avatarPath.isEmpty
          ? Text(
              fallback,
              style: GoogleFonts.inter(
                textStyle: TextStyle(
                  color: _forest,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          : null,
    );
  }

  @override
  Widget _quickLink(IconData icon, String text, String route) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    leading: Icon(icon, color: _forest, size: 23),
    title: Text(
      text,
      style: GoogleFonts.inter(
        textStyle: TextStyle(
          fontWeight: FontWeight.w700,
          color: _ink,
          fontSize: 13,
        ),
      ),
    ),
    onTap: () => context.push(route),
  );

  @override
  Widget _sidebar(bool right) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: right
        ? [
            _sidePanel(
              title: 'Explore KAISA',
              subtitle: 'Stay involved in your community',
              children: [
                _quickLink(
                  Icons.event_available_outlined,
                  'Upcoming events',
                  '/resident/events',
                ),
                _quickLink(
                  Icons.groups_outlined,
                  'Organizations',
                  '/resident/organizations',
                ),
                _quickLink(
                  Icons.search_rounded,
                  'Community Feed',
                  '/resident/feed',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _sidePanel(
              title: 'Your activity',
              children: [
                _quickLink(
                  Icons.event_note_outlined,
                  'My events',
                  '/resident/my-events',
                ),
                _quickLink(
                  Icons.group_work_outlined,
                  'My organizations',
                  '/resident/my-organizations',
                ),
                _quickLink(
                  Icons.notifications_none_rounded,
                  'Notifications',
                  '/resident/notifications',
                ),
              ],
            ),
          ]
        : [
            _sidePanel(
              title: 'Your community',
              children: [
                _quickLink(
                  Icons.person_outline_rounded,
                  'My profile',
                  '/resident/profile',
                ),
                _quickLink(
                  Icons.forum_outlined,
                  'Community Feed',
                  '/resident/feed',
                ),
                _quickLink(
                  Icons.chat_bubble_outline_rounded,
                  'My organizations',
                  '/resident/my-organizations',
                ),
                _quickLink(
                  Icons.groups_2_outlined,
                  'Organizations',
                  '/resident/organizations',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: _forest,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.volunteer_activism_rounded,
                    color: _yellow,
                    size: 28,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Stronger communities start with you.',
                    style: GoogleFonts.inter(
                      textStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Discover activities, find your people, and make a difference.',
                    style: TextStyle(color: Color(0xFFDCECDF), fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => context.push('/resident/events'),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Browse events'),
                    style: TextButton.styleFrom(foregroundColor: _yellow),
                  ),
                ],
              ),
            ),
          ],
  );

  @override
  Widget _sidePanel({
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: KaisaResidentDesign.border),
      borderRadius: BorderRadius.circular(8),
    ),
    padding: const EdgeInsets.fromLTRB(10, 16, 10, 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              textStyle: TextStyle(
                color: _ink,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
            child: Text(
              subtitle,
              style: GoogleFonts.inter(
                textStyle: TextStyle(color: _muted, fontSize: 12),
              ),
            ),
          ),
        const SizedBox(height: 5),
        ...children,
      ],
    ),
  );
}
