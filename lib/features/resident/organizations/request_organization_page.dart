import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/kaisa_resident_design.dart';
import 'kaisa_organizations_repository.dart';
import 'kaisa_organization_widgets.dart';

class RequestOrganizationPage extends StatefulWidget {
  const RequestOrganizationPage({super.key});
  @override
  State<RequestOrganizationPage> createState() =>
      _RequestOrganizationPageState();
}

class _RequestOrganizationPageState extends State<RequestOrganizationPage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      description = TextEditingController(),
      mission = TextEditingController(),
      representative = TextEditingController(),
      reason = TextEditingController();
  String category = 'Community';
  bool agreed = false, sending = false, loading = true, tier2 = false;
  String? error;
  static const categories = [
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
  void initState() {
    super.initState();
    _loadTier();
  }

  Future<void> _loadTier() async {
    if (mounted)
      setState(() {
        loading = true;
        error = null;
      });
    try {
      final approved = await KaisaOrganizationsRepository.instance.isTier2();
      if (mounted) setState(() => tier2 = approved);
    } catch (e) {
      debugPrint('KAISA proposal tier check: $e');
      if (mounted)
        setState(() => error = 'Unable to verify your current account tier.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    mission.dispose();
    representative.dispose();
    reason.dispose();
    super.dispose();
  }

  String? _required(String? text, int min, String label) =>
      (text ?? '').trim().length < min
      ? '$label must have at least $min characters'
      : null;
  Future<void> _send() async {
    if (sending || !form.currentState!.validate()) return;
    if (!agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Confirm that the information is accurate.'),
        ),
      );
      return;
    }
    setState(() => sending = true);
    try {
      await KaisaOrganizationsRepository.instance.propose(
        name: name.text.trim(),
        category: category,
        description: description.text.trim(),
        mission: mission.text.trim(),
        representative: representative.text.trim(),
        reason: reason.text.trim(),
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          icon: const Icon(
            Icons.mark_email_read_outlined,
            color: KaisaResidentDesign.green,
            size: 40,
          ),
          title: const Text('Proposal submitted'),
          content: const Text(
            'Your proposal is pending LGU review. No organization has been created yet.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (mounted) context.go('/resident/organizations');
    } catch (e) {
      debugPrint('KAISA proposal submission: $e');
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request could not be submitted: $e')),
        );
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => KaisaOrganizationPageFrame(
    child: ListView(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => context.go('/resident/organizations'),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Back to Organizations'),
          ),
        ),
        const SizedBox(height: 9),
        const KaisaOrganizationHeading(
          eyebrow: 'START SOMETHING',
          title: 'Propose an Organization',
          subtitle:
              'Send an idea for LGU review. Official groups are created by authorized administrators.',
        ),
        const SizedBox(height: 21),
        KaisaOrganizationHero(
          title: 'Your idea can grow here.',
          subtitle:
              'Help build community connections through a thoughtful proposal.',
        ),
        const SizedBox(height: 22),
        if (loading)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (error != null)
          KaisaOrganizationEmpty(
            title: 'Verification unavailable',
            message: error!,
            action: TextButton(
              onPressed: _loadTier,
              child: const Text('Retry'),
            ),
          )
        else if (!tier2)
          KaisaOrganizationEmpty(
            title: 'Tier 2 verification required',
            message:
                'Only verified Tier 2 residents may submit an organization proposal.',
            action: FilledButton.icon(
              onPressed: () => context.push('/resident/identity-verification'),
              icon: const Icon(Icons.shield_outlined),
              label: const Text('Get verified'),
            ),
          )
        else
          KaisaResidentCard(
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const KaisaResidentSectionHeading(
                    title: 'Organization information',
                    subtitle: 'Please complete all fields accurately.',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: name,
                    maxLength: 150,
                    decoration: const InputDecoration(
                      labelText: 'Proposed organization name *',
                    ),
                    validator: (v) => _required(v, 3, 'Name'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Category *'),
                    items: categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => category = v ?? category),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: description,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 300,
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                    ),
                    validator: (v) => _required(v, 20, 'Description'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: mission,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 300,
                    decoration: const InputDecoration(
                      labelText: 'Mission or purpose *',
                    ),
                    validator: (v) => _required(v, 5, 'Mission'),
                  ),
                  const SizedBox(height: 22),
                  const KaisaResidentSectionHeading(
                    title: 'Representative & rationale',
                  ),
                  const SizedBox(height: 13),
                  TextFormField(
                    controller: representative,
                    maxLength: 150,
                    decoration: const InputDecoration(
                      labelText: 'Representative name *',
                    ),
                    validator: (v) => _required(v, 3, 'Representative'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: reason,
                    minLines: 4,
                    maxLines: 6,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      labelText: 'Reason for request *',
                    ),
                    validator: (v) => _required(v, 30, 'Reason'),
                  ),
                  const SizedBox(height: 14),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: agreed,
                    onChanged: (v) => setState(() => agreed = v ?? false),
                    title: const Text(
                      'I confirm that the information is accurate and may be reviewed by the LGU.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: sending ? null : _send,
                      icon: sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_outlined),
                      label: Text(
                        sending ? 'Submitting...' : 'Submit proposal',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: KaisaResidentDesign.forest,
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  const Text(
                    'Submission does not grant organization ownership or admin access.',
                    style: TextStyle(
                      fontSize: 11,
                      color: KaisaResidentDesign.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 90),
      ],
    ),
  );
}
