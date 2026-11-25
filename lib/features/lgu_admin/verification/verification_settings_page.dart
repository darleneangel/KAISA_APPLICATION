import 'package:flutter/material.dart';
import '../layout/lgu_role_settings_view.dart';


/// Verification Admin settings, aligned with Operations and IT settings.
class VerificationSettingsPage extends StatelessWidget {
  const VerificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) => const LguRoleSettingsView(
    roleName: 'Verification',
    roleCode: 'lgu_verification_admin',
    subtitle:
        'Personal verification-review preferences and guidance for handling sensitive evidence.',
    options: [
      LguSettingOption(
        'queue',
        'New application alerts',
        'Local preference for resident and organization requests.',
        Icons.pending_actions_outlined,
      ),
      LguSettingOption(
        'manual',
        'Manual-review referrals',
        'Local preference for flagged or inconclusive AI-assisted screenings.',
        Icons.person_search_outlined,
      ),
      LguSettingOption(
        'resubmission',
        'Resubmission updates',
        'Local preference for corrected evidence and re-review reminders.',
        Icons.refresh_outlined,
      ),
    ],
    responsibilities: [
      LguResponsibility(
        'Resident identity review',
        'Review appropriate ID/selfie and account eligibility evidence.',
        Icons.badge_outlined,
      ),
      LguResponsibility(
        'Organization accreditation',
        'Validate submitted organizational documents and representatives.',
        Icons.apartment_rounded,
      ),
      LguResponsibility(
        'Manual referral decisions',
        'Resolve uncertain AI-screening outcomes without automatic rejection.',
        Icons.fact_check_outlined,
      ),
      LguResponsibility(
        'Decision audit history',
        'Document review rationales and archive completed cases appropriately.',
        Icons.history_outlined,
      ),
    ],
    safeguards: [
      'ID photographs and selfies require private storage and authorization checks.',
      'AI face similarity is advisory; failed or uncertain screening requires an appropriate human process.',
      'Verification decisions must be logged by the backend; IT manages account-level enforcement.',
    ],
  );
}
