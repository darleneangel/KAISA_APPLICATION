import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../widgets/kaisa_resident_design.dart';
import 'kaisa_organizations_repository.dart';
import 'kaisa_organization_widgets.dart';

class OrganizationDetailsPage extends StatefulWidget {
  const OrganizationDetailsPage({
    super.key,
    this.organizationId,
    required this.name,
    required this.category,
    required this.description,
    required this.members,
  });
  final String? organizationId;
  final String name, category, description;
  final int members;
  @override
  State<OrganizationDetailsPage> createState() =>
      _OrganizationDetailsPageState();
}

class _OrganizationDetailsPageState extends State<OrganizationDetailsPage> {
  KaisaOrganization? org;
  bool loading = true, busy = false, tier2 = false;
  String? error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted)
      setState(() {
        loading = true;
        error = null;
      });
    try {
      if (widget.organizationId == null || widget.organizationId!.isEmpty) {
        throw StateError('Missing organization ID. Check app_router.dart.');
      }
      final result = await Future.wait<dynamic>([
        KaisaOrganizationsRepository.instance.getOrganization(
          widget.organizationId!,
        ),
        KaisaOrganizationsRepository.instance.isTier2(),
      ]);
      if (!mounted) return;
      setState(() {
        org = result[0] as KaisaOrganization?;
        tier2 = result[1] == true;
        if (org == null) error = 'Organization unavailable or not published.';
      });
    } catch (e) {
      debugPrint('KAISA organization detail: $e');
      if (mounted)
        setState(
          () => error = e is StateError
              ? e.message
              : 'Unable to load organization details.',
        );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _notice(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _request() async {
    final current = org;
    if (current == null || busy) return;
    if (!tier2) {
      context.push('/resident/identity-verification');
      return;
    }
    final withdrawing = current.isPending;
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(
          withdrawing
              ? 'Withdraw membership request?'
              : 'Request to join ${current.name}?',
        ),
        content: Text(
          withdrawing
              ? 'Your pending application will be withdrawn.'
              : 'The organization will review your membership request. You will not be a member until approved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(withdrawing ? 'Withdraw' : 'Submit request'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() => busy = true);
    try {
      if (withdrawing) {
        await KaisaOrganizationsRepository.instance.withdrawRequest(current.id);
      } else {
        await KaisaOrganizationsRepository.instance.requestMembership(
          current.id,
        );
      }
      _notice(
        withdrawing
            ? 'Membership request withdrawn.'
            : 'Request submitted for review.',
      );
      await _load();
    } catch (e) {
      debugPrint('KAISA membership action: $e');
      _notice('Unable to update membership: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = org;
    return KaisaOrganizationPageFrame(
      child: ListView(
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: () => context.go('/resident/organizations'),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back to Organizations'),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Copy organization link',
                icon: const Icon(
                  Icons.share_outlined,
                  color: KaisaResidentDesign.green,
                ),
                onPressed: current == null
                    ? null
                    : () async {
                        final link = Uri.base
                            .replace(
                              path: '/resident/organizations',
                              fragment: '',
                            )
                            .toString();
                        await Clipboard.setData(
                          ClipboardData(text: '$link\n${current.name}'),
                        );
                        _notice('Organization reference copied.');
                      },
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(45),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (error != null)
            KaisaOrganizationEmpty(
              title: 'Organization unavailable',
              message: error!,
              action: TextButton(
                onPressed: _load,
                child: const Text('Try again'),
              ),
            )
          else if (current != null) ...[
            KaisaOrganizationHero(
              title: current.name,
              subtitle:
                  '${current.category}  •  ${current.memberCount} approved members',
            ),
            const SizedBox(height: 19),
            KaisaResidentCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KaisaResidentSectionHeading(
                    title: 'Join this community',
                    subtitle: tier2
                        ? 'Membership is subject to approval.'
                        : 'Tier 2 verification is required to apply.',
                  ),
                  const SizedBox(height: 14),
                  if (current.isMember)
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          color: KaisaResidentDesign.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Active ${current.myRole ?? 'Member'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: KaisaResidentDesign.forest,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: busy ? null : _request,
                        icon: Icon(
                          !tier2
                              ? Icons.shield_outlined
                              : current.isPending
                              ? Icons.close_rounded
                              : Icons.group_add_outlined,
                        ),
                        label: Text(
                          busy
                              ? 'Processing...'
                              : !tier2
                              ? 'Get Tier 2 verified'
                              : current.isPending
                              ? 'Withdraw pending request'
                              : 'Request to join',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: KaisaResidentDesign.forest,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 17),
            KaisaResidentCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const KaisaResidentSectionHeading(
                    title: 'About this organization',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    current.description.isEmpty
                        ? 'No description provided yet.'
                        : current.description,
                    style: const TextStyle(
                      color: KaisaResidentDesign.ink,
                      height: 1.55,
                    ),
                  ),
                  if (current.mission.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    const KaisaResidentSectionHeading(title: 'Mission'),
                    const SizedBox(height: 9),
                    Text(
                      current.mission,
                      style: const TextStyle(
                        color: KaisaResidentDesign.ink,
                        height: 1.55,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 17),
            KaisaResidentCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const KaisaResidentSectionHeading(
                    title: 'Contact & location',
                  ),
                  const SizedBox(height: 12),
                  if (current.location.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          color: KaisaResidentDesign.green,
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(current.location)),
                      ],
                    ),
                  if (current.contactEmail.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.alternate_email_outlined,
                            color: KaisaResidentDesign.green,
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: SelectableText(current.contactEmail)),
                        ],
                      ),
                    ),
                  if (current.location.isEmpty && current.contactEmail.isEmpty)
                    const Text(
                      'Contact information has not been published.',
                      style: TextStyle(color: KaisaResidentDesign.muted),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 17),
            KaisaResidentCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const KaisaResidentSectionHeading(
                    title: 'Community activities',
                    subtitle:
                        'Official events and updates will appear here once linked by LGU administrators.',
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/resident/events'),
                    icon: const Icon(Icons.event_outlined),
                    label: const Text('Explore events'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
