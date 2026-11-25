import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Project draft; requires operator/data protection officer approval.
/// Returns explicit consent only; does not modify authentication or Supabase.
class KaisaTermsPrivacyDialog extends StatefulWidget {
  const KaisaTermsPrivacyDialog({super.key, this.initiallyAccepted = false});
  final bool initiallyAccepted;

  static Future<bool?> show(
    BuildContext context, {
    bool initiallyAccepted = false,
  }) => showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        KaisaTermsPrivacyDialog(initiallyAccepted: initiallyAccepted),
  );

  @override
  State<KaisaTermsPrivacyDialog> createState() =>
      _KaisaTermsPrivacyDialogState();
}

class _KaisaTermsPrivacyDialogState extends State<KaisaTermsPrivacyDialog> {
  static const _forest = Color(0xFF00492C);
  static const _ink = Color(0xFF192F25);
  static const _muted = Color(0xFF52645A);
  static const _border = Color(0xFFE0E8E2);
  final _scroll = ScrollController();
  late bool _accepted;

  @override
  void initState() {
    super.initState();
    _accepted = widget.initiallyAccepted;
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 610;
    final inset = compact ? 16.0 : 32.0;
    final pad = compact ? 14.0 : 20.0;
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: inset, vertical: 12),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: (size.width - inset * 2).clamp(0.0, 460.0).toDouble(),
        height: (size.height - 24).clamp(0.0, 500.0).toDouble(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(
              height: 5,
              child: ColoredBox(color: Color(0xFFFDBC19)),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(pad, 12, 8, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Terms & Privacy Notice',
                      style: GoogleFonts.outfit(
                        color: _forest,
                        fontSize: compact ? 19 : 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close policy',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: _forest),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _border),
            Expanded(
              child: Scrollbar(
                controller: _scroll,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scroll,
                  padding: EdgeInsets.fromLTRB(pad, 12, pad, 16),
                  child: SelectionArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Please review how KAISA accounts work and how resident information is handled before creating your account.',
                          style: GoogleFonts.inter(
                            color: _muted,
                            fontSize: 13,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Policy draft — subject to KAISA project/operator review',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF795600),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 22),
                        _heading('Terms of Use'),
                        const SizedBox(height: 16),
                        for (final section in _terms) _section(section),
                        const Divider(color: _border),
                        const SizedBox(height: 16),
                        _heading('Privacy Notice'),
                        const SizedBox(height: 16),
                        for (final section in _privacy) _section(section),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: _border),
            Padding(
              padding: EdgeInsets.fromLTRB(pad, 4, pad, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _accepted,
                        activeColor: _forest,
                        onChanged: (value) =>
                            setState(() => _accepted = value ?? false),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _accepted = !_accepted),
                          child: Text(
                            "I have read and agree to KAISA's Terms of Use and Privacy Notice.",
                            style: GoogleFonts.inter(
                              color: _ink,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _forest,
                          minimumSize: const Size(0, 46),
                        ),
                        child: Text(
                          'Decline',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: _accepted
                              ? () => Navigator.of(context).pop(true)
                              : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: _forest,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          child: Text(
                            'Accept',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heading(String title) => Text(
    title,
    style: GoogleFonts.outfit(
      color: _forest,
      fontSize: 19,
      fontWeight: FontWeight.w700,
    ),
  );

  Widget _section((String, String) section) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.$1,
          style: GoogleFonts.outfit(
            color: _ink,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          section.$2,
          style: GoogleFonts.inter(color: _muted, fontSize: 13, height: 1.65),
        ),
      ],
    ),
  );

  static const _terms = <(String, String)>[
    (
      'Account Registration & Eligibility',
      'KAISA connects residents with community programs, organizations, events, and civic opportunities. To register, provide an email address you can access and accurate profile information. Some features may require additional resident or identity verification.',
    ),
    (
      'Keeping Your Account Secure',
      'Keep your KAISA password and one-time verification codes private. Do not share your account or impersonate another person. If you suspect unauthorized access, change your password and contact the KAISA administrators through their published support channel.',
    ),
    (
      'Responsible Community Participation',
      'When using KAISA feeds, events, and organizations, provide truthful information, respect other residents, and avoid harassment, fraud, spam, malicious links, or misleading participation records. Community posts and registrations may be reviewed according to platform rules.',
    ),
    (
      'Events, Organizations & Account Access',
      'Event participation, organization membership, and access to specific features may depend on eligibility, approval, or identity-verification status. KAISA may restrict access to protect residents and platform integrity, subject to its adopted operating procedures.',
    ),
    (
      'Changes, Support & Agreement',
      'Platform features and these terms may be updated as the KAISA project develops. The operator should publish the effective version and a support or privacy contact before deployment. By accepting, you agree to follow the applicable terms while using KAISA.',
    ),
  ];

  static const _privacy = <(String, String)>[
    (
      'Information KAISA Collects',
      'During registration and profile setup, KAISA may collect your email address, name, birth date, gender, mobile number, province, city or municipality, barangay, street address, ZIP code, community interests, and skills. Later features may ask for additional information when resident verification or participation requires it.',
    ),
    (
      'How Information Is Used',
      'The application uses account information to authenticate users, verify email ownership, maintain resident profiles, support event and organization participation, provide community features, and administer access according to resident or administrator roles.',
    ),
    (
      'Authentication & Service Providers',
      'KAISA uses Supabase for authentication and application data operations in its current implementation. Google and Facebook authentication, when selected, is handled through the relevant provider and Supabase integration. Passwords are handled by the authentication service rather than being saved as plain-text profile fields.',
    ),
    (
      'Access, Disclosure & Protection',
      'Personal information should be accessible only to authorized users and administrators for legitimate KAISA operations, subject to appropriate access rules and database security policies. The final deployed privacy notice must identify the actual data-sharing practices, retention periods, and safeguards approved by the operator.',
    ),
    (
      'Your Privacy Choices & Requests',
      'Residents should be given a way to request access to or correction of their personal data and raise privacy concerns through the official KAISA contact channel. Requests to delete or restrict data are handled according to applicable law and the final approved retention policy. Do not share passwords or one-time codes in support messages.',
    ),
  ];
}
