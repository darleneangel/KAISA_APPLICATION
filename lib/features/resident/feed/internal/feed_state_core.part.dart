part of '../feed_page.dart';

// Shared state, lifecycle, and cross-feature contracts.
mixin _FeedStateCore on State<LegacySocialFeedPage> {
  final db = Supabase.instance.client;
  List<Map<String, dynamic>> posts = [];
  String filter = 'All';
  final TextEditingController _searchController = TextEditingController();
  List<String> _feedInterests = [];
  List<String> _feedSkills = [];
  bool _personalized = true;
  bool _savingPreferences = false;
  bool _showCategoryFilters = true;
  Map<String, String> _storyUrls = {};
  bool loading = true;
  bool tier2 = false;
  List<Map<String, dynamic>> stories = [];
  Timer? _storyTicker;
  String? error;
  String displayName = 'Resident';
  String avatarPath = '';
  late final VoidCallback _profileChangeListener;

  // Contracts implemented by the focused mixins below. This keeps all
  // original private method names and the existing widget behavior intact.
  Future<void> _loadProfile();
  Future<void> _editFeedPreferences();
  Future<void> _openSmartSearch();
  Future<void> _load();
  Future<void> _loadStories();
  Future<void> _createStory();
  Future<void> _viewStory(Map<String, dynamic> story);
  Widget _storiesStrip();
  Future<void> _compose();
  Future<void> _toggleLike(Map<String, dynamic> post);
  Future<void> _comments(Map<String, dynamic> post);
  Future<void> _share(Map<String, dynamic> post);
  void _snack(String message);
  Widget _avatar({double radius = 22});
  Widget _quickLink(IconData icon, String text, String route);
  Widget _sidebar(bool right);
  Widget _sidePanel({
    required String title,
    String? subtitle,
    required List<Widget> children,
  });
  Widget _composer();
  Widget _bulletin(Map<String, dynamic> announcement);
  Widget _feedSortChip(String title, IconData icon, bool personalized);
  Widget _feedMain(List<Map<String, dynamic>> shown);
  Widget _feedNotice(
    String message, {
    required String action,
    required VoidCallback onTap,
    IconData icon = Icons.forum_outlined,
  });

  @override
  void initState() {
    super.initState();
    _profileChangeListener = () => _loadProfile();
    kaisaAccountRefresh.addListener(_profileChangeListener);
    _loadProfile();
    _load();
    _loadStories();
    _storyTicker = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _loadStories(),
    );
  }

  @override
  void dispose() {
    _storyTicker?.cancel();
    _searchController.dispose();
    kaisaAccountRefresh.removeListener(_profileChangeListener);
    super.dispose();
  }
}
