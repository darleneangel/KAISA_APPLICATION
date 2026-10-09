import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class IdentityVerificationPage extends StatefulWidget {
  const IdentityVerificationPage({super.key});

  @override
  State<IdentityVerificationPage> createState() =>
      _IdentityVerificationPageState();
}

class _IdentityVerificationPageState
    extends State<IdentityVerificationPage> {
  final _formKey = GlobalKey<FormState>();

  final fullNameController = TextEditingController(
    text: 'Darlene Custodio',
  );
  final addressController = TextEditingController();
  final idNumberController = TextEditingController();

  String? selectedIdType;
  bool informationConfirmed = false;
  bool isSubmitting = false;

  final List<String> acceptedIds = [
    'Philippine National ID',
    'Driver\'s License',
    'Passport',
    'UMID',
    'Postal ID',
    'Voter\'s ID',
    'Other Government-Issued ID',
  ];

  @override
  void dispose() {
    fullNameController.dispose();
    addressController.dispose();
    idNumberController.dispose();
    super.dispose();
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!informationConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please confirm that the information you provided is correct.',
          ),
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    // PROTOTYPE ONLY.
    // Later, this is where the verification request
    // will be inserted into Supabase.
    await Future.delayed(
      const Duration(milliseconds: 900),
    );

    if (!mounted) return;

    setState(() {
      isSubmitting = false;
    });

    _showSubmissionConfirmation();
  }

  void _showSubmissionConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.verified_user_outlined,
            size: 46,
            color: AppColors.blue,
          ),
          title: const Text(
            'Submit Verification?',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'Your identity information will be submitted for review. '
            'Your account will remain Tier 1 while verification is pending.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Review'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                context.go(
                  '/resident/verification-status',
                  extra: {
                    'status': 'Pending',
                  },
                );
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _showIdUploadInfo() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            24,
            10,
            24,
            32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.blueLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_a_photo_outlined,
                  color: AppColors.blue,
                  size: 30,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Valid ID Upload',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'For the prototype, document upload is not connected yet. '
                'When the database and storage are connected, residents '
                'will upload a clear image of their selected valid ID here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                  },
                  child: const Text('Got It'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'Identity Verification',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              50,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==============================================
                // HEADER
                // ==============================================

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.blue,
                        AppColors.blueDark,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        color: Colors.white,
                        size: 34,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Become a Tier 2 Resident',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Verify your identity to unlock community '
                        'participation features in KAISA.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // ==============================================
                // BENEFITS
                // ==============================================

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.border,
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tier 2 Access',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 13),
                      _BenefitItem(
                        icon: Icons.groups_outlined,
                        text: 'Join community organizations',
                      ),
                      SizedBox(height: 10),
                      _BenefitItem(
                        icon: Icons.event_available_outlined,
                        text: 'Register for community events',
                      ),
                      SizedBox(height: 10),
                      _BenefitItem(
                        icon: Icons.add_business_outlined,
                        text: 'Request a new organization',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                const _SectionHeader(
                  title: 'Personal Information',
                  subtitle:
                      'Make sure your information matches your valid ID.',
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: fullNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(
                      Icons.person_outline_rounded,
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter your full name.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: addressController,
                  textCapitalization: TextCapitalization.words,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Residential Address',
                    hintText: 'Enter your complete address',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(
                      Icons.home_outlined,
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter your residential address.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 28),

                // ==============================================
                // ID INFORMATION
                // ==============================================

                const _SectionHeader(
                  title: 'Valid ID',
                  subtitle:
                      'Provide a government-issued identification document.',
                ),

                const SizedBox(height: 18),

                DropdownButtonFormField<String>(
                  initialValue: selectedIdType,
                  decoration: const InputDecoration(
                    labelText: 'ID Type',
                    prefixIcon: Icon(
                      Icons.badge_outlined,
                    ),
                  ),
                  hint: const Text(
                    'Select valid ID',
                  ),
                  items: acceptedIds.map((id) {
                    return DropdownMenuItem<String>(
                      value: id,
                      child: Text(id),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedIdType = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select an ID type.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: idNumberController,
                  decoration: const InputDecoration(
                    labelText: 'ID Number',
                    hintText: 'Enter identification number',
                    prefixIcon: Icon(
                      Icons.numbers_rounded,
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter your ID number.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // ==============================================
                // ID UPLOAD PLACEHOLDER
                // ==============================================

                InkWell(
                  onTap: _showIdUploadInfo,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.border,
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 38,
                          color: AppColors.blue,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Upload Valid ID',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Tap to add a clear photo of your ID',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Prototype placeholder',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 26),

                // ==============================================
                // REVIEW PROCESS
                // ==============================================

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.blueLight,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verification Process',
                        style: TextStyle(
                          color: AppColors.blueDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 14),
                      _VerificationStep(
                        number: '1',
                        text: 'Submit your information and valid ID',
                      ),
                      SizedBox(height: 12),
                      _VerificationStep(
                        number: '2',
                        text: 'Your request is reviewed',
                      ),
                      SizedBox(height: 12),
                      _VerificationStep(
                        number: '3',
                        text:
                            'You receive an approval or rejection notification',
                      ),
                      SizedBox(height: 12),
                      _VerificationStep(
                        number: '4',
                        text:
                            'Approved accounts are upgraded to Tier 2',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                CheckboxListTile(
                  value: informationConfirmed,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity:
                      ListTileControlAffinity.leading,
                  title: const Text(
                    'I confirm that the information provided is '
                    'accurate and belongs to me.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      informationConfirmed =
                          value ?? false;
                    });
                  },
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: isSubmitting
                        ? null
                        : _submitVerification,
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.send_outlined,
                          ),
                    label: Text(
                      isSubmitting
                          ? 'Submitting...'
                          : 'Submit for Verification',
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Submitting a verification request does not '
                  'immediately upgrade your account to Tier 2.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SECTION HEADER
// ============================================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 19,
          color: AppColors.blue,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _VerificationStep extends StatelessWidget {
  final String number;
  final String text;

  const _VerificationStep({
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 25,
          height: 25,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.blue,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.blueDark,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}