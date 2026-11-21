import 'package:flutter/material.dart';

/// UI-only acceptance document for KAISA registration.
///
/// IMPORTANT: The wording below is a PROJECT DRAFT and must be approved by
/// the KAISA operator / data protection officer before production deployment.
/// Acceptance is returned to the calling page; this widget does not write to
/// Supabase or alter the authentication/database schema.
class KaisaTermsPrivacyDialog extends StatefulWidget {
  const KaisaTermsPrivacyDialog({super.key, this.initiallyAccepted = false});

  final bool initiallyAccepted;

  /// true = explicitly accepted, false = explicitly declined,
  /// null = closed without changing the existing decision.
  static Future<bool?> show(
    BuildContext context, {
    bool initiallyAccepted = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          KaisaTermsPrivacyDialog(initiallyAccepted: initiallyAccepted),
    );
  }

  @override
  State<KaisaTermsPrivacyDialog> createState() =>
      _KaisaTermsPrivacyDialogState();
}

class _KaisaTermsPrivacyDialogState extends State<KaisaTermsPrivacyDialog> {
  static const _forest = Color(0xFF00492C);
  static const _forestDeep = Color(0xFF00301B);
  static const _ink = Color(0xFF192F25);
  static const _muted = Color(0xFF667970);
  static const _border = Color(0xFFE0E8E2);

  late bool _accepted;
  int _tab = 0; // 0: Terms of Use, 1: Privacy Notice.

  @override
  void initState() {
    super.initState();
    _accepted = widget.initiallyAccepted;
  }

