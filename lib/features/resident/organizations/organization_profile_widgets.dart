import 'package:flutter/material.dart';

import '../widgets/kaisa_resident_design.dart';
import 'kaisa_organizations_repository.dart';

class OrganizationImage extends StatelessWidget {
  const OrganizationImage({
    super.key,
    required this.reference,
    required this.icon,
  });

  final String? reference;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final fallback = DecoratedBox(
      decoration: const BoxDecoration(
        gradient: KaisaResidentDesign.heroGradient,
      ),
      child: Center(child: Icon(icon, size: 38, color: Colors.white)),
    );
    final source = reference;
    if (source == null || source.isEmpty) return fallback;
    if (RegExp(r'^assets/images/cavite/[a-zA-Z0-9_\-.]+$').hasMatch(source)) {
      return Image.asset(
        source,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    final url = Uri.tryParse(source);
    if (url?.scheme != 'https' || url!.host.isEmpty) return fallback;
    return Image.network(
      url.toString(),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

class OrganizationFollowButton extends StatefulWidget {
  const OrganizationFollowButton({
    super.key,
    required this.organizationId,
    required this.following,
  });

  final String organizationId;
  final bool following;

  @override
  State<OrganizationFollowButton> createState() =>
      _OrganizationFollowButtonState();
}

class _OrganizationFollowButtonState extends State<OrganizationFollowButton> {
  late bool _following = widget.following;
  bool _saving = false;

  @override
  void didUpdateWidget(OrganizationFollowButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.following != widget.following) _following = widget.following;
  }

  Future<void> _toggle() async {
    final next = !_following;
    setState(() => _saving = true);
    try {
      await KaisaOrganizationsRepository.instance.setFollowing(
        widget.organizationId,
        next,
      );
      if (mounted) setState(() => _following = next);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update Follow. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: _saving ? null : _toggle,
    icon: Icon(
      _following ? Icons.check : Icons.person_add_alt_1_outlined,
      size: 17,
    ),
    label: Text(
      _saving
          ? 'Saving…'
          : _following
          ? 'Following'
          : 'Follow',
    ),
  );
}
