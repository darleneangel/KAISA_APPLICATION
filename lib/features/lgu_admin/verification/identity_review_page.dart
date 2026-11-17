import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/repositories/verification_case_repository.dart';

const _forest = Color(0xFF00492C), _gold = Color(0xFFFBBA16);
const _ink = Color(0xFF173D2B), _muted = Color(0xFF687B70);
const _stroke = Color(0xFFE2EBE4), _mint = Color(0xFFEAF5EE);

/// Prototype review flow, not identity verification or Supabase tier elevation.
class IdentityReviewPage extends StatefulWidget {
  const IdentityReviewPage({super.key, required this.applicationId});
  final String applicationId;
  @override
  State<IdentityReviewPage> createState() => _IdentityReviewPageState();
}

class _IdentityReviewPageState extends State<IdentityReviewPage> {
  final _repo = VerificationCaseRepository.instance;
  final _reason = TextEditingController();
  final _checklist = <bool>[false, false, false];
  String _decision = 'Resubmission';
  bool _saving = false;
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _back() => context.go('/lgu-admin/verification/applications');
  Future<void> _submit() async {
    final app = _repo.find(widget.applicationId);
    if (app == null || !app.needsAction || app.archived || _saving) return;
    if (_decision == 'Approved' && _checklist.any((c) => !c)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Complete all review checklist items before demo approval.',
          ),
        ),
      );
      return;
    }
    if (_reason.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter at least 10 characters explaining your decision.',
          ),
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirm $_decision?'),
        content: const Text(
          'Prototype only: this records a local decision. No real resident is verified, no organization is accredited, and no notification is sent.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => _saving = true);
    final ok = _repo.recordDecision(
      widget.applicationId,
      _decision,
      _reason.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Decision was not saved. Check the application status.',
          ),
        ),
      );
      return;
    }
    // The repository notifies the queue. Once we navigate back, it rebuilds
    // from the updated shared in-memory status (no route arguments required).
    _back();
  }

  Widget _surface(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _stroke),
    ),
    child: child,
  );
  Widget _field(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) {
    final app = _repo.find(widget.applicationId);
    return ColoredBox(
      color: const Color(0xFFF6F8F5),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1050),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0D3325), _forest, Color(0xFF288259)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton.icon(
                          onPressed: _back,
                          icon: const Icon(Icons.arrow_back, color: _gold),
                          label: const Text(
                            'Back to applications',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 9),
                        const Text(
                          'Identity & Credential Review',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'KAISA · LGU Verification · Prototype',
                          style: TextStyle(color: _gold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _surface(
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFFA66B08)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Demo case only. Image comparison, actual identity-document inspection, and tier/accreditation changes are not connected.',
                            style: TextStyle(fontSize: 12, color: _muted),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (app == null)
                    _surface(
                      Column(
                        children: [
                          const Text(
                            'Application not found in the demo repository.',
                          ),
                          TextButton(
                            onPressed: _back,
                            child: const Text('Return to queue'),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    _surface(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app.name,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _field('Application ID', app.id),
                          _field('Request type', app.type),
                          _field('Purpose', app.purpose),
                          _field('Status', app.status),
                          _field('Submission platform', app.platform),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    _surface(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Evidence inspection (not connected)',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _ink,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 9),
                          const Text(
                            'Production implementation must provide permission-checked, expiring access to original evidence. This demo contains no ID image, selfie, or AI face-matching result.',
                            style: TextStyle(
                              color: _muted,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              for (final label in [
                                'ID evidence unavailable',
                                'Selfie evidence unavailable',
                              ])
                                Container(
                                  width: 230,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    color: _mint,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.lock_outline,
                                        color: _forest,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        label,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: _ink,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    if (app.needsAction && !app.archived)
                      _surface(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Manual review decision',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Only check items after authorized evidence inspection. Demo checkboxes do not verify documents.',
                              style: TextStyle(fontSize: 12, color: _muted),
                            ),
                            const SizedBox(height: 12),
                            for (var i = 0; i < _checklist.length; i++)
                              CheckboxListTile(
                                value: _checklist[i],
                                activeColor: _forest,
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  const [
                                    'Submitted material was reviewed',
                                    'Required fields are consistent',
                                    'Applicable verification policy was checked',
                                  ][i],
                                ),
                                onChanged: (v) =>
                                    setState(() => _checklist[i] = v ?? false),
                              ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<String>(
                              initialValue: _decision,
                              decoration: const InputDecoration(
                                labelText: 'Decision',
                                border: OutlineInputBorder(),
                              ),
                              items:
                                  const ['Approved', 'Rejected', 'Resubmission']
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (v) =>
                                  setState(() => _decision = v ?? _decision),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _reason,
                              maxLines: 3,
                              maxLength: 400,
                              decoration: const InputDecoration(
                                labelText:
                                    'Decision reason (min 10 characters)',
                                border: OutlineInputBorder(),
                                hintText:
                                    'Explain the basis of the decision; do not paste ID numbers.',
                              ),
                            ),
                            const SizedBox(height: 15),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _forest,
                                  ),
                                  onPressed: _saving ? null : _submit,
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: Text(
                                    _saving
                                        ? 'Saving'
                                        : 'Save decision & return to applications',
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed: _back,
                                  child: const Text('Cancel'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    else
                      _surface(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'This application is not open for review.',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 9),
                            const Text(
                              'Completed or archived applications cannot be re-decided from this prototype view.',
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: _back,
                              child: const Text('Return to queue'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