  void _close() => Navigator.of(context).pop();
  void _decline() => Navigator.of(context).pop(false);
  void _accept() {
    if (_accepted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 610;
    final horizontalInset = compact ? 10.0 : 26.0;
    final verticalInset = compact ? 10.0 : 25.0;
    final maxWidth = (size.width - horizontalInset * 2)
        .clamp(0.0, 900.0)
        .toDouble();
    final maxHeight = (size.height - verticalInset * 2)
        .clamp(0.0, 800.0)
        .toDouble();

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: horizontalInset,
        vertical: verticalInset,
      ),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: maxWidth,
        height: maxHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(compact),
            const Divider(height: 1, color: _border),
            _tabStrip(compact),
            const Divider(height: 1, color: _border),
            Expanded(
              child: Scrollbar(
                key: ValueKey<int>(_tab),
                thumbVisibility: false,
                child: SingleChildScrollView(
                  key: ValueKey<String>('policy_$_tab'),
                  padding: EdgeInsets.fromLTRB(
                    compact ? 18 : 32,
                    22,
                    compact ? 18 : 32,
                    28,
                  ),
                  child: _tab == 0 ? _terms() : _privacy(),
                ),
              ),
            ),
            _footer(compact),
          ],
        ),
      ),
    );
  }

  Widget _header(bool compact) => Padding(
    padding: EdgeInsets.fromLTRB(
      compact ? 16 : 28,
      compact ? 15 : 22,
      compact ? 12 : 22,
      compact ? 15 : 22,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 37,
              height: 37,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _forest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'K',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KAISA',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: _ink,
                    ),
                  ),
                  Text(
                    'Community Engagement Platform',
                    style: TextStyle(fontSize: 10.5, color: _muted),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Close policy',
              onPressed: _close,
              icon: const Icon(Icons.close_rounded, color: _ink),
            ),
          ],
        ),
        const SizedBox(height: 17),
        const Text(
          'Terms & Privacy Notice',
          style: TextStyle(
            color: _forestDeep,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.45,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Please review how KAISA accounts work and how resident information is handled before creating your account.',
          style: TextStyle(fontSize: 12.5, height: 1.5, color: _muted),
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5DC),
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF795600),
                  size: 15,
                ),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Policy draft — subject to KAISA project/operator review',
                    style: TextStyle(
                      color: Color(0xFF795600),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _tabStrip(bool compact) => Padding(
    padding: EdgeInsets.symmetric(horizontal: compact ? 13 : 25, vertical: 11),
    child: Row(
      children: [
        Expanded(
          child: _tabButton(
            0,
            icon: Icons.gavel_rounded,
            label: compact ? 'Terms' : 'Terms of Use',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _tabButton(
            1,
            icon: Icons.shield_outlined,
            label: compact ? 'Privacy' : 'Privacy Notice',
          ),
        ),
      ],
    ),
  );

  Widget _tabButton(
    int index, {
    required IconData icon,
    required String label,
  }) {
    final selected = _tab == index;
    return Material(
      color: selected ? _forest : const Color(0xFFF2F5F3),
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: () => setState(() => _tab = index),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? Colors.white : _forest, size: 16),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? Colors.white : _ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _terms() => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _PolicySection(
        number: '01',
        heading: 'Account Registration & Eligibility',
        body:
            'KAISA connects residents with community programs, organizations, events, and civic opportunities. To register, provide an email address you can access and accurate profile information. Some features may require additional resident or identity verification.',
      ),
      _PolicySection(
        number: '02',
        heading: 'Keeping Your Account Secure',
        body:
            'Keep your KAISA password and one-time verification codes private. Do not share your account or impersonate another person. If you suspect unauthorized access, change your password and contact the KAISA administrators through their published support channel.',
      ),
      _PolicySection(
        number: '03',
        heading: 'Responsible Community Participation',
        body:
            'When using KAISA feeds, events, and organizations, provide truthful information, respect other residents, and avoid harassment, fraud, spam, malicious links, or misleading participation records. Community posts and registrations may be reviewed according to platform rules.',
      ),
      _PolicySection(
        number: '04',
        heading: 'Events, Organizations & Account Access',
        body:
            'Event participation, organization membership, and access to specific features may depend on eligibility, approval, or identity-verification status. KAISA may restrict access to protect residents and platform integrity, subject to its adopted operating procedures.',
      ),
      _PolicySection(
        number: '05',
        heading: 'Changes, Support & Agreement',
        body:
            'Platform features and these terms may be updated as the KAISA project develops. The operator should publish the effective version and a support or privacy contact before deployment. By accepting, you agree to follow the applicable terms while using KAISA.',
        last: true,
      ),
    ],
  );

  Widget _privacy() => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _PolicySection(
        number: '01',
        heading: 'Information KAISA Collects',
        body:
            'During registration and profile setup, KAISA may collect your email address, name, birth date, gender, mobile number, province, city or municipality, barangay, street address, ZIP code, community interests, and skills. Later features may ask for additional information when resident verification or participation requires it.',
      ),
      _PolicySection(
        number: '02',
        heading: 'How Information Is Used',
        body:
            'The application uses account information to authenticate users, verify email ownership, maintain resident profiles, support event and organization participation, provide community features, and administer access according to resident or administrator roles.',
      ),
      _PolicySection(
        number: '03',
        heading: 'Authentication & Service Providers',
        body:
            'KAISA uses Supabase for authentication and application data operations in its current implementation. Google and Facebook authentication, when selected, is handled through the relevant provider and Supabase integration. Passwords are handled by the authentication service rather than being saved as plain-text profile fields.',
      ),
      _PolicySection(
        number: '04',
        heading: 'Access, Disclosure & Protection',
        body:
            'Personal information should be accessible only to authorized users and administrators for legitimate KAISA operations, subject to appropriate access rules and database security policies. The final deployed privacy notice must identify the actual data-sharing practices, retention periods, and safeguards approved by the operator.',
      ),
      _PolicySection(
        number: '05',
        heading: 'Your Privacy Choices & Requests',
        body:
            'Residents should be given a way to request access to or correction of their personal data and raise privacy concerns through the official KAISA contact channel. Requests to delete or restrict data are handled according to applicable law and the final approved retention policy. Do not share passwords or one-time codes in support messages.',
        last: true,
      ),
    ],
  );

  Widget _footer(bool compact) => Container(
    padding: EdgeInsets.fromLTRB(
      compact ? 13 : 27,
      12,
      compact ? 13 : 27,
      compact ? 14 : 21,
    ),
    decoration: const BoxDecoration(
      color: Color(0xFFF3F6F3),
      border: Border(top: BorderSide(color: _border)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => setState(() => _accepted = !_accepted),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Checkbox(
                  value: _accepted,
                  activeColor: _forest,
                  onChanged: (value) =>
                      setState(() => _accepted = value ?? false),
                ),
                const Expanded(
                  child: Text(
                    'I have read and agree to KAISA\'s Terms of Use and Privacy Notice.',
                    style: TextStyle(color: _ink, fontSize: 12, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (compact)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                onPressed: _accepted ? _accept : null,
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                label: const Text('I Agree & Continue'),
                style: FilledButton.styleFrom(
                  backgroundColor: _forest,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF98ADA1),
                  minimumSize: const Size.fromHeight(44),
                ),
              ),
              TextButton(onPressed: _decline, child: const Text('Decline')),
            ],
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: _decline,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _ink,
                  side: const BorderSide(color: _border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 13,
                  ),
                ),
                child: const Text('Decline'),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: _accepted ? _accept : null,
                icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                label: const Text('I Agree & Continue'),
                style: FilledButton.styleFrom(
                  backgroundColor: _forest,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF98ADA1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 13,
                  ),
                ),
              ),
            ],
          ),
      ],
    ),
  );
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    required this.number,
    required this.heading,
    required this.body,
    this.last = false,
  });

  final String number;
  final String heading;
  final String body;
  final bool last;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 27,
            height: 27,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF00492C),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                heading,
                style: const TextStyle(
                  color: Color(0xFF00301B),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 9),
      Text(
        body,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF42564A),
          height: 1.62,
        ),
      ),
      if (!last) ...[
        const SizedBox(height: 23),
        const Divider(height: 1, color: Color(0xFFE3EBE6)),
        const SizedBox(height: 21),
      ],
    ],
  );
}
