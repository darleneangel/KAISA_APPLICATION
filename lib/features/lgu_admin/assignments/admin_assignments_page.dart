import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/organization_model.dart';
import '../../../shared/repositories/organization_repository.dart';
import '../../../shared/models/audit_log_model.dart';
import '../../../shared/repositories/audit_log_repository.dart';

const _forest = Color(0xFF00492C);
const _green = Color(0xFF287D55);
const _gold = Color(0xFFFBBA16);
const _paper = Color(0xFFF6F8F5);
const _ink = Color(0xFF173D2B);
const _muted = Color(0xFF687B70);
const _stroke = Color(0xFFE2EBE4);
const _mint = Color(0xFFEAF5EE);

/// Operations assignment workflow — in-memory prototype.
/// An assignment is a recorded representative email, NOT an Auth role grant.
/// Real account authorization must be verified and applied by a trusted backend.
class AdminAssignmentsPage extends StatefulWidget {
  const AdminAssignmentsPage({super.key});

  @override
  State<AdminAssignmentsPage> createState() => _AdminAssignmentsPageState();
}

class _AdminAssignmentsPageState extends State<AdminAssignmentsPage> {
  final OrganizationRepository _organizations = OrganizationRepository.instance;
  final AuditLogRepository _audit = AuditLogRepository.instance;
  final TextEditingController _search = TextEditingController();
  String _filter = 'All';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _organizations.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _organizations.removeListener(_refresh);
    _search.dispose();
    super.dispose();
  }

  List<RegistryOrganization> get _filtered {
    final query = _search.text.trim().toLowerCase();
    final items = _organizations.organizations.where((org) {
      final assigned = org.adminEmail.trim().isNotEmpty;
      if (_filter == 'Assigned' && !assigned) return false;
      if (_filter == 'Unassigned' && assigned) return false;
      return '${org.name} ${org.id} ${org.category} ${org.adminEmail}'
          .toLowerCase()
          .contains(query);
    }).toList();
    items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return items;
  }

  BoxDecoration _surface() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(19),
    border: Border.all(color: _stroke),
  );

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _record(
    RegistryOrganization org,
    AuditActionType action,
    String description,
  ) {
    final user = Supabase.instance.client.auth.currentUser;
    // This is presentation-only actor information. Client-created audit
    // records are not independently authenticated or tamper-proof.
    _audit.record(
      actorName: user?.email ?? 'Operations Administrator (Demo)',
      actorRole: 'Operations Administrator',
      action: action,
      module: 'Admin Assignments',
      description: description,
      targetId: org.id,
    );
  }

  Future<void> _edit(RegistryOrganization org) async {
    if (_saving) return;
    final current = org.adminEmail.trim();
    final controller = TextEditingController(text: current);
    final key = GlobalKey<FormState>();
    final entered = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          current.isEmpty ? 'Assign representative' : 'Change representative',
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Form(
            key: key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  org.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  org.id,
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
                const SizedBox(height: 17),
                TextFormField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Organization representative email',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final email = (value ?? '').trim();
                    if (!RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch(email)) {
                      return 'Enter a valid email address.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'PROTOTYPE: Saving an email does not give this person '
                  'a real KAISA organization-admin role or database permissions.',
                  style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _forest),
            onPressed: () {
              if (key.currentState?.validate() ?? false) {
                Navigator.pop(ctx, controller.text.trim());
              }
            },
            child: const Text('Save assignment'),
          ),
        ],
      ),
    );
    // Wait for the modal route to finish unmounting the input field.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(
        const Duration(milliseconds: 350),
        controller.dispose,
      );
    });
    if (!mounted || entered == null) return;
    final value = entered.trim().toLowerCase();
    if (current.toLowerCase() == value) {
      _message('No changes to save.');
      return;
    }
    setState(() => _saving = true);
    try {
      _organizations.assignAdmin(org.id, value);
      _record(
        org,
        current.isEmpty ? AuditActionType.assign : AuditActionType.update,
        current.isEmpty
            ? 'Recorded a representative email for ${org.name} (prototype).'
            : 'Changed the representative email for ${org.name} (prototype).',
      );
      _message('Representative assignment saved in prototype.');
    } catch (_) {
      _message('Unable to save the assignment.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _remove(RegistryOrganization org) async {
    if (_saving || org.adminEmail.trim().isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove representative?'),
        content: Text(
          'Remove the representative email assigned to ${org.name}? '
          'This does not revoke any real Supabase permissions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _forest),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => _saving = true);
    try {
      _organizations.assignAdmin(org.id, '');
      _record(
        org,
        AuditActionType.remove,
        'Removed the representative assignment for ${org.name} (prototype).',
      );
      _message('Representative removed from prototype record.');
    } catch (_) {
      _message('Unable to remove the assignment.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _kpi(String title, int value, IconData icon) => Container(
    padding: const EdgeInsets.all(19),
    decoration: _surface(),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _mint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _forest),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  color: _forest,
                ),
              ),
              Text(title, style: const TextStyle(fontSize: 12, color: _muted)),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _summary() {
    final all = _organizations.organizations;
    final assigned = all.where((o) => o.adminEmail.trim().isNotEmpty).length;
    return LayoutBuilder(
      builder: (context, c) {
        final n = c.maxWidth >= 850
            ? 3
            : c.maxWidth >= 510
            ? 2
            : 1;
        const gap = 12.0;
        final width = (c.maxWidth - (n - 1) * gap) / n;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: width,
              child: _kpi(
                'Registered organizations',
                all.length,
                Icons.apartment_rounded,
              ),
            ),
            SizedBox(
              width: width,
              child: _kpi(
                'With representative',
                assigned,
                Icons.person_outline_rounded,
              ),
            ),
            SizedBox(
              width: width,
              child: _kpi(
                'Without representative',
                all.length - assigned,
                Icons.person_off_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _filters() => Container(
    padding: const EdgeInsets.all(17),
    decoration: _surface(),
    child: Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 290,
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search organization or representative',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
              ),
              isDense: true,
            ),
          ),
        ),
        SizedBox(
          width: 205,
          child: DropdownButtonFormField<String>(
            key: ValueKey(_filter),
            initialValue: _filter,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Representative',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'All', child: Text('All organizations')),
              DropdownMenuItem(value: 'Assigned', child: Text('Assigned')),
              DropdownMenuItem(value: 'Unassigned', child: Text('Unassigned')),
            ],
            onChanged: (value) => setState(() => _filter = value ?? 'All'),
          ),
        ),
        TextButton.icon(
          onPressed: () => setState(() {
            _filter = 'All';
            _search.clear();
          }),
          icon: const Icon(Icons.restart_alt),
          label: const Text('Clear filters'),
        ),
      ],
    ),
  );

  Widget _tile(RegistryOrganization org) {
    final assigned = org.adminEmail.trim().isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(19),
      decoration: _surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    org.name,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${org.id} · ${org.category}',
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: assigned ? _mint : const Color(0xFFFFF5DA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  assigned ? 'Representative assigned' : 'Needs representative',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: assigned ? _green : const Color(0xFF92660C),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 26, color: _stroke),
          const Text(
            'Organization representative email',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 6),
          SelectableText(
            assigned ? org.adminEmail : 'No representative recorded',
            style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: _forest),
                onPressed: _saving ? null : () => _edit(org),
                icon: Icon(
                  assigned
                      ? Icons.edit_outlined
                      : Icons.person_add_alt_1_rounded,
                  size: 18,
                ),
                label: Text(
                  assigned ? 'Change representative' : 'Assign representative',
                ),
              ),
              if (assigned)
                OutlinedButton.icon(
                  onPressed: _saving ? null : () => _remove(org),
                  icon: const Icon(Icons.person_remove_outlined, size: 18),
                  label: const Text('Remove'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: _paper,
    child: LayoutBuilder(
      builder: (context, viewport) {
        final compact = viewport.maxWidth < 650;
        final items = _filtered;
        return ListView(
          padding: EdgeInsets.fromLTRB(
            compact ? 15 : 26,
            24,
            compact ? 15 : 26,
            44,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1260),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(compact ? 22 : 30),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF0B3024),
                            Color(0xFF15543A),
                            Color(0xFF288258),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(23),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KAISA / LGU OPERATIONS / ASSIGNMENTS',
                            style: TextStyle(
                              color: _gold,
                              fontSize: 11,
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 11),
                          Text(
                            'Organization Representatives',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 29,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 7),
                          Text(
                            'Manage representative contacts for registered organizations.',
                            style: TextStyle(
                              color: Color(0xFFE2F0E6),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5DA),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Color(0xFF93650B)),
                          SizedBox(width: 11),
                          Expanded(
                            child: Text(
                              'DEMO MODE — Representative email assignments '
                              'are stored in the local organization repository. They do not '
                              'grant, revoke, or verify real organization permissions.',
                              style: TextStyle(
                                color: Color(0xFF775714),
                                fontSize: 12,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 19),
                    _summary(),
                    const SizedBox(height: 17),
                    _filters(),
                    const SizedBox(height: 14),
                    Text(
                      '${items.length} matching organizations',
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    if (items.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: _surface(),
                        child: const Center(
                          child: Text(
                            'No matching organizations.',
                            style: TextStyle(color: _muted),
                          ),
                        ),
                      )
                    else
                      for (final org in items) _tile(org),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
