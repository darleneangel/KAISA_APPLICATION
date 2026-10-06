import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  final firstNameController = TextEditingController();
  final middleNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool agreedToTerms = false;

  @override
  void dispose() {
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;

    if (!agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please agree to the Terms and Conditions and Privacy Policy.',
          ),
        ),
      );
      return;
    }

    // Prototype only.
    // Later this will create the account through Supabase Auth.
    context.go('/verification');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 900) {
            return _DesktopSignUp(
              formKey: _formKey,
              firstNameController: firstNameController,
              middleNameController: middleNameController,
              lastNameController: lastNameController,
              emailController: emailController,
              passwordController: passwordController,
              confirmPasswordController: confirmPasswordController,
              obscurePassword: obscurePassword,
              obscureConfirmPassword: obscureConfirmPassword,
              agreedToTerms: agreedToTerms,
              onTogglePassword: () {
                setState(() {
                  obscurePassword = !obscurePassword;
                });
              },
              onToggleConfirmPassword: () {
                setState(() {
                  obscureConfirmPassword = !obscureConfirmPassword;
                });
              },
              onTermsChanged: (value) {
                setState(() {
                  agreedToTerms = value ?? false;
                });
              },
              onContinue: _continue,
            );
          }

          return _MobileSignUp(
            formKey: _formKey,
            firstNameController: firstNameController,
            middleNameController: middleNameController,
            lastNameController: lastNameController,
            emailController: emailController,
            passwordController: passwordController,
            confirmPasswordController: confirmPasswordController,
            obscurePassword: obscurePassword,
            obscureConfirmPassword: obscureConfirmPassword,
            agreedToTerms: agreedToTerms,
            onTogglePassword: () {
              setState(() {
                obscurePassword = !obscurePassword;
              });
            },
            onToggleConfirmPassword: () {
              setState(() {
                obscureConfirmPassword = !obscureConfirmPassword;
              });
            },
            onTermsChanged: (value) {
              setState(() {
                agreedToTerms = value ?? false;
              });
            },
            onContinue: _continue,
          );
        },
      ),
    );
  }
}

// ============================================================================
// MOBILE
// ============================================================================

class _MobileSignUp extends StatelessWidget {
  final GlobalKey<FormState> formKey;

  final TextEditingController firstNameController;
  final TextEditingController middleNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final bool agreedToTerms;

  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final ValueChanged<bool?> onTermsChanged;
  final VoidCallback onContinue;

