import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/repositories/resident_account_repository.dart';
import '../widgets/auth_ui.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});
  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _form = GlobalKey<FormState>();
  final _account = ResidentAccountRepository.instance;
  final _first = TextEditingController(),
      _middle = TextEditingController(),
      _last = TextEditingController(),
      _phone = TextEditingController(),
      _address = TextEditingController();
  DateTime? _birth;
  String? _gender, _barangay;
  bool _saving = false;
  final _interests = <String>{}, _skills = <String>{};
  static const _interestOptions = [
    'Environment',
    'Education',
    'Health',
    'Youth',
    'Sports',
    'Arts & Culture',
    'Technology',
    'Community Service',
    'Disaster Preparedness',
    'Livelihood',
  ];
  static const _skillOptions = [
    'Communication',
    'Leadership',
    'Graphic Design',
    'Photography',
    'Video Editing',
    'Programming',
    'Writing',
    'Public Speaking',
    'Event Management',
    'First Aid',
  ];
  @override
  void initState() {
    super.initState();
    final name = _account.fullName.trim().split(RegExp(r'\s+'));
    if (_account.fullName.trim().isNotEmpty) {
      _first.text = name.first;
      if (name.length >= 2) _last.text = name.last;
      if (name.length > 2)
        _middle.text = name.sublist(1, name.length - 1).join(' ');
    }
    _phone.text = _account.phone;
    _address.text = _account.address;
    _barangay = _account.barangay.isEmpty ? null : _account.barangay;
    _birth = _account.birthDate;
  }

  @override
  void dispose() {
    for (final c in [_first, _middle, _last, _phone, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final value = await showDatePicker(
      context: context,
      initialDate: _birth ?? DateTime(now.year - 18),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (value != null) setState(() => _birth = value);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_birth == null || _barangay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select your birth date and barangay.')),
      );
      return;
    }
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    _account.saveProfile(
      fullName: [
        _first.text.trim(),
        if (_middle.text.trim().isNotEmpty) _middle.text.trim(),
        _last.text.trim(),
      ].join(' '),
      phone: _phone.text.trim(),
      address: _address.text.trim(),
      barangay: _barangay!,
      birthDate: _birth!,
    );
    setState(() => _saving = false);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialog) => AlertDialog(
        title: const Text('Welcome to KAISA!'),
        content: const Text(
          'Your basic resident profile has been saved. You can explore the community now.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(dialog);
              context.go('/resident/home');
            },
            child: const Text('Explore KAISA'),
          ),
        ],
      ),
    );
  }

  Widget _choiceSet(String title, List<String> values, Set<String> selection) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF163E2C),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values
              .map(
                (value) => FilterChip(
                  label: Text(value),
                  selected: selection.contains(value),
                  onSelected: (on) => setState(() {
                    if (on) {
                      selection.add(value);
                    } else {
                      selection.remove(value);
                    }
                  }),
                  selectedColor: const Color(0xFFE0F2D0),
                  checkmarkColor: AppColors.forest,
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => AuthResponsivePage(
    showBack: true,
    backRoute: '/verification',
    hero: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthTag(
          label: 'Create your profile',
          icon: Icons.person_pin_circle_outlined,
        ),
        SizedBox(height: 26),
        Text(
          'Show up.\nStand out.\nBelong.',
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.07,
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Tell us a little about yourself to discover communities and opportunities that feel right for you.',
          style: TextStyle(
            color: Color(0xFFE1F2E8),
            fontSize: 15,
            height: 1.65,
          ),
        ),
        SizedBox(height: 28),
        AuthScenicArtwork(),
        SizedBox(height: 14),
        AuthInfoCard(
          title: 'One community, many interests',
          subtitle:
              'Build your resident profile and discover causes, groups, and events you care about.',
          icon: Icons.groups_2_rounded,
        ),
      ],
    ),
    panel: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Make KAISA yours.',
            style: TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.w800,
              color: Color(0xFF163E2C),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Basic resident information',
            style: TextStyle(color: Color(0xFF68786E), fontSize: 14),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _first,
            decoration: const InputDecoration(
              labelText: 'First name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _middle,
            decoration: const InputDecoration(
              labelText: 'Middle name (optional)',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _last,
            decoration: const InputDecoration(labelText: 'Last name'),
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _gender,
            decoration: const InputDecoration(labelText: 'Gender'),
            items: const [
              'Male',
              'Female',
              'Prefer not to say',
            ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setState(() => _gender = v),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date of birth',
                prefixIcon: Icon(Icons.calendar_month_outlined),
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
              child: Text(
                _birth == null
                    ? 'Choose a date'
                    : '${_birth!.month}/${_birth!.day}/${_birth!.year}',
                style: const TextStyle(color: Color(0xFF163E2C)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Contact number',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            validator: (s) => s == null || s.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _address,
            decoration: const InputDecoration(
              labelText: 'Street / complete address',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            validator: (s) => s == null || s.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _barangay,
            decoration: const InputDecoration(labelText: 'Barangay'),
            isExpanded: true,
            items: List.generate(84, (i) {
              final s = 'Barangay ${i + 1}';
              return DropdownMenuItem(value: s, child: Text(s));
            }),
            onChanged: (v) => setState(() => _barangay = v),
          ),
          const SizedBox(height: 26),
          _choiceSet('Your interests', _interestOptions, _interests),
          const SizedBox(height: 24),
          _choiceSet('Your skills', _skillOptions, _skills),
          const SizedBox(height: 24),
          const Text(
            'Your account starts at Tier 1. Identity verification is required for restricted participation features.',
            style: TextStyle(
              color: Color(0xFF68786E),
              fontSize: 12,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: Text(_saving ? 'Saving...' : 'Complete profile'),
            ),
          ),
        ],
      ),
    ),
  );
}
