import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();

  final _birthDateController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  DateTime? _birthDate;
  String? _selectedGender;
  String? _selectedBarangay;

  final Set<String> _selectedInterests = {};
  final Set<String> _selectedSkills = {};

  bool _isSaving = false;

  final List<String> _genders = [
    'Male',
    'Female',
    'Prefer not to say',
  ];

  final List<String> _barangays = [
    'Barangay 1',
    'Barangay 2',
    'Barangay 3',
    'Barangay 4',
    'Barangay 5',
    'Barangay 6',
    'Barangay 7',
    'Barangay 8',
    'Barangay 9',
    'Barangay 10',
    'Barangay 11',
    'Barangay 12',
    'Barangay 13',
    'Barangay 14',
    'Barangay 15',
    'Barangay 16',
    'Barangay 17',
    'Barangay 18',
    'Barangay 19',
    'Barangay 20',
    'Barangay 21',
    'Barangay 22',
    'Barangay 23',
    'Barangay 24',
    'Barangay 25',
    'Barangay 26',
    'Barangay 27',
    'Barangay 28',
    'Barangay 29',
    'Barangay 30',
    'Barangay 31',
    'Barangay 32',
    'Barangay 33',
    'Barangay 34',
    'Barangay 35',
    'Barangay 36',
    'Barangay 37',
    'Barangay 38',
    'Barangay 39',
    'Barangay 40',
    'Barangay 41',
    'Barangay 42',
    'Barangay 43',
    'Barangay 44',
    'Barangay 45',
    'Barangay 46',
    'Barangay 47',
    'Barangay 48',
    'Barangay 49',
    'Barangay 50',
    'Barangay 51',
    'Barangay 52',
    'Barangay 53',
    'Barangay 54',
    'Barangay 55',
    'Barangay 56',
    'Barangay 57',
    'Barangay 58',
    'Barangay 59',
    'Barangay 60',
    'Barangay 61',
    'Barangay 62',
    'Barangay 63',
    'Barangay 64',
    'Barangay 65',
    'Barangay 66',
    'Barangay 67',
    'Barangay 68',
    'Barangay 69',
    'Barangay 70',
    'Barangay 71',
    'Barangay 72',
    'Barangay 73',
    'Barangay 74',
    'Barangay 75',
    'Barangay 76',
    'Barangay 77',
    'Barangay 78',
    'Barangay 79',
    'Barangay 80',
    'Barangay 81',
    'Barangay 82',
    'Barangay 83',
    'Barangay 84',
  ];

  final List<_ChoiceItem> _interests = const [
    _ChoiceItem(
      label: 'Environment',
      icon: Icons.eco_outlined,
    ),
    _ChoiceItem(
      label: 'Education',
      icon: Icons.school_outlined,
    ),
    _ChoiceItem(
      label: 'Health',
      icon: Icons.favorite_border_rounded,
    ),
    _ChoiceItem(
      label: 'Youth',
      icon: Icons.groups_outlined,
    ),
    _ChoiceItem(
      label: 'Sports',
      icon: Icons.sports_basketball_outlined,
    ),
    _ChoiceItem(
      label: 'Arts & Culture',
      icon: Icons.palette_outlined,
    ),
    _ChoiceItem(
      label: 'Technology',
      icon: Icons.computer_outlined,
    ),
    _ChoiceItem(
      label: 'Community Service',
      icon: Icons.volunteer_activism_outlined,
    ),
    _ChoiceItem(
      label: 'Disaster Preparedness',
      icon: Icons.health_and_safety_outlined,
    ),
    _ChoiceItem(
      label: 'Livelihood',
      icon: Icons.work_outline_rounded,
    ),
  ];

  final List<_ChoiceItem> _skills = const [
    _ChoiceItem(
      label: 'Communication',
      icon: Icons.forum_outlined,
    ),
    _ChoiceItem(
      label: 'Leadership',
      icon: Icons.groups_2_outlined,
    ),
    _ChoiceItem(
      label: 'Graphic Design',
      icon: Icons.design_services_outlined,
    ),
    _ChoiceItem(
      label: 'Photography',
      icon: Icons.camera_alt_outlined,
    ),
    _ChoiceItem(
      label: 'Video Editing',
      icon: Icons.video_camera_back_outlined,
    ),
    _ChoiceItem(
      label: 'Programming',
      icon: Icons.code_rounded,
    ),
    _ChoiceItem(
      label: 'Writing',
      icon: Icons.edit_note_rounded,
    ),
    _ChoiceItem(
      label: 'Public Speaking',
      icon: Icons.mic_none_rounded,
    ),
    _ChoiceItem(
      label: 'Event Management',
      icon: Icons.event_note_outlined,
    ),
    _ChoiceItem(
      label: 'First Aid',
      icon: Icons.medical_services_outlined,
    ),
  ];

  @override
  void dispose() {
    _birthDateController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select your birth date',
    );

    if (selectedDate == null) return;

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
        (today.month == _birthDate!.month &&
            today.day < _birthDate!.day)) {
      age--;
    }

    return age;
  }

  Future<void> _completeProfile() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_birthDate == null) {
      _showMessage('Please select your birth date.');
      return;
    }

    if (_selectedGender == null) {
      _showMessage('Please select your gender.');
      return;
    }

    if (_selectedBarangay == null) {
      _showMessage('Please select your barangay.');
      return;
    }

    if (_selectedInterests.isEmpty) {
      _showMessage(
        'Choose at least one community interest.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // ==========================================================
    // PROTOTYPE ONLY
    //
    // Later:
    // Save resident profile to Supabase.
    // The authenticated user will now have a Tier 1 / Basic
    // Resident profile.
    // ==========================================================

    await Future.delayed(
      const Duration(milliseconds: 900),
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    _showProfileCompleteDialog();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
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
              color: AppColors.greenLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_pin_circle_outlined,
              color: AppColors.greenDark,
              size: 37,
            ),
          ),
          title: const Text(
            'You\'re all set!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            age != null
                ? 'Your KAISA Basic Resident profile has been created. '
                    'You are currently $age years old and can now start '
                    'exploring your community.'
                : 'Your KAISA Basic Resident profile has been created. '
                    'You can now start exploring your community.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.go('/resident/home');
              },
              icon: const Icon(
                Icons.home_outlined,
              ),
              label: const Text(
                'Enter KAISA',
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 900;

            if (desktop) {
              return _buildDesktop();
            }

            return _buildMobile();
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // MOBILE
  // ===========================================================================

  Widget _buildMobile() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        14,
        20,
        32,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 560,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _buildTopBar(),

                const SizedBox(height: 30),

                _buildHeading(),

                const SizedBox(height: 28),

                _buildPersonalInformation(),

                const SizedBox(height: 20),

                _buildLocationInformation(),

                const SizedBox(height: 20),

                _buildInterests(),

                const SizedBox(height: 20),

                _buildSkills(),

                const SizedBox(height: 24),

                _buildTierNotice(),

                const SizedBox(height: 24),

                _buildCompleteButton(),

                const SizedBox(height: 24),

                _buildProgress(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // DESKTOP
  // ===========================================================================

  Widget _buildDesktop() {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: _buildDesktopSidePanel(),
        ),

        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 60,
              vertical: 30,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 760,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(),

                      const SizedBox(height: 30),

                      _buildHeading(),

                      const SizedBox(height: 28),

                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child:
                                _buildPersonalInformation(),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child:
                                _buildLocationInformation(),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      _buildInterests(),

                      const SizedBox(height: 20),

                      _buildSkills(),

                      const SizedBox(height: 24),

                      _buildTierNotice(),

                      const SizedBox(height: 24),

                      _buildCompleteButton(),

                      const SizedBox(height: 24),

                      _buildProgress(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TOP BAR
  // ===========================================================================

  Widget _buildTopBar() {
    return Row(
      children: [
        InkWell(
          onTap: () {
            context.go('/verification');
          },
          borderRadius: BorderRadius.circular(13),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ),

        const Spacer(),

        Container(
          width: 43,
          height: 43,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Image.asset(
            'assets/images/kaisa_logo.png',
            fit: BoxFit.contain,
          ),
        ),

        const SizedBox(width: 9),

        const Text(
          'KAISA',
          style: TextStyle(
            color: AppColors.blueDark,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // HEADING
  // ===========================================================================

  Widget _buildHeading() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: AppColors.greenLight,
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_add_alt_1_rounded,
                size: 15,
                color: AppColors.greenDark,
              ),
              SizedBox(width: 6),
              Text(
                'ALMOST THERE',
                style: TextStyle(
                  color: AppColors.greenDark,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .6,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        const Text(
          'Tell us about yourself.',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 31,
            fontWeight: FontWeight.w900,
            letterSpacing: -.7,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Complete your resident profile so KAISA can show '
          'community opportunities relevant to you.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.55,
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
      subtitle:
          'A little more information about you.',
      child: Column(
        children: [
          TextFormField(
            controller: _birthDateController,
            readOnly: true,
            onTap: _selectBirthDate,
            decoration: InputDecoration(
              labelText: 'Birth Date',
              hintText: 'MM/DD/YYYY',
              prefixIcon:
                  const Icon(Icons.cake_outlined),
              suffixIcon: IconButton(
                onPressed: _selectBirthDate,
                icon: const Icon(
                  Icons.calendar_month_outlined,
                ),
              ),
            ),
            validator: (_) {
              if (_birthDate == null) {
                return 'Birth date is required.';
              }

              return null;
            },
          ),

          const SizedBox(height: 14),

          DropdownButtonFormField<String>(
            value: _selectedGender,
            decoration: const InputDecoration(
              labelText: 'Gender',
              prefixIcon:
                  Icon(Icons.person_outline_rounded),
            ),
            hint: const Text(
              'Select gender',
            ),
            items: _genders.map((gender) {
              return DropdownMenuItem(
                value: gender,
                child: Text(gender),
              );
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

          const SizedBox(height: 14),

          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            decoration: const InputDecoration(
              labelText: 'Mobile Number',
              hintText: '09XXXXXXXXX',
              prefixIcon:
                  Icon(Icons.phone_outlined),
            ),
            validator: (value) {
              final phone = value?.trim() ?? '';

              if (phone.isEmpty) {
                return 'Mobile number is required.';
              }

              if (!RegExp(r'^09\d{9}$')
                  .hasMatch(phone)) {
                return 'Enter a valid 11-digit mobile number.';
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
      subtitle:
          'Help us connect you with nearby opportunities.',
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _selectedBarangay,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Barangay',
              prefixIcon:
                  Icon(Icons.location_city_outlined),
            ),
            hint: const Text(
              'Select your barangay',
            ),
            items: _barangays.map((barangay) {
              return DropdownMenuItem(
                value: barangay,
                child: Text(barangay),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedBarangay = value;
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Please select your barangay.';
              }

              return null;
            },
          ),

          const SizedBox(height: 14),

          TextFormField(
            controller: _addressController,
            textCapitalization:
                TextCapitalization.words,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Street / Address',
              hintText:
                  'House no., street, subdivision',
              prefixIcon:
                  Icon(Icons.home_outlined),
              alignLabelWithHint: true,
            ),
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Address is required.';
              }

              return null;
            },
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 18,
                  color: AppColors.blue,
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'City: Cavite City, Cavite',
                    style: TextStyle(
                      color:
                          AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
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
  // INTERESTS
  // ===========================================================================

  Widget _buildInterests() {
    return _ProfileCard(
      icon: Icons.interests_outlined,
      title: 'Community Interests',
      subtitle:
          'Select at least one. We\'ll use these to personalize your feed.',
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: _interests.map((interest) {
              final selected =
                  _selectedInterests
                      .contains(interest.label);

              return _SelectableChip(
                item: interest,
                selected: selected,
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedInterests
                          .remove(interest.label);
                    } else {
                      _selectedInterests
                          .add(interest.label);
                    }
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 13),

          Row(
            children: [
              Icon(
                _selectedInterests.isEmpty
                    ? Icons.info_outline_rounded
                    : Icons.check_circle_outline_rounded,
                size: 15,
                color: _selectedInterests.isEmpty
                    ? AppColors.textMuted
                    : AppColors.greenDark,
              ),
              const SizedBox(width: 6),
              Text(
                _selectedInterests.isEmpty
                    ? 'Choose at least one interest'
                    : '${_selectedInterests.length} selected',
                style: TextStyle(
                  color: _selectedInterests.isEmpty
                      ? AppColors.textMuted
                      : AppColors.greenDark,
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
      subtitle:
          'Optional — tell organizations what you can contribute.',
      child: Wrap(
        spacing: 9,
        runSpacing: 9,
        children: _skills.map((skill) {
          final selected =
              _selectedSkills.contains(skill.label);

          return _SelectableChip(
            item: skill,
            selected: selected,
            onTap: () {
              setState(() {
                if (selected) {
                  _selectedSkills
                      .remove(skill.label);
                } else {
                  _selectedSkills
                      .add(skill.label);
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
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.blueLight,
            AppColors.greenLight
                .withValues(alpha: .65),
          ],
        ),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppColors.blue
              .withValues(alpha: .12),
        ),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: AppColors.blueDark,
            size: 24,
          ),

          SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Basic Resident Account',
                  style: TextStyle(
                    color: AppColors.blueDark,
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
                    color: AppColors.textSecondary,
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
        onPressed:
            _isSaving ? null : _completeProfile,
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
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Text(
                    'Complete Profile',
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 19,
                  ),
                ],
              ),
      ),
    );
  }

  // ===========================================================================
  // PROGRESS
  // ===========================================================================

  Widget _buildProgress() {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(),
            ),
            Padding(
              padding:
                  EdgeInsets.symmetric(
                horizontal: 12,
              ),
              child: Text(
                'STEP 3 OF 3',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .7,
                ),
              ),
            ),
            Expanded(
              child: Divider(),
            ),
          ],
        ),

        SizedBox(height: 11),

        Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            _ProgressDot(completed: true),
            SizedBox(width: 7),
            _ProgressDot(completed: true),
            SizedBox(width: 7),
            _ProgressDot(active: true),
          ],
        ),

        SizedBox(height: 14),

        Text(
          'Account  •  Verification  •  Profile',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // DESKTOP SIDE PANEL
  // ===========================================================================

  Widget _buildDesktopSidePanel() {
    return Container(
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.blueDark,
            AppColors.blue,
            AppColors.greenDark,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -110,
            right: -100,
            child: Container(
              width: 310,
              height: 310,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white
                    .withValues(alpha: .05),
              ),
            ),
          ),

          Positioned(
            bottom: -140,
            left: -120,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white
                    .withValues(alpha: .05),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(55),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      padding:
                          const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(18),
                      ),
                      child: Image.asset(
                        'assets/images/kaisa_logo.png',
                      ),
                    ),

                    const SizedBox(width: 14),

                    const Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KAISA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight:
                                FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          'Community Engagement Platform',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const Spacer(),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.yellow,
                    borderRadius:
                        BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'FINAL STEP',
                    style: TextStyle(
                      color: AppColors.blueDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .8,
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                const Text(
                  'Your community.\nYour interests.\nYour impact.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 43,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'A complete profile helps KAISA connect you '
                  'with programs and opportunities that match '
                  'what you care about.',
                  style: TextStyle(
                    color: Color(0xFFE3ECF7),
                    fontSize: 15,
                    height: 1.65,
                  ),
                ),

                const SizedBox(height: 34),

                const _SideFeature(
                  icon: Icons.explore_outlined,
                  text:
                      'Personalized opportunities',
                ),

                const SizedBox(height: 17),

                const _SideFeature(
                  icon: Icons.groups_outlined,
                  text:
                      'Relevant organizations',
                ),

                const SizedBox(height: 17),

                const _SideFeature(
                  icon: Icons.location_on_outlined,
                  text:
                      'Local community programs',
                ),

                const Spacer(),

                const Text(
                  'Connect • Participate • Impact',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  const _ProfileCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: AppColors.border,
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
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.blueLight,
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: AppColors.blue,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color:
                            AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color:
                            AppColors.textMuted,
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

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
          duration:
              const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.blueLight
                : AppColors.surfaceSoft,
            borderRadius:
                BorderRadius.circular(30),
            border: Border.all(
              color: selected
                  ? AppColors.blue
                  : AppColors.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : item.icon,
                size: 16,
                color: selected
                    ? AppColors.blue
                    : AppColors.textSecondary,
              ),

              const SizedBox(width: 6),

              Text(
                item.label,
                style: TextStyle(
                  color: selected
                      ? AppColors.blueDark
                      : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: selected
                      ? FontWeight.w800
                      : FontWeight.w600,
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
// SIDE FEATURE
// =============================================================================

class _SideFeature extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SideFeature({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color:
                Colors.white.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            size: 19,
            color: AppColors.yellow,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// PROGRESS DOT
// =============================================================================

class _ProgressDot extends StatelessWidget {
  final bool active;
  final bool completed;

  const _ProgressDot({
    this.active = false,
    this.completed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active || completed ? 24 : 7,
      height: 7,
      decoration: BoxDecoration(
        color: completed
            ? AppColors.green
            : active
                ? AppColors.blue
                : AppColors.border,
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

  const _ChoiceItem({
    required this.label,
    required this.icon,
  });
}