  const _MobileSignUp({
    required this.formKey,
    required this.firstNameController,
    required this.middleNameController,
    required this.lastNameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.agreedToTerms,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onTermsChanged,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopBar(
                    onBack: () => context.go('/welcome'),
                  ),

                  const SizedBox(height: 28),

                  const _MobileHeading(),

                  const SizedBox(height: 30),

                  _SignUpForm(
                    firstNameController: firstNameController,
                    middleNameController: middleNameController,
                    lastNameController: lastNameController,
                    emailController: emailController,
                    passwordController: passwordController,
                    confirmPasswordController: confirmPasswordController,
                    obscurePassword: obscurePassword,
                    obscureConfirmPassword: obscureConfirmPassword,
                    agreedToTerms: agreedToTerms,
                    onTogglePassword: onTogglePassword,
                    onToggleConfirmPassword: onToggleConfirmPassword,
                    onTermsChanged: onTermsChanged,
                    onContinue: onContinue,
                    desktop: false,
                  ),

                  const SizedBox(height: 25),

                  _LoginPrompt(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileHeading extends StatelessWidget {
  const _MobileHeading();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                Icons.groups_rounded,
                size: 15,
                color: AppColors.greenDark,
              ),
              SizedBox(width: 6),
              Text(
                'JOIN THE COMMUNITY',
                style: TextStyle(
                  color: AppColors.greenDark,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .6,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 17),

        const Text(
          'Create your\nKAISA account.',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 34,
            height: 1.08,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),

        const SizedBox(height: 12),

        const Text(
          'Connect with your community and discover meaningful '
          'opportunities across Cavite City.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// DESKTOP
// ============================================================================

class _DesktopSignUp extends StatelessWidget {
  final GlobalKey<FormState> formKey;

  final TextEditingController firstNameController;
  final TextEditingController middleNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final bool agreedToTerms;

  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final ValueChanged<bool?> onTermsChanged;
  final VoidCallback onContinue;

  const _DesktopSignUp({
    required this.formKey,
    required this.firstNameController,
    required this.middleNameController,
    required this.lastNameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.agreedToTerms,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onTermsChanged,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: const _DesktopBrandPanel(),
        ),

        Expanded(
          flex: 6,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 60,
                vertical: 32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TopBar(
                          onBack: () => context.go('/welcome'),
                        ),

                        const SizedBox(height: 30),

                        const Text(
                          'Create your account',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Start your journey toward meaningful community participation.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 30),

                        _SignUpForm(
                          firstNameController: firstNameController,
                          middleNameController: middleNameController,
                          lastNameController: lastNameController,
                          emailController: emailController,
                          passwordController: passwordController,
                          confirmPasswordController:
                              confirmPasswordController,
                          obscurePassword: obscurePassword,
                          obscureConfirmPassword:
                              obscureConfirmPassword,
                          agreedToTerms: agreedToTerms,
                          onTogglePassword: onTogglePassword,
                          onToggleConfirmPassword:
                              onToggleConfirmPassword,
                          onTermsChanged: onTermsChanged,
                          onContinue: onContinue,
                          desktop: true,
                        ),

                        const SizedBox(height: 24),

                        _LoginPrompt(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DesktopBrandPanel extends StatelessWidget {
  const _DesktopBrandPanel();

  @override
  Widget build(BuildContext context) {
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
          const Positioned(
            top: -100,
            right: -90,
            child: _Circle(
              size: 300,
              opacity: .06,
            ),
          ),

          const Positioned(
            bottom: -120,
            left: -100,
            child: _Circle(
              size: 330,
              opacity: .06,
            ),
          ),

          Positioned(
            right: 60,
            bottom: 90,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.yellow.withValues(alpha: .10),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Brand(),

                const Spacer(),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.yellow,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Text(
                    'YOUR COMMUNITY STARTS HERE',
                    style: TextStyle(
                      color: AppColors.blueDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .7,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Discover.\nParticipate.\nBelong.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 50,
                    height: 1.04,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.2,
                  ),
                ),

                const SizedBox(height: 20),

                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 470,
                  ),
                  child: const Text(
                    'Create your KAISA account and connect with '
                    'opportunities, organizations, and initiatives '
                    'that make a difference in Cavite City.',
                    style: TextStyle(
                      color: Color(0xFFE4EDF8),
                      fontSize: 16,
                      height: 1.65,
                    ),
                  ),
                ),

                const SizedBox(height: 38),

                const _Benefit(
                  icon: Icons.explore_rounded,
                  title: 'Discover opportunities',
                  description:
                      'Find events, training, volunteer work, and community programs.',
                ),

                const SizedBox(height: 18),

                const _Benefit(
                  icon: Icons.groups_rounded,
                  title: 'Connect with organizations',
                  description:
                      'Engage with trusted community organizations across the city.',
                ),

                const SizedBox(height: 18),

                const _Benefit(
                  icon: Icons.workspace_premium_rounded,
                  title: 'Build your participation history',
                  description:
                      'Keep track of activities, attendance, and certificates.',
                ),

                const Spacer(),

                const Text(
                  'Connect • Participate • Impact',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

// ============================================================================
// FORM
// ============================================================================

class _SignUpForm extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController middleNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final bool agreedToTerms;
  final bool desktop;

  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final ValueChanged<bool?> onTermsChanged;
  final VoidCallback onContinue;

  const _SignUpForm({
    required this.firstNameController,
    required this.middleNameController,
    required this.lastNameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.agreedToTerms,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onTermsChanged,
    required this.onContinue,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(
          icon: Icons.person_outline_rounded,
          title: 'Personal Information',
        ),

        const SizedBox(height: 14),

        if (desktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _NameField(
                  controller: firstNameController,
                  label: 'First Name',
                  hint: 'Juan',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NameField(
                  controller: lastNameController,
                  label: 'Last Name',
                  hint: 'Dela Cruz',
                ),
              ),
            ],
          )
        else ...[
          _NameField(
            controller: firstNameController,
            label: 'First Name',
            hint: 'Juan',
          ),
          const SizedBox(height: 14),
          _NameField(
            controller: lastNameController,
            label: 'Last Name',
            hint: 'Dela Cruz',
          ),
        ],

        const SizedBox(height: 14),

        TextFormField(
          controller: middleNameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Middle Name',
            hintText: 'Optional',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
        ),

        const SizedBox(height: 27),

        const _SectionLabel(
          icon: Icons.lock_outline_rounded,
          title: 'Account Information',
        ),

        const SizedBox(height: 14),

        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            labelText: 'Email Address',
            hintText: 'you@example.com',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (value) {
            final email = value?.trim() ?? '';

            if (email.isEmpty) {
              return 'Please enter your email address.';
            }

            final emailPattern =
                RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

            if (!emailPattern.hasMatch(email)) {
              return 'Enter a valid email address.';
            }

            return null;
          },
        ),

        const SizedBox(height: 14),

        if (desktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _PasswordField(
                  controller: passwordController,
                  label: 'Password',
                  obscure: obscurePassword,
                  onToggle: onTogglePassword,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ConfirmPasswordField(
                  controller: confirmPasswordController,
                  passwordController: passwordController,
                  obscure: obscureConfirmPassword,
                  onToggle: onToggleConfirmPassword,
                ),
              ),
            ],
          )
        else ...[
          _PasswordField(
            controller: passwordController,
            label: 'Password',
            obscure: obscurePassword,
            onToggle: onTogglePassword,
          ),
          const SizedBox(height: 14),
          _ConfirmPasswordField(
            controller: confirmPasswordController,
            passwordController: passwordController,
            obscure: obscureConfirmPassword,
            onToggle: onToggleConfirmPassword,
          ),
        ],

        const SizedBox(height: 10),

        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'Use at least 8 characters with a mix of letters and numbers.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ),

        const SizedBox(height: 22),

        _TermsAgreement(
          value: agreedToTerms,
          onChanged: onTermsChanged,
        ),

        const SizedBox(height: 25),

        ElevatedButton(
          onPressed: onContinue,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Create Account'),
              SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                size: 19,
              ),
            ],
          ),
        ),

        const SizedBox(height: 15),

        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'STEP 1 OF 3',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .7,
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),

        const SizedBox(height: 10),

        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StepDot(active: true),
            SizedBox(width: 7),
            _StepDot(),
            SizedBox(width: 7),
            _StepDot(),
          ],
        ),
      ],
    );
  }
}

class _NameField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;

