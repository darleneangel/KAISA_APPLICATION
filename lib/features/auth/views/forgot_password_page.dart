import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
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

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;

  bool _tagalog = false;
  String _t(String en, String tl) => _tagalog ? tl : en;

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
  void dispose() {
    _slideTimer?.cancel();
    _email.dispose();
    super.dispose();
  }

  Future<void> _sendRecoveryCode() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);

    try {
      final email = _email.text.trim();
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      context.go('/reset-password?email=${Uri.encodeComponent(email)}');
    } on AuthException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Unable to send your recovery code. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
                                  child: _buildRecoveryCard(isMobile: mobile),
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
            tooltip: _t('Back to login', 'Bumalik sa login'),
            onPressed: _busy ? null : () => context.go('/login'),
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

  Widget _buildRecoveryCard({required bool isMobile}) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 14 : 17),
        border: Border.all(color: _CivicColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1800301B),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 4,
            width: double.infinity,
            child: ColoredBox(color: _CivicColors.gold),
          ),
          Padding(
            padding: EdgeInsets.all(isMobile ? 14 : 20),
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _t('ACCOUNT RECOVERY', 'PAGBAWI NG ACCOUNT'),
                      style: GoogleFonts.inter(
                        color: _CivicColors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _t('Forgot your password?', 'Nakalimutan ang password?'),
                      style: GoogleFonts.outfit(
                        color: _CivicColors.forest,
                        fontSize: isMobile ? 22 : 26,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -.7,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _t(
                        'Enter your registered email to receive a recovery code.',
                        'Ilagay ang iyong rehistradong email upang makatanggap ng recovery code.',
                      ),
                      style: GoogleFonts.inter(
                        color: _CivicColors.muted,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _t('Email address', 'Email address'),
                      style: GoogleFonts.inter(
                        color: _CivicColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: _email,
                      enabled: !_busy,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.email],
                      autocorrect: false,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: _CivicColors.ink,
                      ),
                      onFieldSubmitted: (_) => _sendRecoveryCode(),
                      decoration: InputDecoration(
                        hintText: 'you@example.com',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 13,
                          color: _CivicColors.muted,
                        ),
                        prefixIcon: const Icon(
                          Icons.alternate_email_rounded,
                          color: _CivicColors.green,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: _CivicColors.input,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: _CivicColors.border,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: _CivicColors.green,
                            width: 1.8,
                          ),
                        ),
                        errorMaxLines: 3,
                      ),
                      validator: (value) {
                        final email = (value ?? '').trim();
                        if (!RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        ).hasMatch(email)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: _busy ? null : _sendRecoveryCode,
                      style: FilledButton.styleFrom(
                        backgroundColor: _CivicColors.forest,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    _t(
                                      'Send recovery code',
                                      'Ipadala ang recovery code',
                                    ),
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
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
                    const SizedBox(height: 5),
                    TextButton(
                      onPressed: _busy ? null : () => context.go('/login'),
                      child: Text(
                        _t(
                          'Remember your password? Log in',
                          'Naalala ang password? Mag-login',
                        ),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: _CivicColors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Divider(color: _CivicColors.border),
                    const SizedBox(height: 5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          color: _CivicColors.green,
                          size: 17,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            _t(
                              'Your password can only be changed after verifying your recovery code.',
                              'Maaari lamang baguhin ang password matapos ma-verify ang recovery code.',
                            ),
                            style: GoogleFonts.inter(
                              color: _CivicColors.muted,
                              fontSize: 11,
                              height: 1.45,
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
        ],
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
