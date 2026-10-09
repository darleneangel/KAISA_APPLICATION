import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class RequestOrganizationPage extends StatefulWidget {
  const RequestOrganizationPage({super.key});

  @override
  State<RequestOrganizationPage> createState() =>
      _RequestOrganizationPageState();
}

class _RequestOrganizationPageState
    extends State<RequestOrganizationPage> {
  final _formKey = GlobalKey<FormState>();

  final organizationNameController = TextEditingController();
  final descriptionController = TextEditingController();
  final missionController = TextEditingController();
  final representativeController = TextEditingController();
  final reasonController = TextEditingController();

  String? selectedCategory;

  bool agreedToTerms = false;
  bool isSubmitting = false;

  // ============================================================
  // PROTOTYPE ONLY
  //
  // true  = Tier 2 verified resident
  // false = Tier 1 resident
  //
  // Later this will come from the logged-in user's account.
  // ============================================================
  static const bool isTier2Verified = false;

  final List<String> categories = [
    'Youth',
    'Community',
    'Environment',
    'Education',
    'Sports',
    'Culture & Arts',
    'Health & Wellness',
    'Other',
  ];

  @override
  void dispose() {
    organizationNameController.dispose();
    descriptionController.dispose();
    missionController.dispose();
    representativeController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please confirm that the information provided is correct.',
          ),
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    // Prototype loading delay.
    // Later this is where the database request will happen.
    await Future.delayed(
      const Duration(milliseconds: 800),
    );

    if (!mounted) return;

    setState(() {
      isSubmitting = false;
    });

    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.hourglass_top_rounded,
            size: 46,
            color: AppColors.blue,
          ),
          title: const Text(
            'Request Submitted',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'Your organization request has been submitted for review. '
            'You will be notified once your request has been approved '
            'or rejected.',
            textAlign: TextAlign.center,
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.go('/resident/organizations');
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void _goToVerification() {
  context.push(
    '/resident/identity-verification',
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Request Organization',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: isTier2Verified
          ? _buildRequestForm()
          : _buildVerificationRequired(),
    );
  }

  // ============================================================
  // TIER 2 REQUEST FORM
  // ============================================================

  Widget _buildRequestForm() {
    return SafeArea(
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
              // --------------------------------------------------
              // INTRODUCTION
              // --------------------------------------------------

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.blueLight,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.blueDark,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Creating an organization requires approval. '
                        'Complete the information below and submit your '
                        'request for review.',
                        style: TextStyle(
                          color: AppColors.blueDark,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const _FormSectionTitle(
                title: 'Organization Information',
                subtitle:
                    'Tell us about the organization you want to establish.',
              ),

              const SizedBox(height: 18),

              // --------------------------------------------------
              // ORGANIZATION NAME
              // --------------------------------------------------

              TextFormField(
                controller: organizationNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Organization Name',
                  hintText: 'Enter organization name',
                  prefixIcon: Icon(
                    Icons.groups_2_outlined,
                  ),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Please enter an organization name.';
                  }

                  if (value.trim().length < 3) {
                    return 'Organization name is too short.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // --------------------------------------------------
              // CATEGORY
              // --------------------------------------------------

              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(
                    Icons.category_outlined,
                  ),
                ),
                hint: const Text(
                  'Select a category',
                ),
                items: categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a category.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // --------------------------------------------------
              // DESCRIPTION
              // --------------------------------------------------

              TextFormField(
                controller: descriptionController,
                minLines: 3,
                maxLines: 5,
                maxLength: 300,
                decoration: const InputDecoration(
                  labelText: 'Organization Description',
                  hintText:
                      'Briefly describe your proposed organization...',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Please provide an organization description.';
                  }

                  if (value.trim().length < 20) {
                    return 'Please provide a more detailed description.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 10),

              // --------------------------------------------------
              // MISSION
              // --------------------------------------------------

              TextFormField(
                controller: missionController,
                minLines: 3,
                maxLines: 5,
                maxLength: 300,
                decoration: const InputDecoration(
                  labelText: 'Mission / Purpose',
                  hintText:
                      'What does the organization aim to accomplish?',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Please provide the organization mission.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 24),

              // ==================================================
              // REPRESENTATIVE
              // ==================================================

              const _FormSectionTitle(
                title: 'Representative Information',
                subtitle:
                    'Provide the person responsible for this request.',
              ),

              const SizedBox(height: 18),

              TextFormField(
                controller: representativeController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Representative Name',
                  hintText: 'Full name',
                  prefixIcon: Icon(
                    Icons.person_outline_rounded,
                  ),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Please enter the representative name.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 24),

              // ==================================================
              // REASON
              // ==================================================

              const _FormSectionTitle(
                title: 'Reason for Request',
                subtitle:
                    'Explain why this organization should be established.',
              ),

              const SizedBox(height: 18),

              TextFormField(
                controller: reasonController,
                minLines: 4,
                maxLines: 7,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  hintText:
                      'Explain how this organization can benefit '
                      'the community...',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Please provide a reason for your request.';
                  }

                  if (value.trim().length < 30) {
                    return 'Please provide a more detailed reason.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 10),

              // ==================================================
              // REVIEW PROCESS
              // ==================================================

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
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What happens next?',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    SizedBox(height: 14),

                    _ProcessStep(
                      number: '1',
                      title: 'Submit Request',
                      description:
                          'Your organization proposal is submitted.',
                    ),

                    _ProcessDivider(),

                    _ProcessStep(
                      number: '2',
                      title: 'Request Review',
                      description:
                          'The request will be reviewed by the '
                          'authorized administrator.',
                    ),

                    _ProcessDivider(),

                    _ProcessStep(
                      number: '3',
                      title: 'Decision',
                      description:
                          'You will be notified if the request is '
                          'approved or rejected.',
                    ),

                    _ProcessDivider(),

                    _ProcessStep(
                      number: '4',
                      title: 'Organization Setup',
                      description:
                          'If approved, the organization can be '
                          'activated and administrative permissions '
                          'can be assigned.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // CONFIRMATION
              // ==================================================

              CheckboxListTile(
                value: agreedToTerms,
                contentPadding: EdgeInsets.zero,
                controlAffinity:
                    ListTileControlAffinity.leading,
                title: const Text(
                  'I confirm that the information provided is '
                  'accurate and complete.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    agreedToTerms = value ?? false;
                  });
                },
              ),

              const SizedBox(height: 20),

              // ==================================================
              // SUBMIT
              // ==================================================

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                      isSubmitting ? null : _submitRequest,
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
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
                        : 'Submit Request',
                  ),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Submitting a request does not automatically create '
                'or approve an organization.',
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
    );
  }

  // ============================================================
  // TIER 1 LOCKED SCREEN
  // ============================================================

  Widget _buildVerificationRequired() {
    return SafeArea(
      top: false,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: AppColors.blueLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  size: 48,
                  color: AppColors.blue,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Verification Required',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Only Tier 2 verified residents can request the '
                'creation of an organization.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Complete identity verification to unlock '
                'organization participation and creation requests.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.textMuted,
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _goToVerification,
                  icon: const Icon(
                    Icons.verified_outlined,
                  ),
                  label: const Text(
                    'Verify My Identity',
                  ),
                ),
              ),

              const SizedBox(height: 10),

              TextButton(
                onPressed: () => context.pop(),
                child: const Text(
                  'Maybe Later',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// FORM SECTION TITLE
// ============================================================================

class _FormSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _FormSectionTitle({
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

// ============================================================================
// PROCESS STEP
// ============================================================================

class _ProcessStep extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _ProcessStep({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.blueLight,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: AppColors.blueDark,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProcessDivider extends StatelessWidget {
  const _ProcessDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 13,
        top: 5,
        bottom: 5,
      ),
      child: Container(
        width: 2,
        height: 18,
        color: AppColors.border,
      ),
    );
  }
}