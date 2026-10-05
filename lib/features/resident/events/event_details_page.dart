import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class EventDetailsPage extends StatefulWidget {
  final String title;
  final String organization;
  final String category;
  final String description;
  final String date;
  final String time;
  final String location;
  final int participants;
  final int capacity;

  const EventDetailsPage({
    super.key,
    required this.title,
    required this.organization,
    required this.category,
    required this.description,
    required this.date,
    required this.time,
    required this.location,
    required this.participants,
    required this.capacity,
  });

  @override
  State<EventDetailsPage> createState() =>
      _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  // ============================================================
  // PROTOTYPE ONLY
  //
  // false = Tier 1
  // true  = Tier 2
  //
  // Later this will come from the logged-in resident.
  // ============================================================
  static const bool isTier2Verified = false;

  bool isRegistered = false;

  bool get isFull =>
      widget.participants >= widget.capacity;

  int get availableSlots {
    final slots =
        widget.capacity - widget.participants;

    return slots < 0 ? 0 : slots;
  }

  void _handleRegistration() {
    if (!isTier2Verified) {
      _showVerificationRequired();
      return;
    }

    if (isFull) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Registration is no longer available because this event is full.',
          ),
        ),
      );
      return;
    }

    if (isRegistered) {
      _showCancelRegistration();
      return;
    }

    _showRegistrationConfirmation();
  }

  void _showVerificationRequired() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.verified_user_outlined,
            size: 44,
            color: AppColors.blue,
          ),
          title: const Text(
            'Identity Verification Required',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'You need a Tier 2 verified account before you can '
            'register for community events.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Not Now'),
            ),
            FilledButton(
              onPressed: () {
                  Navigator.pop(dialogContext);

                  context.push(
                    '/resident/identity-verification',
                  );
                },
              child: const Text('Get Verified'),
            ),
          ],
        );
      },
    );
  }

  void _showRegistrationConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.event_available_outlined,
            size: 44,
            color: AppColors.greenDark,
          ),
          title: const Text(
            'Register for Event?',
            textAlign: TextAlign.center,
          ),
          content: Text(
            'Would you like to register for "${widget.title}"?',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                setState(() {
                  isRegistered = true;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'You have successfully registered for this event.',
                    ),
                  ),
                );
              },
              child: const Text('Register'),
            ),
          ],
        );
      },
    );
  }

  void _showCancelRegistration() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Cancel Registration?',
          ),
          content: Text(
            'Are you sure you want to cancel your registration '
            'for "${widget.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Keep Registration'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                setState(() {
                  isRegistered = false;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Your event registration has been cancelled.',
                    ),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
              child: const Text(
                'Cancel Registration',
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double progress =
        widget.capacity == 0
            ? 0
            : (widget.participants /
                    widget.capacity)
                .clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
        ),
        title: const Text(
          'Event Details',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Share Event',
            onPressed: () {
              // Share functionality later.
            },
            icon: const Icon(
              Icons.share_outlined,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          bottom: 130,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ==================================================
            // EVENT HEADER
            // ==================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                24,
                32,
                24,
                32,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.blue,
                    AppColors.blueDark,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          Colors.white.withOpacity(
                        0.16,
                      ),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Icon(
                        Icons.groups_outlined,
                        size: 18,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'Hosted by ${widget.organization}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // ============================================
                  // EVENT INFORMATION
                  // ============================================

                  const Text(
                    'Event Information',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 14),

                  _InfoCard(
                    icon:
                        Icons.calendar_month_outlined,
                    title: 'Date',
                    value: widget.date,
                  ),

                  const SizedBox(height: 10),

                  _InfoCard(
                    icon: Icons.schedule_outlined,
                    title: 'Time',
                    value: widget.time,
                  ),

                  const SizedBox(height: 10),

                  _InfoCard(
                    icon:
                        Icons.location_on_outlined,
                    title: 'Location',
                    value: widget.location,
                  ),

                  const SizedBox(height: 30),

                  // ============================================
                  // ABOUT
                  // ============================================

                  const Text(
                    'About This Event',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    widget.description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color:
                          AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ============================================
                  // PARTICIPATION
                  // ============================================

                  const Text(
                    'Participation',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.border,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons
                                  .people_outline_rounded,
                              color: AppColors.blue,
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Text(
                                '${widget.participants} of '
                                '${widget.capacity} registered',
                                style: const TextStyle(
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                              ),
                            ),

                            Text(
                              isFull
                                  ? 'Full'
                                  : '$availableSlots slots left',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w700,
                                color: isFull
                                    ? AppColors.error
                                    : AppColors
                                        .greenDark,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(
                            20,
                          ),
                          child:
                              LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor:
                                AppColors.blueLight,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ============================================
                  // REGISTERED STATE
                  // ============================================

                  if (isRegistered) ...[
                    const SizedBox(height: 20),

                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            AppColors.greenLight,
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons
                                .check_circle_outline_rounded,
                            color:
                                AppColors.greenDark,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'You are registered for this event.',
                              style: TextStyle(
                                color:
                                    AppColors.greenDark,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ============================================
                  // TIER 1 INFORMATION
                  // ============================================

                  if (!isTier2Verified) ...[
                    const SizedBox(height: 20),

                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.blueLight,
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                      child: const Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons
                                .lock_outline_rounded,
                            color:
                                AppColors.blueDark,
                          ),
                          SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  'Tier 2 verification required',
                                  style: TextStyle(
                                    color: AppColors
                                        .blueDark,
                                    fontWeight:
                                        FontWeight
                                            .w700,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'You can view this event, '
                                  'but identity verification '
                                  'is required before registering.',
                                  style: TextStyle(
                                    color: AppColors
                                        .blueDark,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),

                  // ============================================
                  // HOST ORGANIZATION
                  // ============================================

                  const Text(
                    'Hosted By',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color:
                                AppColors.blueLight,
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                          ),
                          child: const Icon(
                            Icons.groups_2_outlined,
                            color: AppColors.blue,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            widget.organization,
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ),

                        const Icon(
                          Icons.chevron_right_rounded,
                          color:
                              AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // ========================================================
      // REGISTRATION BUTTON
      // ========================================================

      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            12,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(
                color: AppColors.border,
              ),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            child: isRegistered
                ? OutlinedButton.icon(
                    onPressed:
                        _handleRegistration,
                    icon: const Icon(
                      Icons
                          .event_busy_outlined,
                    ),
                    label: const Text(
                      'Cancel Registration',
                    ),
                  )
                : FilledButton.icon(
                    onPressed: isFull
                        ? null
                        : _handleRegistration,
                    icon: Icon(
                      isTier2Verified
                          ? Icons
                              .event_available_outlined
                          : Icons
                              .lock_outline_rounded,
                    ),
                    label: Text(
                      isFull
                          ? 'Event Full'
                          : 'Register for Event',
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// INFORMATION CARD
// ============================================================================

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.blueLight,
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 21,
              color: AppColors.blue,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color:
                        AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        AppColors.textPrimary,
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