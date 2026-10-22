import '../../../core/theme/kaisa_backdrop.dart';
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/repositories/resident_account_repository.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _hidePassword = true;
  bool _agreedToTerms = false;

  // Password Validation State
  double _passwordStrength = 0.0;
  String _strengthLabel = '';
  Color _strengthColor = AppColors.border;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);
    _confirmController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    final val = _passwordController.text;
    if (val.isEmpty) {
      setState(() {
        _passwordStrength = 0.0;
        _strengthLabel = '';
        _strengthColor = AppColors.border;
      });
      return;
    }

    double strength = 0.0;
    if (val.length >= 8) strength += 0.35;
    if (RegExp(r'[A-Z]').hasMatch(val) && RegExp(r'[a-z]').hasMatch(val)) {
      strength += 0.35;
    }
    if (RegExp(r'[0-9!@#\$&*~]').hasMatch(val)) strength += 0.30;

    setState(() {
      _passwordStrength = strength.clamp(0.0, 1.0);
      if (_passwordStrength < 0.4) {
        _strengthLabel = 'Weak';
        _strengthColor = AppColors.error;
      } else if (_passwordStrength < 0.8) {
        _strengthLabel = 'Moderate';
        _strengthColor = AppColors.lime;
      } else {
        _strengthLabel = 'Strong & Secure';
        _strengthColor = AppColors.green;
      }
    });
  }

  /// Opens the interactive Terms & Privacy Modal
  void _openTermsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TermsPrivacyModal(
        onAccept: () {
          setState(() => _agreedToTerms = true);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _createAccount() {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: const Text(
            'Please read and accept the Terms and Privacy Policy.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    ResidentAccountRepository.instance.setPrototypeAccount(
      _emailController.text.trim(),
    );

    context.go('/verification');
  }

  @override
  Widget build(BuildContext context) {
    final bool passwordsMatch =
        _passwordController.text.isNotEmpty &&
        _confirmController.text == _passwordController.text;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: KaisaBackdrop()),
          Positioned.fill(
            child: Stack(
              children: [
                // Background Glow Accents
                Positioned(
                  top: -90,
                  right: -70,
                  child: _GlowingOrb(
                    color: AppColors.forest.withValues(alpha: 0.18),
                    radius: 170,
                  ),
                ),
                Positioned(
                  bottom: -50,
                  left: -50,
                  child: _GlowingOrb(
                    color: AppColors.green.withValues(alpha: 0.14),
                    radius: 150,
                  ),
                ),

                SafeArea(
                  child: Column(
                    children: [
                      // Navigation Header
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => context.go('/welcome'),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.surface,
                                elevation: 2,
                                shadowColor: Colors.black.withValues(
                                  alpha: 0.05,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Dual Logos Header Section (LGU + KAISA PNGs)
                                    _BrandedLogoHeader(),

                                    const SizedBox(height: 24),

                                    // Form Glassmorphism Card
                                    _GlassContainer(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          const Text(
                                            'Create Your Account',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Enter your email and password to get started.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 22),

                                          // Email Field
                                          _CustomTextField(
                                            controller: _emailController,
                                            labelText: 'Email Address',
                                            hintText: 'name@example.com',
                                            prefixIcon:
                                                Icons.mail_outline_rounded,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            autofillHints: const [
                                              AutofillHints.email,
                                            ],
                                            validator: (value) {
                                              final email = value?.trim() ?? '';
                                              if (!RegExp(
                                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                              ).hasMatch(email)) {
                                                return 'Enter a valid email address.';
                                              }
                                              return null;
                                            },
                                          ),

                                          const SizedBox(height: 16),

                                          // Password Field
                                          _CustomTextField(
                                            controller: _passwordController,
                                            labelText: 'Password',
                                            hintText: 'Minimum 8 characters',
                                            prefixIcon:
                                                Icons.lock_outline_rounded,
                                            obscureText: _hidePassword,
                                            suffixIcon: IconButton(
                                              onPressed: () => setState(
                                                () => _hidePassword =
                                                    !_hidePassword,
                                              ),
                                              icon: Icon(
                                                _hidePassword
                                                    ? Icons.visibility_outlined
                                                    : Icons
                                                          .visibility_off_outlined,
                                                color: AppColors.textSecondary,
                                                size: 20,
                                              ),
                                            ),
                                            validator: (value) {
                                              if ((value ?? '').length < 8) {
                                                return 'Use at least 8 characters.';
                                              }
                                              return null;
                                            },
                                          ),

                                          // Password Strength Bar
                                          if (_passwordController
                                              .text
                                              .isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            _PasswordStrengthBar(
                                              strength: _passwordStrength,
                                              label: _strengthLabel,
                                              color: _strengthColor,
                                            ),
                                          ],

                                          const SizedBox(height: 16),

                                          // Confirm Password Field
                                          _CustomTextField(
                                            controller: _confirmController,
                                            labelText: 'Confirm Password',
                                            hintText: 'Re-enter your password',
                                            prefixIcon:
                                                Icons.lock_reset_rounded,
                                            obscureText: _hidePassword,
                                            suffixIcon:
                                                _confirmController
                                                    .text
                                                    .isNotEmpty
                                                ? Icon(
                                                    passwordsMatch
                                                        ? Icons
                                                              .check_circle_rounded
                                                        : Icons.cancel_rounded,
                                                    color: passwordsMatch
                                                        ? AppColors.green
                                                        : AppColors.error,
                                                    size: 20,
                                                  )
                                                : null,
                                            validator: (value) {
                                              if (value !=
                                                  _passwordController.text) {
                                                return 'Passwords do not match.';
                                              }
                                              return null;
                                            },
                                          ),

                                          const SizedBox(height: 18),

                                          // Interactive Terms & Conditions Checkbox Box
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(
                                                alpha: 0.6,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: AppColors.border
                                                    .withValues(alpha: 0.5),
                                              ),
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Checkbox(
                                                  value: _agreedToTerms,
                                                  activeColor: AppColors.forest,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  onChanged: (val) => setState(
                                                    () => _agreedToTerms =
                                                        val ?? false,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 10,
                                                          right: 8,
                                                        ),
                                                    child: RichText(
                                                      text: TextSpan(
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Color.fromARGB(
                                                            255,
                                                            3,
                                                            3,
                                                            3,
                                                          ),
                                                          height: 1.4,
                                                        ),
                                                        children: [
                                                          const TextSpan(
                                                            text:
                                                                'I agree to the ',
                                                          ),
                                                          TextSpan(
                                                            text:
                                                                'Terms of Service',
                                                            style: const TextStyle(
                                                              color: AppColors
                                                                  .forest,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              decoration:
                                                                  TextDecoration
                                                                      .underline,
                                                            ),
                                                            recognizer:
                                                                TapGestureRecognizer()
                                                                  ..onTap =
                                                                      _openTermsModal,
                                                          ),
                                                          const TextSpan(
                                                            text: ', ',
                                                          ),
                                                          TextSpan(
                                                            text:
                                                                'Privacy Policy',
                                                            style: const TextStyle(
                                                              color: AppColors
                                                                  .forest,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              decoration:
                                                                  TextDecoration
                                                                      .underline,
                                                            ),
                                                            recognizer:
                                                                TapGestureRecognizer()
                                                                  ..onTap =
                                                                      _openTermsModal,
                                                          ),
                                                          const TextSpan(
                                                            text: ', and ',
                                                          ),
                                                          TextSpan(
                                                            text:
                                                                'RA 10173 Data Privacy Act',
                                                            style: const TextStyle(
                                                              color: AppColors
                                                                  .forest,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              decoration:
                                                                  TextDecoration
                                                                      .underline,
                                                            ),
                                                            recognizer:
                                                                TapGestureRecognizer()
                                                                  ..onTap =
                                                                      _openTermsModal,
                                                          ),
                                                          const TextSpan(
                                                            text:
                                                                ' compliance.',
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    // Glowing Action Button
                                    _GlowingButton(
                                      label: 'Create Account',
                                      icon: Icons.arrow_forward_rounded,
                                      onPressed: _createAccount,
                                    ),

                                    const SizedBox(height: 20),

                                    // Divider
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            color: AppColors.border.withValues(
                                              alpha: 0.6,
                                            ),
                                          ),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: Text(
                                            'OR',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: AppColors.border.withValues(
                                              alpha: 0.6,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 20),

                                    // Google SSO Placeholder Button
                                    OutlinedButton.icon(
                                      onPressed: null,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        side: BorderSide(
                                          color: AppColors.border.withValues(
                                            alpha: 0.8,
                                          ),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.account_circle_outlined,
                                        size: 20,
                                      ),
                                      label: const Text(
                                        'Continue with Google (Coming Soon)',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    // Login Navigation Link
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'Already have an account?',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () => context.go('/login'),
                                          child: const Text(
                                            'Log In',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: Color.fromARGB(
                                                255,
                                                252,
                                                252,
                                                252,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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

// -----------------------------------------------------------------------------
// INTERACTIVE POP-UP MODAL: TERMS, PRIVACY POLICY & RA 10173
// -----------------------------------------------------------------------------
class _TermsPrivacyModal extends StatefulWidget {
  final VoidCallback onAccept;

  const _TermsPrivacyModal({required this.onAccept});

  @override
  State<_TermsPrivacyModal> createState() => _TermsPrivacyModalState();
}

class _TermsPrivacyModalState extends State<_TermsPrivacyModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag Handle bar
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),

          // Header Title & Close Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.forest.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.gavel_rounded,
                        color: AppColors.forest,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Legal Policies',
                          style: TextStyle(
                            fontFamily: '',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'KAISA Cavite City GovTech System',
                          style: TextStyle(
                            fontFamily: '',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Pill Tabs Header
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.6),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: AppColors.forest,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'Terms'),
                Tab(text: 'Privacy'),
                Tab(text: 'RA 10173'),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Tab Content View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _TermsContent(),
                _PrivacyContent(),
                _DataPrivacyActContent(),
              ],
            ),
          ),

          // Sticky Bottom Action Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Decline',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color.fromARGB(255, 3, 24, 11),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: widget.onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forest,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                    ),
                    label: const Text(
                      'I Agree & Accept',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
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
}

// -----------------------------------------------------------------------------
// TAB CONTENTS
// -----------------------------------------------------------------------------
class _TermsContent extends StatelessWidget {
  const _TermsContent();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SectionTitle('1. Platform Scope & Purpose'),
          _SectionBody(
            'KAISA is the official multi-platform community engagement ecosystem for the local organizations of Cavite City. '
            'By creating an account, users agree to utilize the system responsibly for participating in '
            'community events, volunteer initiatives, accredited organizational activities, and civic reporting.',
          ),
          SizedBox(height: 16),
          _SectionTitle('2. User Responsibilities & Verification'),
          _SectionBody(
            'Users agree to provide accurate registration details. Identity verification (eKYC) '
            'is required to unlock Tier 2 benefits, including volunteer certificates and job opportunity applications. '
            'Creation of fraudulent or duplicate accounts is strictly prohibited.',
          ),
          SizedBox(height: 16),
          _SectionTitle('3. Code of Conduct'),
          _SectionBody(
            'Harassment, hate speech, political propaganda spam, or fake event submissions will result '
            'in immediate account suspension by the Super Admin (LYDO / MIS) compliance panel.',
          ),
        ],
      ),
    );
  }
}

class _PrivacyContent extends StatelessWidget {
  const _PrivacyContent();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SectionTitle('1. Information Collection'),
          _SectionBody(
            'We collect your email address, full name, barangay location, and eKYC government identification '
            'solely for verifying resident authenticity and matching local volunteer/job opportunities.',
          ),
          SizedBox(height: 16),
          _SectionTitle('2. Data Storage & Encryption'),
          _SectionBody(
            'All personal data is encrypted at rest using PostgreSQL Row-Level Security (RLS) on Supabase servers. '
            'Sensitive government ID photos uploaded during identity verification are stored in secure, private buckets.',
          ),
          SizedBox(height: 16),
          _SectionTitle('3. Information Sharing'),
          _SectionBody(
            'Your data is never sold or shared with commercial advertisers. Event attendance lists are accessible '
            'only to accredited event organizers and LGU administrators for official monitoring.',
          ),
        ],
      ),
    );
  }
}

class _DataPrivacyActContent extends StatelessWidget {
  const _DataPrivacyActContent();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SectionTitle('Republic Act No. 10173 Compliance'),
          _SectionBody(
            'KAISA strictly complies with the Data Privacy Act of 2012 (RA 10173) of the Philippines. '
            'By using this platform, you grant explicit consent for the local government of Cavite City to process '
            'your personal data in accordance with the following rights:',
          ),
          SizedBox(height: 14),
          _BulletPoint(
            'Right to be Informed: You know how your data is collected and processed.',
          ),
          _BulletPoint(
            'Right to Access: You may request access to your stored personal records anytime.',
          ),
          _BulletPoint(
            'Right to Rectification: You can update or correct inaccuracies in your profile.',
          ),
          _BulletPoint(
            'Right to Erasure: You may request account deletion and data removal upon written request.',
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _SectionBody extends StatelessWidget {
  final String text;
  const _SectionBody(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;
  const _BulletPoint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              color: AppColors.forest,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// BRANDING LOGO HEADER
// -----------------------------------------------------------------------------
class _BrandedLogoHeader extends StatelessWidget {
  const _BrandedLogoHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/LGU.png',
                height: 64,
                width: 64,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const _LogoFallback(
                  icon: Icons.account_balance_rounded,
                  color: AppColors.forest,
                ),
              ),
              const SizedBox(width: 20),
              Container(height: 45, width: 1.5, color: Color(0xFFE2E9E4)),
              const SizedBox(width: 20),
              Image.asset(
                'assets/images/kaisa_logo.png',
                height: 64,
                width: 64,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const _LogoFallback(
                  icon: Icons.diversity_3_rounded,
                  color: AppColors.green,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'KAISA CAVITE CITY',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _LogoFallback extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _LogoFallback({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}

// -----------------------------------------------------------------------------
// PASSWORD STRENGTH COMPONENT
// -----------------------------------------------------------------------------
class _PasswordStrengthBar extends StatelessWidget {
  final double strength;
  final String label;
  final Color color;

  const _PasswordStrengthBar({
    required this.strength,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Password Security:',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: strength,
            minHeight: 5,
            backgroundColor: AppColors.border.withValues(alpha: 0.5),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// GLASS & HELPER COMPONENTS
// -----------------------------------------------------------------------------
class _GlassContainer extends StatelessWidget {
  final Widget child;

  const _GlassContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.deepForest.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;

  const _CustomTextField({
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.autofillHints,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        prefixIcon: Icon(prefixIcon, color: AppColors.mint, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.forest.withValues(alpha: 0.72),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.border.withValues(alpha: 0.8),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.border.withValues(alpha: 0.8),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.lime, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
      ),
      validator: validator,
    );
  }
}

class _GlowingButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _GlowingButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.forest.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lime,
          foregroundColor: AppColors.deepForest,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 20),
          ],
        ),
      ),
    );
  }
}

class _GlowingOrb extends StatelessWidget {
  final Color color;
  final double radius;

  const _GlowingOrb({required this.color, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}