  const _NameField({
    required this.controller,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(Icons.person_outline_rounded),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label is required.';
        }

        return null;
      },
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      autofillHints: const [AutofillHints.newPassword],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please create a password.';
        }

        if (value.length < 8) {
          return 'Password must contain at least 8 characters.';
        }

        if (!RegExp(r'[A-Za-z]').hasMatch(value) ||
            !RegExp(r'[0-9]').hasMatch(value)) {
          return 'Include letters and numbers.';
        }

        return null;
      },
    );
  }
}

class _ConfirmPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final TextEditingController passwordController;
  final bool obscure;
  final VoidCallback onToggle;

  const _ConfirmPasswordField({
    required this.controller,
    required this.passwordController,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        prefixIcon: const Icon(Icons.lock_reset_rounded),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please confirm your password.';
        }

        if (value != passwordController.text) {
          return 'Passwords do not match.';
        }

        return null;
      },
    );
  }
}

// ============================================================================
// SMALL COMPONENTS
// ============================================================================

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;

  const _TopBar({
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onBack,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: AppColors.textPrimary,
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
            border: Border.all(color: AppColors.border),
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
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 62,
          height: 62,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Image.asset(
            'assets/images/kaisa_logo.png',
            fit: BoxFit.contain,
          ),
        ),

        const SizedBox(width: 14),

        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KAISA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.7,
              ),
            ),
            Text(
              'Community Engagement Platform',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionLabel({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 31,
          height: 31,
          decoration: BoxDecoration(
            color: AppColors.blueLight,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            icon,
            size: 17,
            color: AppColors.blue,
          ),
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _TermsAgreement extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _TermsAgreement({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 9, 12, 9),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.blue,
          ),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.45,
                  ),
                  children: [
                    TextSpan(text: 'I agree to the '),
                    TextSpan(
                      text: 'Terms and Conditions',
                      style: TextStyle(
                        color: AppColors.blue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(text: ' and acknowledge the '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(
                        color: AppColors.blue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(text: '.'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already part of KAISA?',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        TextButton(
          onPressed: () => context.go('/login'),
          child: const Text('Log In'),
        ),
      ],
    );
  }
}

class _Benefit extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _Benefit({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: AppColors.yellow,
            size: 21,
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool active;

  const _StepDot({
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 24 : 7,
      height: 7,
      decoration: BoxDecoration(
        color: active ? AppColors.blue : AppColors.border,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final double size;
  final double opacity;

  const _Circle({
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}