import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/kaisa_auth_service.dart';
import '../../../core/services/kaisa_resident_profile_gate.dart';

/// KAISA login — centered Civic Dignity form over a civic photo slideshow.
///
/// Authentication, session checking, OAuth, and role-based destinations are
/// retained from the existing login_page.dart. This is a UI replacement only.
///
/// Important: Server-side RLS must continue to protect privileged data.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
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

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _hidden = true;
  bool _isLoading = false;
  bool _socialLoading = false;
  bool _tagalog = false;

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

  bool get _working => _isLoading || _socialLoading;
  String _t(String english, String tagalog) => _tagalog ? tagalog : english;

  @override
  void dispose() {
    _slideTimer?.cancel();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // AUTHENTICATION — preserved from your original working login page.
  // -------------------------------------------------------------------------

  /// Returns null for residents. Blocks incorrectly configured admin accounts.
  /// Never infer elevated access from an email address or client-side input.
  String? _destinationFor(User user) {
    final metadata = user.appMetadata;
    if (metadata['is_super_admin'] != true) {
      return null;
    }

    switch (metadata['kaisa_lgu_role']) {
      case 'lgu_it_admin':
        // The existing LGU shell selects IT dashboard by authenticated role.
        return '/lgu-admin/dashboard';
      case 'lgu_verification_admin':
        return '/lgu-admin/verification/dashboard';
      case 'lgu_operations_admin':
        return '/lgu-admin/dashboard';
      default:
        throw const FormatException(
          'Your administrator role is not configured correctly. '
          'Please contact the KAISA IT administrator.',
        );
    }
  }

  Future<void> _signIn() async {
    if (_working) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final response = await KaisaAuthService.instance.signIn(
        _email.text.trim(),
        _password.text,
      );
      if (!mounted) return;

      if (response.user == null || response.session == null) {
        _showError('Could not establish a session. Please try again.');
        return;
      }

      // Read the latest Auth user after establishing a session.
      // Do not use the Admin API or service-role keys in the Flutter client.
      final fresh = await Supabase.instance.client.auth.getUser();
      if (!mounted) return;

      final user = fresh.user;
      if (user == null || user.id != response.user!.id) {
        _showError('Could not verify your account. Please sign in again.');
        await Supabase.instance.client.auth.signOut();
        return;
      }

      // Preserve trusted administrator routing. Only resident accounts
      // must pass through the persisted profile-completion check.
      final adminDestination = _destinationFor(user);
      final destination =
          adminDestination ??
          await KaisaResidentProfileGate.destinationFor(user);
      if (!mounted) return;

      context.go(destination);
    } on AuthException catch (error) {
      if (mounted) _showError(_messageForAuthError(error));
    } on FormatException catch (error) {
      // Refuse a privileged account with incomplete/unrecognized role claims.
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {
        // Still report the authorization issue to the user.
      }
      if (mounted) _showError(error.message);
    } catch (_) {
      if (mounted) {
        _showError(
          'Could not verify your KAISA login. Check your connection '
          'and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _social(OAuthProvider provider) async {
    if (_working) return;
    FocusScope.of(context).unfocus();
    setState(() => _socialLoading = true);
    try {
      await KaisaAuthService.instance.socialSignIn(provider);
      // OAuth completes via redirect; the existing app auth-state listener
      // and router handle the callback and social OTP flow.
    } on AuthException catch (error) {
      if (mounted) _showError(_messageForAuthError(error));
    } catch (_) {
      if (mounted) _showError('Unable to open social login. Please try again.');
    } finally {
      if (mounted) setState(() => _socialLoading = false);
    }
  }

  String _messageForAuthError(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'Incorrect email or password.';
    }
    if (message.contains('email not confirmed')) {
      return 'Please confirm your email address before logging in.';
    }
    if (message.contains('rate limit') ||
        message.contains('too many requests')) {
      return 'Too many attempts. Please try again later.';
    }
    return error.message;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // -------------------------------------------------------------------------
  // PRESENTATION — adapted from the supplied Stitch screenshot / DESIGN.md.
  // -------------------------------------------------------------------------

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

  @override
  Widget build(BuildContext context) {
    final light = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(seedColor: _CivicColors.green),
    );
    return Theme(
      data: light.copyWith(
        textTheme: Theme.of(
          context,
        ).textTheme.apply(fontFamily: GoogleFonts.inter().fontFamily),
        platform: Theme.of(context).platform,
      ),
      child: Scaffold(
        backgroundColor: _CivicColors.dark,
        body: Stack(
          children: [
            _background(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final mobile = constraints.maxWidth < 700;
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: mobile ? 12 : 40,
                          vertical: mobile ? 8 : 16,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildHeader(
                              isMobile: mobile,
                              smallPhone: constraints.maxWidth < 390,
                            ),
                            if (mobile) _dots(),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: mobile ? 6 : 18,
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: mobile ? 340 : 380,
                                  ),
                                  child: _buildLoginCard(isMobile: mobile),
                                ),
                              ),
                            ),
                            _buildFooter(isMobile: mobile),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({required bool isMobile, required bool smallPhone}) =>
      Row(
        children: [
          IconButton(
            tooltip: _t('Back to welcome', 'Bumalik sa welcome'),
            onPressed: _working ? null : () => context.go('/welcome'),
            color: Colors.white,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Image.asset(
            'assets/images/kaisa_logo.png',
            width: isMobile ? 34 : 42,
            height: isMobile ? 34 : 42,
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
                    fontSize: isMobile ? 21 : 25,
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
          _buildLanguagePicker(isMobile),
        ],
      );

  Widget _buildLanguagePicker(bool isMobile) => PopupMenuButton<bool>(
    tooltip: 'Choose language / Piliin ang wika',
    initialValue: _tagalog,
    onSelected: (value) => setState(() => _tagalog = value),
    itemBuilder: (_) => const [
      PopupMenuItem(value: false, child: Text('English')),
      PopupMenuItem(value: true, child: Text('Tagalog')),
    ],
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black26,
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.translate_rounded,
            color: _CivicColors.gold,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            _tagalog
                ? (isMobile ? 'FIL' : 'Tagalog')
                : (isMobile ? 'EN' : 'English'),
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildLoginCard({required bool isMobile}) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 14 : 17),
        border: Border.all(color: _CivicColors.border),
        boxShadow: [
          BoxShadow(
            color: _CivicColors.forest.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(
            height: 4,
            width: double.infinity,
            child: ColoredBox(color: _CivicColors.gold),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 14 : 20,
              isMobile ? 14 : 20,
              isMobile ? 14 : 20,
              isMobile ? 10 : 16,
            ),
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('YOUR COMMUNITY PORTAL', 'ANG IYONG COMMUNITY PORTAL'),
                      style: GoogleFonts.inter(
                        color: _CivicColors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      _t(
                        'Welcome Back to KAISA',
                        'Maligayang pagbabalik sa KAISA',
                      ),
                      style: GoogleFonts.outfit(
                        color: _CivicColors.forest,
                        fontSize: isMobile ? 22 : 26,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.05,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _t(
                        'Sign in to your community portal.',
                        'Mag-sign in sa iyong community portal.',
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF465249),
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 9),
                    _fieldLabel(_t('Email address', 'Email address')),
                    SizedBox(height: 4),
                    TextFormField(
                      controller: _email,
                      enabled: !_working,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.inter(
                        color: _CivicColors.ink,
                        fontSize: 14,
                      ),
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: _inputDecoration(
                        compact: isMobile,
                        hint: 'name@domain.ph',
                        prefix: Icons.alternate_email_rounded,
                      ),
                      validator: (value) {
                        final email = (value ?? '').trim();
                        if (!RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        ).hasMatch(email)) {
                          return _t(
                            'Enter a valid email address',
                            'Maglagay ng wastong email address',
                          );
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 5),
                    _fieldLabel(_t('Password', 'Password')),
                    SizedBox(height: 4),
                    TextFormField(
                      controller: _password,
                      enabled: !_working,
                      obscureText: _hidden,
                      style: GoogleFonts.inter(
                        color: _CivicColors.ink,
                        fontSize: 14,
                      ),
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _signIn(),
                      decoration: _inputDecoration(
                        compact: isMobile,
                        hint: '••••••••••••',
                        prefix: Icons.lock_outline_rounded,
                        suffix: IconButton(
                          tooltip: _hidden ? 'Show password' : 'Hide password',
                          onPressed: _working
                              ? null
                              : () => setState(() => _hidden = !_hidden),
                          icon: Icon(
                            _hidden
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 21,
                            color: _CivicColors.muted,
                          ),
                        ),
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? _t(
                              'Enter your password',
                              'Ilagay ang iyong password',
                            )
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _working
                            ? null
                            : () => context.go('/forgot-password'),
                        style: TextButton.styleFrom(
                          foregroundColor: _CivicColors.forest,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 6,
                          ),
                          minimumSize: const Size(0, 44),
                        ),
                        child: Text(
                          _t('Forgot password?', 'Nakalimutan ang password?'),
                          textAlign: TextAlign.end,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    SizedBox(
                      width: double.infinity,

                      child: FilledButton(
                        onPressed: _working ? null : _signIn,
                        style: FilledButton.styleFrom(
                          minimumSize: Size(0, 44),
                          backgroundColor: _CivicColors.forest,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: _CivicColors.green
                              .withValues(alpha: 0.60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 23,
                                height: 23,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      _t('Sign in', 'Mag-sign in'),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(color: _CivicColors.border),
                        ),
                        Flexible(
                          flex: 4,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              _t('OR CONTINUE WITH', 'O GAMITIN ANG'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10,
                                color: _CivicColors.muted,
                                letterSpacing: 1.0,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(color: _CivicColors.border),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    if (_socialLoading)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: LinearProgressIndicator(
                          color: _CivicColors.green,
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: _socialButton(
                            providerName: 'Google',
                            brandLetter: 'G',
                            brandColor: const Color(0xFF4285F4),
                            onPressed: _working
                                ? null
                                : () => _social(OAuthProvider.google),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _socialButton(
                            providerName: 'Facebook',
                            brandLetter: 'f',
                            brandColor: const Color(0xFF1877F2),
                            onPressed: _working
                                ? null
                                : () => _social(OAuthProvider.facebook),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 3,
                        runSpacing: 0,
                        children: [
                          Text(
                            _t('New to KAISA?', 'Bago sa KAISA?'),
                            style: const TextStyle(
                              color: Color(0xFF465249),
                              fontSize: 13,
                            ),
                          ),
                          TextButton(
                            onPressed: _working
                                ? null
                                : () => context.go('/signup'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              foregroundColor: _CivicColors.forest,
                              minimumSize: const Size(0, 44),
                            ),
                            child: Text(
                              _t(
                                'Register as a resident',
                                'Magrehistro bilang residente',
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                decoration: TextDecoration.underline,
                                decorationColor: _CivicColors.gold,
                                decorationThickness: 2,
                              ),
                            ),
                          ),
                          const CircleAvatar(
                            radius: 3,
                            backgroundColor: _CivicColors.gold,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: _CivicColors.ink,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefix,
    Widget? suffix,
    bool compact = false,
  }) {
    final regularBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _CivicColors.border),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF89948E), fontSize: 14),
      filled: true,
      fillColor: _CivicColors.input,
      prefixIcon: Icon(prefix, size: 21, color: _CivicColors.muted),
      suffixIcon: suffix,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: compact ? 9 : 10,
      ),
      border: regularBorder,
      enabledBorder: regularBorder,
      disabledBorder: regularBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _CivicColors.green, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 2),
      ),
    );
  }

  Widget _socialButton({
    required String providerName,
    required String brandLetter,
    required Color brandColor,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _CivicColors.border),
          foregroundColor: _CivicColors.ink,
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.string(
              providerName == 'Google' ? _googleLogoSvg : _facebookLogoSvg,
              width: 21,
              height: 21,
              excludeFromSemantics: true,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                providerName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          _t(slide.title, slide.titleTl),
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

const _googleLogoSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48"><path fill="#4285F4" d="M43.6 24.5c0-1.4-.1-2.8-.4-4.1H24v7.8h11a9.4 9.4 0 0 1-4.1 6.2v5.2h6.7c3.9-3.6 6-8.9 6-15.1z"/><path fill="#34A853" d="M24 44c5.5 0 10.1-1.8 13.5-4.9l-6.7-5.2c-1.8 1.2-4.1 2-6.8 2-5.3 0-9.8-3.6-11.4-8.4H5.7v5.4A20 20 0 0 0 24 44z"/><path fill="#FBBC05" d="M12.6 27.5a12 12 0 0 1 0-7.1V15H5.7a20 20 0 0 0 0 17.9l6.9-5.4z"/><path fill="#EA4335" d="M24 12c3 0 5.7 1 7.8 3l5.9-5.9A19.2 19.2 0 0 0 24 4 20 20 0 0 0 5.7 15l6.9 5.4C14.2 15.6 18.7 12 24 12z"/></svg>';
const _facebookLogoSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><circle cx="12" cy="12" r="12" fill="#0866FF"/><path fill="#fff" d="M16.67 15.47l.53-3.47h-3.33V9.75c0-.95.46-1.87 1.95-1.87h1.52V4.93s-1.38-.23-2.7-.23c-2.75 0-4.55 1.67-4.55 4.68V12H7.03v3.47h3.06V24h3.78v-8.53z"/></svg>';
