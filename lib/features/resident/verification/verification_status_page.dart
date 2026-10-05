import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class VerificationStatusPage extends StatelessWidget {
  final String status;

  const VerificationStatusPage({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final statusLower = status.toLowerCase();

    final bool approved = statusLower == 'approved';
    final bool rejected = statusLower == 'rejected';

    final IconData icon = approved
        ? Icons.verified_rounded
        : rejected
            ? Icons.cancel_outlined
            : Icons.hourglass_top_rounded;

    final String title = approved
        ? 'Identity Verified'
        : rejected
            ? 'Verification Unsuccessful'
            : 'Verification Pending';

    final String description = approved
        ? 'Your identity has been verified. Your account now has '
            'Tier 2 access to KAISA community participation features.'
        : rejected
            ? 'Your verification request could not be approved. '
                'Review the provided information and submit a new request.'
            : 'Your identity verification request has been submitted '
                'and is currently awaiting review.';

    final Color statusColor = approved
        ? AppColors.greenDark
        : rejected
            ? AppColors.error
            : AppColors.blue;

    final Color statusBackground = approved
        ? AppColors.greenLight
        : AppColors.blueLight;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            context.go('/resident/profile');
          },
          icon: const Icon(
            Icons.close_rounded,
          ),
        ),
        title: const Text(
          'Verification Status',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),

              Container(
                width: 105,
                height: 105,
                decoration: BoxDecoration(
                  color: statusBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 50,
                  color: statusColor,
                ),
              ),

              const SizedBox(height: 25),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 30),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.border,
                  ),
                ),
                child: Column(
                  children: [
                    _StatusRow(
                      title: 'Request Status',
                      value: status,
                      valueColor: statusColor,
                    ),

                    const Divider(height: 28),

                    _StatusRow(
                      title: 'Current Access',
                      value: approved
                          ? 'Tier 2'
                          : 'Tier 1',
                    ),

                    if (!approved &&
                        !rejected) ...[
                      const Divider(height: 28),
                      const _StatusRow(
                        title: 'Next Step',
                        value: 'Awaiting Review',
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 22),

              if (!approved && !rejected)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: AppColors.blueLight,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.blueDark,
                      ),
                      SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          'You can continue using KAISA while your '
                          'request is being reviewed. Tier 2 features '
                          'will remain unavailable until approval.',
                          style: TextStyle(
                            color: AppColors.blueDark,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (approved)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: AppColors.greenLight,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.greenDark,
                      ),
                      SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          'You can now join organizations, register '
                          'for events, and request organizations.',
                          style: TextStyle(
                            color: AppColors.greenDark,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (rejected)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: AppColors.border,
                    ),
                  ),
                  child: const Text(
                    'Please review your information and ensure that '
                    'your identification document is valid and clearly '
                    'visible before submitting another request.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),

              const SizedBox(height: 28),

              if (rejected)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      context.go(
                        '/resident/identity-verification',
                      );
                    },
                    icon: const Icon(
                      Icons.refresh_rounded,
                    ),
                    label: const Text(
                      'Submit Again',
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      context.go('/resident/profile');
                    },
                    child: const Text(
                      'Back to Profile',
                    ),
                  ),
                ),

              const SizedBox(height: 10),

              if (!approved && !rejected)
                TextButton(
                  onPressed: () {
                    context.go('/resident/home');
                  },
                  child: const Text(
                    'Go to Home',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String title;
  final String value;
  final Color? valueColor;

  const _StatusRow({
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color:
                valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}