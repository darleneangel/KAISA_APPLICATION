import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/kaisa_auth_service.dart';

/// KAISA login — compact Civic Dignity UI with 5-photo crossfade background.
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
  static const Color input = Color(0xFFF4F6FB);
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

  // Five rotating background photos. When the files exist in assets/images,
  // Flutter uses them offline; until then, online Unsplash photos are used.
  static const List<String> _slideAssets = [
    'assets/images/kaisa_bg_01.jpg',
    'assets/images/kaisa_bg_02.jpg',
    'assets/images/kaisa_bg_03.jpg',
    'assets/images/kaisa_bg_04.jpg',
    'assets/images/kaisa_bg_05.jpg',
  ];

  static const List<String> _slideImageUrls = [
    'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?auto=format&fit=crop&w=1600&q=82',
    'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=1600&q=82',
    'https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?auto=format&fit=crop&w=1600&q=82',
    'https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?auto=format&fit=crop&w=1600&q=82',
    'https://images.unsplash.com/photo-1556761175-b413da4baf72?auto=format&fit=crop&w=1600&q=82',
  ];

  Timer? _slideTimer;
  int _activeSlide = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect operating-system accessibility preferences (reduced motion).
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _slideTimer?.cancel();
      _slideTimer = null;
    } else {
      _slideTimer ??= Timer.periodic(const Duration(seconds: 7), (_) {
        if (!mounted) return;
        setState(() => _activeSlide = (_activeSlide + 1) % _slideAssets.length);
      });
    }
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

      final destination = _destinationFor(user);
      if (!mounted) return;

      // Existing resident flow; admin routes take precedence.
      context.go(destination ?? '/resident/home');
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

  // Crossfade slide animation is independent of auth state and form values.
  // No external UI dependencies are required.
  Widget _buildPhotoSlideshow(bool reduceMotion) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: _CivicColors.dark),
            AnimatedSwitcher(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 1350),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              layoutBuilder: (current, previous) => Stack(
                fit: StackFit.expand,
                children: [...previous, if (current != null) current],
              ),
              child: Image.asset(
                _slideAssets[_activeSlide],
                key: ValueKey<int>(_activeSlide),
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                // Files can be downloaded once with download_kaisa_images.ps1.
                // Without them, this remote version still shows the slideshow.
                errorBuilder: (context, error, stackTrace) => Image.network(
                  _slideImageUrls[_activeSlide],
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, error, stackTrace) =>
                      const ColoredBox(color: _CivicColors.dark),
                ),
              ),
            ),
            // A forest-green scrim keeps the white login card and header clear
            // against all five photos, including lighter scenes.
            ColoredBox(color: _CivicColors.dark.withValues(alpha: 0.50)),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xA6002015),
                    Color(0x1A002818),
                    Color(0xAA002015),
                  ],
                  stops: [0.0, 0.48, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Scaffold(
      backgroundColor: _CivicColors.dark,
      body: Stack(
        children: [
          _buildPhotoSlideshow(reduceMotion),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 700;
                final smallPhone = constraints.maxWidth < 390;

                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 32,
                        vertical: isMobile ? 14 : 15,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildHeader(
                            isMobile: isMobile,
                            smallPhone: smallPhone,
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: isMobile ? 14 : 12,
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: 350),
                                child: _buildLoginCard(isMobile: isMobile),
                              ),
                            ),
                          ),
                          _buildFooter(isMobile: isMobile),
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
    );
  }

  Widget _buildHeader({required bool isMobile, required bool smallPhone}) {
    return Row(
      children: [
        IconButton(
          tooltip: _t('Back to welcome', 'Bumalik sa welcome'),
          onPressed: _working ? null : () => context.go('/welcome'),
          icon: const Icon(Icons.arrow_back_rounded),
          color: Colors.white,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.09),
          ),
        ),
        SizedBox(width: isMobile ? 10 : 16),
        // Circular logo only: no yellow tile, tint, or colored backdrop.
        SizedBox(
          height: isMobile ? 40 : 44,
          width: isMobile ? 40 : 44,
          child: ClipOval(
            child: Image.asset(
              'assets/images/kaisa_logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.groups_rounded,
                size: 26,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'KAISA',
              style: TextStyle(
                fontSize: smallPhone ? 18 : 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
                color: Colors.white,
              ),
            ),
            if (!smallPhone)
              Text(
                'LUNGSOD NG CAVITE',
                style: TextStyle(
                  fontSize: isMobile ? 8 : 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
          ],
        ),
        const Spacer(),
        _buildLanguagePicker(isMobile),
      ],
    );
  }

  Widget _buildLanguagePicker(bool isMobile) {
    if (isMobile) {
      return PopupMenuButton<bool>(
        tooltip: 'Choose language / Piliin ang wika',
        initialValue: _tagalog,
        onSelected: (value) => setState(() => _tagalog = value),
        icon: const Icon(Icons.translate_rounded, color: _CivicColors.gold),
        itemBuilder: (context) => const [
          PopupMenuItem(value: false, child: Text('English')),
          PopupMenuItem(value: true, child: Text('Tagalog')),
        ],
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.translate_rounded,
              size: 17,
              color: _CivicColors.gold,
            ),
            const SizedBox(width: 4),
            TextButton(
              onPressed: () => setState(() => _tagalog = false),
              style: TextButton.styleFrom(
                foregroundColor: _tagalog ? Colors.white60 : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: const Size(0, 32),
              ),
              child: Text(
                'English',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: !_tagalog ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
            const Text('/', style: TextStyle(color: Colors.white38)),
            TextButton(
              onPressed: () => setState(() => _tagalog = true),
              style: TextButton.styleFrom(
                foregroundColor: _tagalog ? Colors.white : Colors.white60,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: const Size(0, 32),
              ),
              child: Text(
                'Tagalog',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: _tagalog ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginCard({required bool isMobile}) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 35,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 18 : 21,
              isMobile ? 18 : 20,
              isMobile ? 18 : 21,
              isMobile ? 15 : 16,
            ),
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('Sign in to KAISA', 'Mag-sign in sa KAISA'),
                      style: TextStyle(
                        color: _CivicColors.forest,
                        fontSize: isMobile ? 25 : 26,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.05,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _t(
                        'Enter your credentials to access your community '
                            'portal and opportunities.',
                        'Ilagay ang iyong account details upang ma-access '
                            'ang community portal at mga oportunidad.',
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF465249),
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _fieldLabel(_t('Email address', 'Email address')),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _email,
                      enabled: !_working,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: _inputDecoration(
                        hint: 'Enter Email Address',
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
                    const SizedBox(height: 10),
                    _fieldLabel(_t('Password', 'Password')),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _password,
                      enabled: !_working,
                      obscureText: _hidden,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _signIn(),
                      decoration: _inputDecoration(
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
                    Row(
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          size: 16,
                          color: _CivicColors.muted,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            _t('Your KAISA account', 'Ang iyong KAISA account'),
                            style: const TextStyle(
                              fontSize: 11,
                              color: _CivicColors.muted,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _working
                              ? null
                              : () => context.go('/forgot-password'),
                          style: TextButton.styleFrom(
                            foregroundColor: _CivicColors.forest,
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            minimumSize: const Size(0, 42),
                          ),
                          child: Text(
                            _t('Forgot password?', 'Nakalimutan ang password?'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: FilledButton(
                        onPressed: _working ? null : _signIn,
                        style: FilledButton.styleFrom(
                          backgroundColor: _CivicColors.forest,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: _CivicColors.green
                              .withValues(alpha: 0.60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
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
                                  Text(
                                    _t('Sign in', 'Mag-sign in'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const CircleAvatar(
                                    radius: 12,
                                    backgroundColor: _CivicColors.gold,
                                    child: Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 16,
                                      color: _CivicColors.forest,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 13),
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(color: _CivicColors.border),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 11),
                          child: Text(
                            _t('OR CONTINUE WITH', 'O MAGPATULOY GAMIT ANG'),
                            style: const TextStyle(
                              fontSize: 10,
                              color: _CivicColors.muted,
                              letterSpacing: 1.0,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(color: _CivicColors.border),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
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
                    const SizedBox(height: 10),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 3,
                        runSpacing: 0,
                        children: [
                          Text(
                            _t('New to the community?', 'Bago sa komunidad?'),
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
                              minimumSize: const Size(0, 38),
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
  }) {
    final regularBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: _CivicColors.border),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF89948E), fontSize: 14),
      filled: true,
      fillColor: _CivicColors.input,
      prefixIcon: Icon(prefix, size: 21, color: _CivicColors.muted),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: regularBorder,
      enabledBorder: regularBorder,
      disabledBorder: regularBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(color: _CivicColors.green, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
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
      height: 40,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _CivicColors.border),
          foregroundColor: _CivicColors.ink,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              brandLetter,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: brandColor,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                providerName,
                overflow: TextOverflow.ellipsis,
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
    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          _t('KAISA  •  Lungsod ng Cavite', 'KAISA  •  Lungsod ng Cavite'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 11,
            letterSpacing: 0.3,
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const CircleAvatar(radius: 5, backgroundColor: _CivicColors.gold),
            const SizedBox(width: 10),
            Text(
              _t(
                'Connect • Participate • Make an Impact',
                'Makipag-ugnayan • Makilahok • Makiisa',
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Text(
          'Lungsod ng Cavite  •  Civic Engagement Portal',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.77),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
