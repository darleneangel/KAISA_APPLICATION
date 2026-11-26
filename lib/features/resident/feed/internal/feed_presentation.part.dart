part of '../feed_page.dart';

// Existing Feed palette, category helpers, and time formatting. Stitch Civic Dignity palette.
// Civic Dignity: Stitch is a visual reference, not a source of new features.
const _forest = Color(0xFF00492C);
const _green = Color(0xFF2C6A4A);
const _yellow = Color(0xFFFDBC19);
const _ink = Color(0xFF151C27);
const _muted = Color(0xFF6B7280);
const _canvas = Color(0xFFF8F9FA);
const _soft = Color(0xFFF0F5F1);
const _line = Color(0xFFE5E7EB);
const _sage = Color(0xFF95D4AD);

String _relativeTime(DateTime? date) {
  if (date == null) return 'Recently';
  final elapsed = DateTime.now().difference(date);
  if (elapsed.isNegative || elapsed.inMinutes < 1) return 'Just now';
  if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}m ago';
  if (elapsed.inHours < 24) return '${elapsed.inHours}h ago';
  if (elapsed.inDays < 7) return '${elapsed.inDays}d ago';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

Color _categoryTint(String category) {
  switch (category.toLowerCase()) {
    case 'announcement':
      return const Color(0xFFFFF2D5);
    case 'event':
      return const Color(0xFFE8F0FF);
    case 'organization':
      return const Color(0xFFF0EAFE);
    default:
      return const Color(0xFFE9F4EC);
  }
}

Color _categoryInk(String category) {
  switch (category.toLowerCase()) {
    case 'announcement':
      return const Color(0xFF856000);
    case 'event':
      return const Color(0xFF2D567E);
    case 'organization':
      return const Color(0xFF65528E);
    default:
      return _forest;
  }
}

IconData _categoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'announcement':
      return Icons.campaign_outlined;
    case 'event':
      return Icons.event_available_outlined;
    case 'organization':
      return Icons.groups_2_outlined;
    default:
      return Icons.forum_outlined;
  }
}
