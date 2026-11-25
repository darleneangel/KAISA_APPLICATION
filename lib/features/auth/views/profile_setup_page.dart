import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();

  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _zipController = TextEditingController();
  final _barangayOtherController = TextEditingController();

  DateTime? _birthDate;
  String? _selectedGender;
  String? _selectedBarangay;
  String? _selectedCity;
  String _selectedProvince = 'Cavite';

  final Set<String> _selectedInterests = {};
  final Set<String> _selectedSkills = {};

  bool _isSaving = false;
  bool _loadingProfile = true;
  bool _loadFailed = false;
  bool _attempted = false;
  bool _leaving = false;
  final _scroll = ScrollController();
  String get _localPhone => '0${_phoneController.text.trim()}';
  bool get _locked => _isSaving || _loadingProfile || _loadFailed || _leaving;

  final List<String> _genders = ['Male', 'Female', 'Prefer not to say'];

  // Phase 1: Cavite localities. Extend the province/city catalogs later.
  static const Map<String, String> _cavitePostalCodes = {
    'Alfonso': '4123',
    'Amadeo': '4119',
    'Bacoor': '4102',
    'Carmona': '4116',
    'Cavite City': '4100',
    'Dasmariñas': '4114',
    'General Emilio Aguinaldo': '4124',
    'General Mariano Alvarez': '4117',
    'General Trias': '4107',
    'Imus': '4103',
    'Indang': '4122',
    'Kawit': '4104',
    'Magallanes': '4113',
    'Maragondon': '4112',
    'Mendez': '4121',
    'Naic': '4110',
    'Noveleta': '4105',
    'Rosario': '4106',
    'Silang': '4118',
    'Tagaytay': '4120',
    'Tanza': '4108',
    'Ternate': '4111',
    'Trece Martires': '4109',
  };

  // The existing Barangay 1–84 options apply only to Cavite City.
  final List<String> _caviteCityBarangays = List.generate(
    84,
    (index) => 'Barangay ${index + 1}',
  );

  String get _barangayValue => _selectedCity == 'Cavite City'
      ? (_selectedBarangay ?? '')
      : _barangayOtherController.text.trim();

  final List<_ChoiceItem> _interests = const [
    _ChoiceItem(label: 'Environment', icon: Icons.eco_outlined),
    _ChoiceItem(label: 'Education', icon: Icons.school_outlined),
    _ChoiceItem(label: 'Health', icon: Icons.favorite_border_rounded),
    _ChoiceItem(label: 'Youth', icon: Icons.groups_outlined),
    _ChoiceItem(label: 'Sports', icon: Icons.sports_basketball_outlined),
    _ChoiceItem(label: 'Arts & Culture', icon: Icons.palette_outlined),
    _ChoiceItem(label: 'Technology', icon: Icons.computer_outlined),
    _ChoiceItem(
      label: 'Community Service',
      icon: Icons.volunteer_activism_outlined,
    ),
    _ChoiceItem(
      label: 'Disaster Preparedness',
      icon: Icons.health_and_safety_outlined,
    ),
    _ChoiceItem(label: 'Livelihood', icon: Icons.work_outline_rounded),
  ];

  final List<_ChoiceItem> _skills = const [
    _ChoiceItem(label: 'Communication', icon: Icons.forum_outlined),
    _ChoiceItem(label: 'Leadership', icon: Icons.groups_2_outlined),
    _ChoiceItem(label: 'Graphic Design', icon: Icons.design_services_outlined),
    _ChoiceItem(label: 'Photography', icon: Icons.camera_alt_outlined),
    _ChoiceItem(label: 'Video Editing', icon: Icons.video_camera_back_outlined),
    _ChoiceItem(label: 'Programming', icon: Icons.code_rounded),
    _ChoiceItem(label: 'Writing', icon: Icons.edit_note_rounded),
    _ChoiceItem(label: 'Public Speaking', icon: Icons.mic_none_rounded),
    _ChoiceItem(label: 'Event Management', icon: Icons.event_note_outlined),
    _ChoiceItem(label: 'First Aid', icon: Icons.medical_services_outlined),
  ];

  // Documented civic milestones. Keep each image and caption together.
  static const _slides = <_AchievementSlide>[
    _AchievementSlide(
      'assets/images/cavite/unlad_pier.jpg',
      'https://thecaviterising.com/wp-content/uploads/2023/09/Photo-1-Article-180-091623.png',
      'Unlad Pier opens to the public',
      'Binuksan sa publiko ang Unlad Pier',
      'A waterfront facility supporting local transport and tourism.',
      'Pasilidad sa baybayin para sa transportasyon at turismo.',
      'INFRASTRUCTURE • SEP 2023',
      'The Cavite Rising',
    ),
    _AchievementSlide(
      'assets/images/cavite/corregidor_2025.jpg',
      'https://thecaviterising.com/wp-content/uploads/2025/06/Photo-8-Article-143-060625.jpg',
      'Corregidor tours launched',
      'Inilunsad ang Corregidor tours',
      'The City Tourism Office launched group tours from Unlad Pier.',
      'Inilunsad ng City Tourism Office ang group tours mula sa Unlad Pier.',
      'TOURISM • JUN 2025',
      'The Cavite Rising',
    ),
    _AchievementSlide(
      'assets/images/cavite/regada_foam_2025.jpg',
      'https://media.assettype.com/tribune%2F2025-07-20%2Fq9frrgh4%2FRevelers-enjoying-a-foam-party-Photo-by-Roel-Hoang-Manipon.jpg',
      'Regada community celebration',
      'Pagdiriwang ng Regada',
      'Residents celebrate together at the Regada foam party.',
      'Sama-samang nagdiriwang ang mga residente sa Regada.',
      'COMMUNITY • JUN 2025',
      'Roel Hoang Manipon / Daily Tribune',
    ),
    _AchievementSlide(
      'assets/images/cavite/regada_2025.jpg',
      'https://media.assettype.com/tribune%2F2025-07-20%2Fg6tgw5si%2FFirefighters-drenching-attendees-with-cool-water-Photo-by-Roel-Hoang-Manipon.jpg',
      'Regada Water Festival',
      'Pista ng Regada',
      'The city celebrated local culture through festivities and community activities.',
      'Ipinagdiwang ng lungsod ang kultura sa pamamagitan ng mga gawaing pangkomunidad.',
      'CULTURE • JUN 2025',
      'Roel Hoang Manipon / Daily Tribune',
    ),
  ];
  Timer? _slideTimer;
  int _activeSlide = 0;
  bool _paused = false;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _scheduleSlides();
  }

  void _scheduleSlides() {
    _slideTimer?.cancel();
    _slideTimer = null;
    if (_paused || _reduceMotion) return;
    _slideTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (mounted)
        setState(() => _activeSlide = (_activeSlide + 1) % _slides.length);
    });
  }

  void _selectSlide(int index) {
    setState(() => _activeSlide = (index + _slides.length) % _slides.length);
    _scheduleSlides();
  }

  @override
  void initState() {
    super.initState();
    final data = Supabase.instance.client.auth.currentUser?.userMetadata;
    _lastNameController.text = (data?['last_name'] ?? '').toString();
    _firstNameController.text = (data?['first_name'] ?? '').toString();
    _middleNameController.text = (data?['middle_name'] ?? '').toString();
    // Retain legacy name metadata as a reference, but don't guess its parts.
    if (_firstNameController.text.isEmpty && data?['full_name'] != null) {
      debugPrint('KAISA: Previous full_name exists; ask user for name parts.');
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    if (mounted)
      setState(() {
        _loadingProfile = true;
        _loadFailed = false;
      });
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      if (mounted) context.go('/login');
      return;
    }
    try {
      final row = await client
          .from('resident_profiles')
          .select(
            'user_id,last_name,first_name,middle_name,birth_date,gender,mobile_number,province,city_municipality,barangay,street_address,zip_code,interests,skills,profile_completed',
          )
          .eq('user_id', user.id)
          .maybeSingle();
      if (!mounted || _leaving || client.auth.currentUser?.id != user.id)
        return;
      if (row != null && row['profile_completed'] == true) {
        // Repair the old router's onboarding metadata if necessary, not privileges.
        if (user.userMetadata?['profile_completed'] != true) {
          await client.auth.updateUser(
            UserAttributes(data: {'profile_completed': true}),
          );
        }
        if (mounted && client.auth.currentUser?.id == user.id)
          context.go('/resident/home');
        return;
      }
      if (row != null) {
        String val(String key) => (row[key] ?? '').toString();
        _lastNameController.text = val('last_name');
        _firstNameController.text = val('first_name');
        _middleNameController.text = val('middle_name');
        final date = DateTime.tryParse(val('birth_date'));
        if (date != null &&
            !date.isBefore(DateTime(1900)) &&
            !date.isAfter(DateTime.now())) {
          _birthDate = date;
          _birthDateController.text =
              '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
        }
        _selectedGender = _genders.contains(val('gender'))
            ? val('gender')
            : null;
        var phone = val('mobile_number').replaceAll(RegExp(r'[^0-9]'), '');
        if (phone.startsWith('63') && phone.length == 12)
          phone = phone.substring(2);
        if (phone.startsWith('0')) phone = phone.substring(1);
        _phoneController.text = phone;
        _selectedCity = _cavitePostalCodes.containsKey(val('city_municipality'))
            ? val('city_municipality')
            : null;
        if (_selectedCity == 'Cavite City') {
          _selectedBarangay = _caviteCityBarangays.contains(val('barangay'))
              ? val('barangay')
              : null;
        } else {
          _barangayOtherController.text = val('barangay');
        }
        _addressController.text = val('street_address');
        _zipController.text = val('zip_code');
        if (row['interests'] is List)
          _selectedInterests.addAll(
            (row['interests'] as List).whereType<String>(),
          );
        if (row['skills'] is List)
          _selectedSkills.addAll((row['skills'] as List).whereType<String>());
      }
      if (mounted) setState(() => _loadingProfile = false);
    } catch (error) {
      debugPrint('KAISA profile load failed: ${error.runtimeType}');
      if (mounted)
        setState(() {
          _loadingProfile = false;
          _loadFailed = true;
        });
    }
  }

  Future<void> _backToLogin() async {
    if (_isSaving || _leaving) return;
    setState(() => _leaving = true);
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) context.go('/login');
    } catch (_) {
      if (mounted) {
        setState(() => _leaving = false);
        _showMessage('Could not sign out. Please try again.');
      }
    }
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _scroll.dispose();
    _lastNameController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _zipController.dispose();
    _barangayOtherController.dispose();
    _birthDateController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 18),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select your birth date',
    );

    if (selectedDate == null || !mounted) return;

    setState(() {
      _birthDate = selectedDate;

      _birthDateController.text =
          '${selectedDate.month.toString().padLeft(2, '0')}/'
          '${selectedDate.day.toString().padLeft(2, '0')}/'
          '${selectedDate.year}';
    });
  }

  int? _calculateAge() {
    if (_birthDate == null) return null;

    final today = DateTime.now();
    int age = today.year - _birthDate!.year;

    if (today.month < _birthDate!.month ||
        (today.month == _birthDate!.month && today.day < _birthDate!.day)) {
      age--;
    }

    return age;
  }

  Future<void> _completeProfile() async {
    if (_locked) return;
    FocusScope.of(context).unfocus();
    setState(() => _attempted = true);
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid || _selectedInterests.isEmpty) {
      _showMessage(
        'Please complete all required fields and choose at least one interest.',
      );
      if (_scroll.hasClients)
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      return;
    }

    if (_birthDate == null) {
      _showMessage('Please select your birth date.');
      return;
    }

    if (_selectedGender == null) {
      _showMessage('Please select your gender.');
      return;
    }

    if (_barangayValue.isEmpty) {
      _showMessage('Please provide your barangay.');
      return;
    }

    if (_selectedCity == null) {
      _showMessage('Please select your city or municipality.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage('Please sign in before completing your profile.');
      return;
    }

    final last = _lastNameController.text.trim();
    final first = _firstNameController.text.trim();
    final middle = _middleNameController.text.trim();
    final fullName = [
      first,
      middle,
      last,
    ].where((part) => part.isNotEmpty).join(' ');
    final birthDate = _birthDate!.toIso8601String().split('T').first;

    try {
      // Persist to the dedicated resident table, secured with Supabase RLS.
      final client = Supabase.instance.client;
      final values = <String, dynamic>{
        'user_id': user.id,
        'last_name': last,
        'first_name': first,
        'middle_name': middle.isEmpty ? null : middle,
        'full_name': fullName,
        'birth_date': birthDate,
        'gender': _selectedGender,
        'mobile_number': _localPhone,
        'province': _selectedProvince,
        'city_municipality': _selectedCity,
        'barangay': _barangayValue,
        'street_address': _addressController.text.trim(),
        'zip_code': _zipController.text.trim(),
        'interests': _selectedInterests.toList(),
        'skills': _selectedSkills.toList(),
        'profile_completed': true,
      };
      // Never reset a verified resident's tier on an existing row.
      // Use insert for new records; a concurrent duplicate fails safely.
      final existing = await client
          .from('resident_profiles')
          .select('profile_completed')
          .eq('user_id', user.id)
          .maybeSingle();
      if (!mounted || client.auth.currentUser?.id != user.id) return;
      if (existing == null) {
        await client
            .from('resident_profiles')
            .insert({...values, 'resident_tier': 1})
            .select('user_id')
            .single();
      } else if (existing['profile_completed'] != true) {
        final changes = Map<String, dynamic>.of(values)..remove('user_id');
        final query = client
            .from('resident_profiles')
            .update(changes)
            .eq('user_id', user.id);
        if (existing['profile_completed'] == false) {
          await query.eq('profile_completed', false).select('user_id').single();
        } else {
          await query
              .isFilter('profile_completed', null)
              .select('user_id')
              .single();
        }
      }
      if (!mounted || _leaving || client.auth.currentUser?.id != user.id)
        return;
      if (existing?['profile_completed'] == true) {
        await client.auth.updateUser(
          UserAttributes(data: {'profile_completed': true}),
        );
        if (mounted) context.go('/resident/home');
        return;
      }

      // Keep the current router's metadata-based completion check working.
      // This metadata is NOT an authorization source for privileged access.
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {
            ...?user.userMetadata,
            'last_name': last,
            'first_name': first,
            'middle_name': middle,
            'full_name': fullName,
            'birth_date': birthDate,
            'gender': _selectedGender,
            'mobile_number': _localPhone,
            'province': _selectedProvince,
            'city_municipality': _selectedCity,
            'barangay': _barangayValue,
            'street_address': _addressController.text.trim(),
            'zip_code': _zipController.text.trim(),
            'interests': _selectedInterests.toList(),
            'skills': _selectedSkills.toList(),
            'profile_completed': true,
          },
        ),
      );
    } catch (error) {
      debugPrint('KAISA profile save failed: ${error.runtimeType}');
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage('Could not save your profile. Please try again.');
      return;
    }

    if (!mounted || Supabase.instance.client.auth.currentUser?.id != user.id)
      return;
    setState(() => _isSaving = false);

    _showProfileCompleteDialog();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showProfileCompleteDialog() {
    final age = _calculateAge();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: const Color(0xFFEAF5ED),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_pin_circle_outlined,
              color: _CivicColors.green,
              size: 37,
            ),
          ),
          title: const Text(
            'You\'re all set!',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w900),
          ),
          content: Text(
            age != null
                ? 'Your KAISA resident profile is complete. '
                      'You are currently $age years old and can now start '
                      'exploring your community.'
                : 'Your KAISA resident profile is complete. '
                      'You can now start exploring your community.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _CivicColors.muted, height: 1.5),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.go('/resident/home');
              },
              icon: const Icon(Icons.home_outlined),
              label: const Text('Enter KAISA'),
            ),
          ],
        );
      },
    );
  }

  Widget _background() {
    final slide = _slides[_activeSlide % _slides.length];
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: _CivicColors.dark),
            AnimatedSwitcher(
              duration: _reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 450),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              layoutBuilder: (current, previous) => Stack(
                fit: StackFit.expand,
                children: [...previous, if (current != null) current],
              ),
              child: SizedBox.expand(
                key: ValueKey(slide.asset),
                child: Image.asset(
                  slide.asset,
                  filterQuality: FilterQuality.high,
                  fit: slide.contain ? BoxFit.contain : BoxFit.cover,
                  errorBuilder: (_, __, ___) => Image.network(
                    slide.url,
                    filterQuality: FilterQuality.high,
                    fit: slide.contain ? BoxFit.contain : BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const ColoredBox(color: _CivicColors.dark),
                  ),
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xA6002115),
                    Color(0x5500301B),
                    Color(0xC6002818),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dots() => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      for (var i = 0; i < _slides.length; i++)
        IconButton(
          tooltip: _slides[i].title,
          onPressed: () => _selectSlide(i),
          icon: Icon(
            Icons.circle,
            size: _activeSlide == i ? 13 : 8,
            color: _activeSlide == i ? _CivicColors.gold : Colors.white54,
          ),
        ),
      IconButton(
        tooltip: _paused ? 'Resume slideshow' : 'Pause slideshow',
        onPressed: _reduceMotion
            ? null
            : () {
                setState(() => _paused = !_paused);
                _scheduleSlides();
              },
        color: Colors.white,
        icon: Icon(_paused ? Icons.play_arrow_rounded : Icons.pause_rounded),
      ),
    ],
  );

  Widget _buildHeader({required bool isMobile, required bool smallPhone}) =>
      Row(
        children: [
          IconButton(
            tooltip: 'Back to login',
            onPressed: _isSaving || _leaving ? null : _backToLogin,
            color: Colors.white,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Image.asset(
            'assets/images/kaisa_logo.png',
            width: isMobile ? 30 : 34,
            height: isMobile ? 30 : 34,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.groups_rounded,
              color: _CivicColors.gold,
              size: 36,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KAISA',
                  style: GoogleFonts.outfit(
                    fontSize: isMobile ? 19 : 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                if (!smallPhone)
                  Text(
                    'LUNGSOD NG CAVITE',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      letterSpacing: 1,
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
          ),
          if (!isMobile) _dots(),
        ],
      );

  Widget _buildFooter({required bool isMobile}) {
    final slide = _slides[_activeSlide % _slides.length];
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        const Icon(Icons.circle, color: _CivicColors.gold, size: 9),
        Text(
          slide.title,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        Text(
          slide.credit,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final light = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(seedColor: _CivicColors.green),
    );
    OutlineInputBorder outline(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: color, width: width),
        );
    final theme = light.copyWith(
      textTheme: Theme.of(context).textTheme
          .apply(fontFamily: GoogleFonts.inter().fontFamily)
          .copyWith(
            headlineLarge: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
            headlineMedium: GoogleFonts.outfit(
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
            titleMedium: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            bodyLarge: GoogleFonts.inter(fontSize: 13),
            bodyMedium: GoogleFonts.inter(fontSize: 12),
            bodySmall: GoogleFonts.inter(fontSize: 11),
            labelLarge: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
      platform: Theme.of(context).platform,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _CivicColors.input,
        isDense: true,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        labelStyle: GoogleFonts.inter(fontSize: 12),
        errorStyle: GoogleFonts.inter(
          fontSize: 11,
          color: const Color(0xFFB42318),
        ),
        errorMaxLines: 3,
        border: outline(_CivicColors.border),
        enabledBorder: outline(_CivicColors.border),
        focusedBorder: outline(_CivicColors.green, 1.8),
        errorBorder: outline(const Color(0xFFB42318), 1.5),
        focusedErrorBorder: outline(const Color(0xFFB42318), 2),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _CivicColors.forest,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(44),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: _CivicColors.dark,
        body: Stack(
          children: [
            _background(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final mobile = constraints.maxWidth < 700;
                  final desktop = constraints.maxWidth >= 860;
                  final short = constraints.maxHeight < 420;
                  return Column(
                    children: [
                      if (!short)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: mobile ? 10 : 28,
                            vertical: 4,
                          ),
                          child: _buildHeader(
                            isMobile: mobile,
                            smallPhone: constraints.maxWidth < 390,
                          ),
                        ),
                      if (mobile && !short) _dots(),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _scroll,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.fromLTRB(
                            mobile ? 10 : 20,
                            4,
                            mobile ? 10 : 20,
                            8,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: desktop ? 860 : 440,
                              ),
                              child: Container(
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    mobile ? 14 : 17,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const SizedBox(
                                      height: 4,
                                      child: ColoredBox(
                                        color: _CivicColors.gold,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(mobile ? 10 : 14),
                                      child: _loadingProfile || _leaving
                                          ? const Padding(
                                              padding: EdgeInsets.all(24),
                                              child: Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            )
                                          : _loadFailed
                                          ? Column(
                                              children: [
                                                const Text(
                                                  'Unable to load your profile. Please try again.',
                                                ),
                                                const SizedBox(height: 8),
                                                FilledButton(
                                                  onPressed: _loadProfile,
                                                  child: const Text('Retry'),
                                                ),
                                              ],
                                            )
                                          : Form(
                                              key: _formKey,
                                              autovalidateMode: _attempted
                                                  ? AutovalidateMode.always
                                                  : AutovalidateMode
                                                        .onUserInteraction,
                                              child: AbsorbPointer(
                                                absorbing: _isSaving,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
                                                  children: [
                                                    _buildHeading(),
                                                    const SizedBox(height: 6),
                                                    _buildProgress(),
                                                    const SizedBox(height: 8),
                                                    if (desktop)
                                                      Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Expanded(
                                                            child:
                                                                _buildPersonalInformation(),
                                                          ),
                                                          const SizedBox(
                                                            width: 10,
                                                          ),
                                                          Expanded(
                                                            child:
                                                                _buildLocationInformation(),
                                                          ),
                                                        ],
                                                      )
                                                    else ...[
                                                      _buildPersonalInformation(),
                                                      const SizedBox(height: 8),
                                                      _buildLocationInformation(),
                                                    ],
                                                    const SizedBox(height: 8),
                                                    if (desktop)
                                                      Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Expanded(
                                                            child:
                                                                _buildInterests(),
                                                          ),
                                                          const SizedBox(
                                                            width: 10,
                                                          ),
                                                          Expanded(
                                                            child:
                                                                _buildSkills(),
                                                          ),
                                                        ],
                                                      )
                                                    else ...[
                                                      _buildInterests(),
                                                      const SizedBox(height: 8),
                                                      _buildSkills(),
                                                    ],
                                                    const SizedBox(height: 8),
                                                    _buildTierNotice(),
                                                    const SizedBox(height: 6),
                                                    _buildCompleteButton(),
                                                  ],
                                                ),
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (!short)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                          child: _buildFooter(isMobile: mobile),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF5ED),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_add_alt_1_rounded,
                size: 15,
                color: _CivicColors.green,
              ),
              SizedBox(width: 6),
              Text(
                'ALMOST THERE',
                style: TextStyle(
                  color: _CivicColors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .6,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Tell us about yourself.',
          style: GoogleFonts.outfit(
            color: _CivicColors.ink,
            fontSize: MediaQuery.sizeOf(context).width < 700 ? 21 : 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -.7,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Complete your resident profile to discover relevant community opportunities. Fields marked * are required.',
          style: TextStyle(
            color: _CivicColors.muted,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // PERSONAL INFORMATION
  // ===========================================================================

  Widget _buildPersonalInformation() {
    return _ProfileCard(
      icon: Icons.badge_outlined,
      title: 'Personal Details',
      subtitle: 'A little more information about you.',
      child: Column(
        children: [
          TextFormField(
            controller: _lastNameController,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.familyName],
            decoration: const InputDecoration(
              labelText: 'Last Name *',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            validator: (value) =>
                (value ?? '').trim().isEmpty ? 'Last name is required.' : null,
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _firstNameController,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.givenName],
            decoration: const InputDecoration(
              labelText: 'First Name *',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            validator: (value) =>
                (value ?? '').trim().isEmpty ? 'First name is required.' : null,
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _middleNameController,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.middleName],
            decoration: const InputDecoration(
              labelText: 'Middle Name (optional)',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _birthDateController,
            readOnly: true,
            onTap: _selectBirthDate,
            decoration: InputDecoration(
              labelText: 'Birth Date *',
              hintText: 'MM/DD/YYYY',
              prefixIcon: const Icon(Icons.cake_outlined),
              suffixIcon: IconButton(
                onPressed: _selectBirthDate,
                icon: const Icon(Icons.calendar_month_outlined),
              ),
            ),
            validator: (_) {
              if (_birthDate == null) {
                return 'Birth date is required.';
              }

              return null;
            },
          ),

          const SizedBox(height: 6),

          DropdownButtonFormField<String>(
            initialValue: _selectedGender,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Gender *',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            hint: const Text('Select gender'),
            items: _genders.map((gender) {
              return DropdownMenuItem(value: gender, child: Text(gender));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedGender = value;
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Please select your gender.';
              }

              return null;
            },
          ),

          const SizedBox(height: 6),

          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              TextInputFormatter.withFunction((oldValue, newValue) {
                var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
                if (digits.length == 12 && digits.startsWith('63'))
                  digits = digits.substring(2);
                if (digits.startsWith('0')) digits = digits.substring(1);
                if (digits.length > 10) return oldValue;
                if (digits == newValue.text) return newValue;
                return TextEditingValue(
                  text: digits,
                  selection: TextSelection.collapsed(offset: digits.length),
                );
              }),
            ],
            decoration: InputDecoration(
              labelText: 'Mobile Number *',
              hintText: '9XXXXXXXXX',
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.string(_philippineFlag, width: 24, height: 14),
                    const SizedBox(width: 7),
                    Text(
                      '+63',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: _CivicColors.ink,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 22, color: _CivicColors.border),
                  ],
                ),
              ),
              helperText: '10 digits after +63 (11 in local format).',
              helperMaxLines: 2,
            ),
            validator: (value) {
              final phone = value?.trim() ?? '';

              if (phone.isEmpty) {
                return 'Mobile number is required.';
              }

              if (!RegExp(r'^9\d{9}$').hasMatch(phone)) {
                return 'Enter 10 digits after +63, starting with 9.';
              }

              return null;
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // LOCATION
  // ===========================================================================

  Widget _buildLocationInformation() {
    return _ProfileCard(
      icon: Icons.location_on_outlined,
      title: 'Resident Information',
      subtitle: 'Help us connect you with nearby opportunities.',
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedProvince,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Province *',
              prefixIcon: Icon(Icons.map_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'Cavite', child: Text('Cavite')),
            ],
            onChanged: (value) => setState(() {
              _selectedProvince = value ?? 'Cavite';
              _selectedCity = null;
              _selectedBarangay = null;
              _zipController.clear();
            }),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            key: ValueKey(_selectedProvince),
            initialValue: _selectedCity,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'City / Municipality *',
              prefixIcon: Icon(Icons.location_city_outlined),
            ),
            hint: const Text('Select city or municipality'),
            items: _cavitePostalCodes.keys
                .map((city) => DropdownMenuItem(value: city, child: Text(city)))
                .toList(),
            onChanged: (value) => setState(() {
              _selectedCity = value;
              _selectedBarangay = null;
              _barangayOtherController.clear();
              _zipController.text = _cavitePostalCodes[value] ?? '';
            }),
            validator: (value) =>
                value == null ? 'Select your city or municipality.' : null,
          ),
          const SizedBox(height: 6),
          if (_selectedCity == 'Cavite City') ...[
            DropdownButtonFormField<String>(
              key: const ValueKey('cavite_city_barangays'),
              initialValue: _selectedBarangay,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Barangay *',
                prefixIcon: Icon(Icons.place_outlined),
              ),
              hint: const Text('Select your barangay'),
              items: _caviteCityBarangays
                  .map(
                    (barangay) => DropdownMenuItem(
                      value: barangay,
                      child: Text(barangay),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedBarangay = value),
              validator: (value) => value == null ? 'Select a barangay.' : null,
            ),
          ] else ...[
            TextFormField(
              controller: _barangayOtherController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Barangay *',
                hintText: 'Enter your barangay',
                prefixIcon: Icon(Icons.place_outlined),
              ),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Barangay is required.' : null,
            ),
          ],
          const SizedBox(height: 6),
          TextFormField(
            controller: _addressController,
            textCapitalization: TextCapitalization.words,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Street Address *',
              hintText: 'House no., street, subdivision',
              prefixIcon: Icon(Icons.home_outlined),
              alignLabelWithHint: true,
            ),
            validator: (value) => (value ?? '').trim().isEmpty
                ? 'Street address is required.'
                : null,
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _zipController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            decoration: const InputDecoration(
              labelText: 'ZIP Code *',
              hintText: '4-digit postal code',
              prefixIcon: Icon(Icons.local_post_office_outlined),
            ),
            validator: (value) =>
                RegExp(r'^\d{4}$').hasMatch((value ?? '').trim())
                ? null
                : 'Enter a valid 4-digit ZIP code.',
          ),
          const SizedBox(height: 8),
          const Text(
            'The ZIP code is suggested from your city or municipality. '
            'You may edit it if your postal area uses a different code.',
            style: TextStyle(color: _CivicColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // INTERESTS
  // ===========================================================================

  Widget _buildInterests() {
    return _ProfileCard(
      icon: Icons.interests_outlined,
      title: 'Community Interests *',
      hasError: _attempted && _selectedInterests.isEmpty,
      subtitle:
          'Select at least one. We\'ll use these to personalize your feed.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: _interests.map((interest) {
              final selected = _selectedInterests.contains(interest.label);

              return _SelectableChip(
                item: interest,
                selected: selected,
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedInterests.remove(interest.label);
                    } else {
                      _selectedInterests.add(interest.label);
                    }
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 7),

          Row(
            children: [
              Icon(
                _selectedInterests.isEmpty
                    ? Icons.info_outline_rounded
                    : Icons.check_circle_outline_rounded,
                size: 15,
                color: _selectedInterests.isEmpty
                    ? (_attempted
                          ? const Color(0xFFB42318)
                          : _CivicColors.muted)
                    : _CivicColors.green,
              ),
              const SizedBox(width: 6),
              Text(
                _selectedInterests.isEmpty
                    ? 'Choose at least one interest'
                    : '${_selectedInterests.length} selected',
                style: TextStyle(
                  color: _selectedInterests.isEmpty
                      ? (_attempted
                            ? const Color(0xFFB42318)
                            : _CivicColors.muted)
                      : _CivicColors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SKILLS
  // ===========================================================================

  Widget _buildSkills() {
    return _ProfileCard(
      icon: Icons.auto_awesome_outlined,
      title: 'Skills',
      subtitle: 'Optional — tell organizations what you can contribute.',
      child: Wrap(
        spacing: 5,
        runSpacing: 5,
        children: _skills.map((skill) {
          final selected = _selectedSkills.contains(skill.label);

          return _SelectableChip(
            item: skill,
            selected: selected,
            onTap: () {
              setState(() {
                if (selected) {
                  _selectedSkills.remove(skill.label);
                } else {
                  _selectedSkills.add(skill.label);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  // ===========================================================================
  // BASIC RESIDENT NOTICE
  // ===========================================================================

  Widget _buildTierNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEAF5ED),
            const Color(0xFFEAF5ED).withValues(alpha: .65),
          ],
        ),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _CivicColors.green.withValues(alpha: .12)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: _CivicColors.forest,
            size: 24,
          ),

          SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resident Account',
                  style: TextStyle(
                    color: _CivicColors.forest,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'After completing your profile, you can explore '
                  'community feeds, organizations, events, and '
                  'opportunities. Some participation features will '
                  'require resident verification later.',
                  style: TextStyle(
                    color: _CivicColors.muted,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BUTTON
  // ===========================================================================

  Widget _buildCompleteButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _locked ? null : _completeProfile,
        child: _isSaving
            ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Complete Profile'),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 19),
                ],
              ),
      ),
    );
  }

  // ===========================================================================
  // PROGRESS
  // ===========================================================================

  Widget _buildProgress() {
    return const Wrap(
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        Text(
          'STEP 3 OF 3',
          style: TextStyle(
            color: _CivicColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: .5,
          ),
        ),
        _ProgressDot(completed: true),
        _ProgressDot(completed: true),
        _ProgressDot(active: true),
        Text(
          'Account  •  Verification  •  Profile',
          style: TextStyle(color: _CivicColors.muted, fontSize: 10),
        ),
      ],
    );
  }
}

// =============================================================================
// PROFILE CARD
// =============================================================================

class _ProfileCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final bool hasError;

  const _ProfileCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError ? const Color(0xFFB42318) : _CivicColors.border,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x09000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5ED),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 19, color: _CivicColors.green),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        color: _CivicColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _CivicColors.muted,
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          child,
        ],
      ),
    );
  }
}

// =============================================================================
// SELECTABLE CHIP
// =============================================================================

class _SelectableChip extends StatelessWidget {
  final _ChoiceItem item;
  final bool selected;
  final VoidCallback onTap;

  const _SelectableChip({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEAF5ED) : _CivicColors.input,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: selected ? _CivicColors.green : _CivicColors.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? Icons.check_circle_rounded : item.icon,
                size: 16,
                color: selected ? _CivicColors.green : _CivicColors.muted,
              ),

              const SizedBox(width: 6),

              Text(
                item.label,
                style: TextStyle(
                  color: selected ? _CivicColors.forest : _CivicColors.muted,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// PROGRESS DOT
// =============================================================================

class _ProgressDot extends StatelessWidget {
  final bool active;
  final bool completed;

  const _ProgressDot({this.active = false, this.completed = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active || completed ? 24 : 7,
      height: 7,
      decoration: BoxDecoration(
        color: completed
            ? _CivicColors.green
            : active
            ? _CivicColors.gold
            : _CivicColors.border,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

// =============================================================================
// MODEL
// =============================================================================

class _ChoiceItem {
  final String label;
  final IconData icon;

  const _ChoiceItem({required this.label, required this.icon});
}

class _CivicColors {
  const _CivicColors._();

  static const Color dark = Color(0xFF002818);
  static const Color forest = Color(0xFF00301B);
  static const Color green = Color(0xFF00492C);
  static const Color gold = Color(0xFFFDBC19);
  static const Color ink = Color(0xFF17211B);
  static const Color muted = Color(0xFF65716B);
  static const Color input = Color(0xFFF9F9FF);
  static const Color border = Color(0xFFE2E9E5);
}

class _AchievementSlide {
  const _AchievementSlide(
    this.asset,
    this.url,
    this.title,
    this.titleTl,
    this.description,
    this.descriptionTl,
    this.category,
    this.credit, {
    this.contain = false,
  });
  final String asset,
      url,
      title,
      titleTl,
      description,
      descriptionTl,
      category,
      credit;
  final bool contain;
}

const _philippineFlag =
    """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 90 45"><path fill="#0038A8" d="M0 0h90v22.5H0z"/><path fill="#CE1126" d="M0 22.5h90V45H0z"/><path fill="#fff" d="M0 0l39 22.5L0 45z"/><g fill="#FCD116"><circle cx="14" cy="22.5" r="4"/><path d="M13 13h2v6h-2zm0 13h2v6h-2zM5 21.5h6v2H5zm12 0h6v2h-6zM7 15l1.5-1.5 4 4-1.5 1.5zm9 11 1.5-1.5 4 4-1.5 1.5zM7 30l4-4 1.5 1.5-4 4zm9-11 4-4 1.5 1.5-4 4z"/><path d="M4 5l1 2 2 0-1.5 1.5.5 2-2-1-2 1 .5-2L1 7h2zM4 35l1 2h2l-1.5 1.5.5 2-2-1-2 1 .5-2L1 37h2zM31 19l1 2h2l-1.5 1.5.5 2-2-1-2 1 .5-2L28 21h2z"/></g></svg>""";
