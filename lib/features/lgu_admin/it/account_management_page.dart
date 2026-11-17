import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';

// KAISA IT Superadmin / Account Management
// DEMO ONLY: no Supabase reads, writes, or privileged Auth API calls.
// The real version must enforce permissions on a trusted server and log actions.

const _forest = Color(0xFF0C3828);
const _deep = Color(0xFF092A21);
const _green = Color(0xFF287D55);
const _mint = Color(0xFFE7F3EB);
const _paper = Color(0xFFF6F8F5);
const _ink = Color(0xFF17382B);
const _muted = Color(0xFF718278);
const _stroke = Color(0xFFE4EAE4);
const _yellow = Color(0xFFFFCF47);
const _orange = Color(0xFFAC6420);
const _red = Color(0xFFB84646);

class AccountManagementPage extends StatefulWidget {
  const AccountManagementPage({super.key});

  @override
  State<AccountManagementPage> createState() => _AccountManagementPageState();
}

class _AccountManagementPageState extends State<AccountManagementPage> {
  // Local, reset-on-restart demonstration records.
  late final List<_Account> _accounts = [
    _Account(
      'DEMO-001',
      'Demo Resident A',
      'resident.a@example.test',
      'Resident',
      'Tier 1',
      _AccountStatus.active,
      'Nov 11, 2026 · 09:15 AM',
    ),
    _Account(
      'DEMO-002',
      'Demo Organization Admin',
      'org.admin@example.test',
      'Organization Admin',
      'Tier 2',
      _AccountStatus.active,
      'Nov 12, 2026 · 10:40 AM',
    ),
    _Account(
      'DEMO-003',
      'Demo Resident B',
      'resident.b@example.test',
      'Resident',
      'Tier 2',
      _AccountStatus.suspended,
      'Nov 13, 2026 · 02:05 PM',
    ),
    _Account(
      'DEMO-004',
      'Demo Resident C',
      'resident.c@example.test',
      'Resident',
      'Tier 1',
      _AccountStatus.active,
      'Nov 14, 2026 · 11:30 AM',
    ),
    _Account(
      'DEMO-005',
      'Demo Organization Staff',
      'staff@example.test',
      'Organization Staff',
      'No resident tier',
      _AccountStatus.active,
      'Nov 14, 2026 · 03:25 PM',
    ),
    _Account(
      'DEMO-006',
      'Demo Resident D',
      'resident.d@example.test',
      'Resident',
      'Tier 2',
      _AccountStatus.archived,
      'Nov 15, 2026 · 08:50 AM',
    ),
  ];
  final List<_AuditEntry> _audit = [];
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _statusFilter = 'All statuses';
  String _roleFilter = 'All roles';
  bool _exporting = false;
  int _nextDemoNumber = 7;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_Account> get _visibleAccounts => _accounts.where((account) {
    final query = _query.trim().toLowerCase();
    final matchesQuery =
        query.isEmpty ||
        [
          account.name,
          account.id,
          account.email,
          account.role,
        ].any((text) => text.toLowerCase().contains(query));
    return matchesQuery &&
        (_statusFilter == 'All statuses' ||
            account.status.label == _statusFilter) &&
        (_roleFilter == 'All roles' || account.role == _roleFilter);
  }).toList();

  int _count(_AccountStatus status) =>
      _accounts.where((a) => a.status == status).length;

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // A spreadsheet-safe CSV cell. Avoid treating user-supplied names as formulas.
  String _csvCell(String value) {
    final guarded = RegExp(r'^\s*[=+\-@]').hasMatch(value) ? "'$value" : value;
    return '"${guarded.replaceAll('"', '""')}"';
  }

  Future<void> _exportCsv() async {
    if (_exporting) return;
    final records = _visibleAccounts;
    if (records.isEmpty) {
      _snack('There are no matching records to export.');
      return;
    }
    setState(() => _exporting = true);
    try {
      final lines = <String>[
        [
          'Account ID',
          'Name',
          'Email',
          'Role',
          'Tier',
          'Status',
          'Created at (demo)',
        ].map(_csvCell).join(','),
        for (final a in records)
          [
            a.id,
            a.name,
            a.email,
            a.role,
            a.tier,
            a.status.label,
            a.joined,
          ].map(_csvCell).join(','),
      ];
      final csv = '\uFEFF${lines.join('\r\n')}\r\n';
      final bytes = Uint8List.fromList(utf8.encode(csv));
      await FileSaver.instance.saveFile(
        name: 'KAISA_demo_accounts_${DateTime.now().millisecondsSinceEpoch}',
        bytes: bytes,
        fileExtension: 'csv',
        mimeType: MimeType.csv,
      );
      _snack('Demo CSV exported (${records.length} filtered accounts).');
    } catch (error) {
      _snack('Could not export the CSV: $error');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // DEMO ONLY: The form does not create a Supabase Auth user or send an invite.
  Future<void> _addAccount() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    String selectedRole = 'Resident';
    String selectedTier = 'Tier 1';
    String? validation;

    final result = await showDialog<_NewAccountDraft>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, updateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('Add demo account'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'IT Superadmin provisions accounts. This preview only '
                    'adds a local directory record and does not send an invitation.',
                    style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: nameController,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Display name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    maxLength: 254,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Account role',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        const [
                              'Resident',
                              'Organization Admin',
                              'Organization Staff',
                              'IT Superadmin',
                              'Verification Superadmin',
                              'Operations Superadmin',
                            ]
                            .map(
                              (role) => DropdownMenuItem(
                                value: role,
                                child: Text(
                                  role,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        updateDialog(() {
                          selectedRole = value;
                          validation = null;
                        });
                      }
                    },
                  ),
                  if (selectedRole == 'Resident') ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedTier,
                      decoration: const InputDecoration(
                        labelText: 'Demo resident tier',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Tier 1',
                          child: Text('Tier 1'),
                        ),
                        DropdownMenuItem(
                          value: 'Tier 2',
                          child: Text('Tier 2'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null)
                          updateDialog(() => selectedTier = value);
                      },
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Administrative roles do not receive a resident tier. '
                      'Real role assignments require trusted backend authorization.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                  if (validation != null) ...[
                    const SizedBox(height: 12),
                    Text(validation!, style: const TextStyle(color: _red)),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: _forest),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: const Text('Add demo account'),
              onPressed: () {
                final name = nameController.text.trim();
                final email = emailController.text.trim().toLowerCase();
                final validEmail = RegExp(
                  r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                ).hasMatch(email);
                if (name.isEmpty || !validEmail) {
                  updateDialog(
                    () => validation =
                        'Enter a display name and valid email address.',
                  );
                  return;
                }
                if (_accounts.any((a) => a.email.toLowerCase() == email)) {
                  updateDialog(
                    () => validation =
                        'This email already exists in the demo directory.',
                  );
                  return;
                }
                Navigator.pop(
                  dialogContext,
                  _NewAccountDraft(
                    name: name,
                    email: email,
                    role: selectedRole,
                    tier: selectedRole == 'Resident'
                        ? selectedTier
                        : 'No resident tier',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
    // Allow dialog exit animation to complete before disposing controllers.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    nameController.dispose();
    emailController.dispose();
    if (!mounted || result == null) return;

    final now = DateTime.now();
    final id = 'DEMO-${(_nextDemoNumber++).toString().padLeft(3, '0')}';
    setState(() {
      _accounts.insert(
        0,
        _Account(
          id,
          result.name,
          result.email,
          result.role,
          result.tier,
          _AccountStatus.active,
          _formatDateTime(now),
        ),
      );
      _audit.insert(
        0,
        _AuditEntry(
          result.name,
          id,
          'Created demo account · ${result.role}',
          'Local preview only — no Auth account or invitation created',
          now,
        ),
      );
      _query = '';
      _searchController.clear();
      _statusFilter = 'All statuses';
      _roleFilter = 'All roles';
    });
    _snack('Demo account created. No Supabase invitation was sent.');
  }

  String _formatDateTime(DateTime date) {
    final hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final month = const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ][date.month - 1];
    final minute = date.minute.toString().padLeft(2, '0');
    final meridiem = date.hour >= 12 ? 'PM' : 'AM';
    return '$month ${date.day}, ${date.year} · $hour12:$minute $meridiem';
  }

  // Proposed KAISA policy options for UI testing only.
  // Actual reasons, thresholds, and appeals require LGU approval.
  List<_PolicyOption> _policiesForAction(String action) => switch (action) {
    'Suspend' => const [
      _PolicyOption(
        'S01',
        'Substantiated misinformation violation',
        'Following documented review of reported misinformation.',
      ),
      _PolicyOption(
        'S02',
        'Substantiated hateful or harassing content',
        'Following documented review of harmful content reports.',
      ),
      _PolicyOption(
        'S03',
        'Confirmed spam or fraudulent activity',
        'After investigation of abusive or deceptive account behavior.',
      ),
      _PolicyOption(
        'S04',
        'Account security risk',
        'Potential compromise or suspicious access requiring investigation.',
      ),
      _PolicyOption(
        'S05',
        'Requested temporary suspension',
        'Account holder requested a temporary access restriction.',
      ),
    ],
    'Activate' => const [
      _PolicyOption(
        'A01',
        'Appeal reviewed and approved',
        'An authorized reviewer approved reinstatement.',
      ),
      _PolicyOption(
        'A02',
        'Security concern resolved',
        'Required recovery and identity checks are complete.',
      ),
      _PolicyOption(
        'A03',
        'Suspension period completed',
        'Authorized suspension period has ended.',
      ),
      _PolicyOption(
        'A04',
        'Account holder requested reactivation',
        'Request was verified and approved.',
      ),
      _PolicyOption(
        'A05',
        'Administrative error corrected',
        'Previous suspension was determined to be incorrect.',
      ),
    ],
    'Archive' => const [
      _PolicyOption(
        'R01',
        'User-requested account closure',
        'Verified user request; retention and deletion are separate decisions.',
      ),
      _PolicyOption(
        'R02',
        'Confirmed duplicate or superseded record',
        'Identity and ownership have been verified.',
      ),
      _PolicyOption(
        'R03',
        'Long-term inactivity review (50 years)',
        'Illustrative threshold only: review eligibility, not automatic deletion.',
      ),
      _PolicyOption(
        'R04',
        'Approved administrative deprovisioning',
        'Role or appointment has ended under an approved process.',
      ),
    ],
    _ => const [
      _PolicyOption(
        'T01',
        'Account holder requested restoration',
        'Verified request with the required administrative approval.',
      ),
      _PolicyOption(
        'T02',
        'Archive decision reversed after review',
        'An authorized reviewer approved restoration.',
      ),
      _PolicyOption(
        'T03',
        'Archived in error',
        'Documented correction of an incorrect archive action.',
      ),
    ],
  };

  Future<void> _confirmAction(
    _Account account,
    _AccountStatus next, {
    bool restoring = false,
  }) async {
    if (account.status == next) return;
    final oldStatus = account.status;
    final action = restoring
        ? 'Restore'
        : next == _AccountStatus.suspended
        ? 'Suspend'
        : next == _AccountStatus.archived
        ? 'Archive'
        : 'Activate';
    final policies = _policiesForAction(action);
    final noteController = TextEditingController();
    String? selectedCode;
    String? validation;
    String? reason;

    try {
      reason = await showDialog<String>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, updateDialog) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: Text('$action demo account?'),
            content: SizedBox(
              width: 470,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${account.name}  •  ${account.id}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _actionExplanation(next),
                      style: const TextStyle(color: _muted, height: 1.5),
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedCode,
                      decoration: InputDecoration(
                        labelText: 'Policy reason (required)',
                        errorText: validation,
                        border: const OutlineInputBorder(),
                      ),
                      hint: const Text('Choose a policy reason'),
                      items: [
                        for (final policy in policies)
                          DropdownMenuItem<String>(
                            value: policy.code,
                            child: Text(
                              '${policy.code} · ${policy.label}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) => updateDialog(() {
                        selectedCode = value;
                        validation = null;
                      }),
                    ),
                    if (selectedCode != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _mint,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          policies
                              .firstWhere((p) => p.code == selectedCode)
                              .description,
                          style: const TextStyle(color: _forest, fontSize: 12),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      maxLength: 300,
                      decoration: const InputDecoration(
                        labelText: 'Reference / case notes (optional)',
                        hintText: 'Case or request reference, if applicable',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const Text(
                      'PROPOSED POLICIES • DEMO ONLY. No real account '
                      'is changed. Reports must be reviewed before sanctions; '
                      'archiving is not permanent deletion.',
                      style: TextStyle(color: _orange, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _forest),
                onPressed: () {
                  if (selectedCode == null) {
                    updateDialog(
                      () => validation = 'Select a policy before continuing.',
                    );
                    return;
                  }
                  final policy = policies.firstWhere(
                    (item) => item.code == selectedCode,
                  );
                  final note = noteController.text.trim();
                  Navigator.pop(
                    dialogContext,
                    '${policy.code} · ${policy.label}'
                    '${note.isEmpty ? '' : ' — $note'}',
                  );
                },
                child: Text('Confirm $action'),
              ),
            ],
          ),
        ),
      );
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      noteController.dispose();
    }

    if (!mounted || reason == null) return;
    setState(() {
      account.status = next;
      _audit.insert(
        0,
        _AuditEntry(
          account.name,
          account.id,
          '${oldStatus.label} → ${next.label}',
          reason!,
          DateTime.now(),
        ),
      );
    });
    _snack('${account.name}: status changed to ${next.label} (demo only).');
  }

  String _actionExplanation(_AccountStatus next) => switch (next) {
    _AccountStatus.suspended =>
      'Suspension would block account access in a real deployment. '
          'This preview only changes the local status.',
    _AccountStatus.archived =>
      'Archiving retains a record for historical review; it is not '
          'permanent deletion. This preview only changes local status.',
    _AccountStatus.active =>
      'Activation would restore the account to active use in a real '
          'deployment. This preview only changes local status.',
  };

  void _openDetails(_Account account) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Account profile'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: _mint,
                  child: Text(
                    _initials(account.name),
                    style: const TextStyle(
                      color: _forest,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _detail('Name', account.name),
                _detail('Demo ID', account.id),
                _detail('Email', account.email),
                _detail('Role', account.role),
                _detail('Resident tier', account.tier),
                _detail('Status', account.status.label),
                _detail('Created at (demo)', account.joined),
                const SizedBox(height: 12),
                const Text(
                  'This is a fictional account. Sensitive identity documents, '
                  'credentials, and authentication sessions are not loaded.',
                  style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(color: _muted)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );

  static String _initials(String name) {
    final words = name.split(' ').where((word) => word.isNotEmpty).toList();
    if (words.isEmpty) return 'KA';
    return words.take(2).map((word) => word[0]).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleAccounts;
    return ColoredBox(
      color: _paper,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 700;
          return ListView(
            padding: EdgeInsets.fromLTRB(
              narrow ? 16 : 28,
              24,
              narrow ? 16 : 28,
              42,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1320),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _heading(narrow),
                      const SizedBox(height: 22),
                      _notice(),
                      const SizedBox(height: 23),
                      _summaryGrid(),
                      const SizedBox(height: 15),
                      _statusDistribution(),
                      const SizedBox(height: 25),
                      _directory(visible, narrow),
                      const SizedBox(height: 20),
                      _activityLog(),
                      const SizedBox(height: 16),
                      const Text(
                        'IT Superadmin prototype • Local changes reset when '
                        'this screen is recreated. No real accounts are accessed.',
                        style: TextStyle(color: _muted, fontSize: 11),
                      ),
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

  Widget _heading(bool narrow) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'KAISA  /  LGU ADMINISTRATION  /  IT',
        style: TextStyle(
          color: _green,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
      const SizedBox(height: 9),
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Account Management',
                style: TextStyle(
                  color: _ink,
                  fontSize: narrow ? 26 : 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Manage account lifecycle and review access decisions.',
                style: TextStyle(color: _muted, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 20),
      Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_deep, _forest, Color(0xFF1A664B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            const Positioned(
              right: -35,
              top: -70,
              child: _DecorativeRing(size: 230),
            ),
            Padding(
              padding: EdgeInsets.all(narrow ? 20 : 27),
              child: Wrap(
                spacing: 18,
                runSpacing: 14,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: narrow ? 260 : 500,
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'IDENTITY & ACCESS CONTROL',
                          style: TextStyle(
                            color: _yellow,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.8,
                          ),
                        ),
                        SizedBox(height: 11),
                        Text(
                          'Every account. One clear overview.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            height: 1.17,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Review statuses, investigate account details and '
                          'document lifecycle changes from a single workspace.',
                          style: TextStyle(
                            color: Color(0xFFCEE5D9),
                            fontSize: 12,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _addAccount,
                    style: FilledButton.styleFrom(
                      backgroundColor: _yellow,
                      foregroundColor: _deep,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 17,
                      ),
                    ),
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('Add account'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _exporting ? null : _exportCsv,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0x77FFFFFF)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 17,
                      ),
                    ),
                    icon: const Icon(Icons.file_download_outlined),
                    label: Text(_exporting ? 'Exporting...' : 'Export CSV'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _notice() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF6DC),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFF4E7C1)),
    ),
    child: const Row(
      children: [
        Icon(Icons.info_outline_rounded, color: _orange),
        SizedBox(width: 11),
        Expanded(
          child: Text(
            'DEVELOPMENT PREVIEW — Fictional accounts only. '
            'Add, Suspend, Activate, Archive, Restore, and CSV export '
            'do not access or modify Supabase.',
            style: TextStyle(
              color: Color(0xFF78591F),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _summaryGrid() => LayoutBuilder(
    builder: (context, constraints) {
      final cols = constraints.maxWidth >= 970
          ? 4
          : constraints.maxWidth >= 530
          ? 2
          : 1;
      const gap = 13.0;
      final width = (constraints.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          _metric(
            'Total accounts',
            '${_accounts.length}',
            Icons.people_alt_outlined,
            width,
            _forest,
          ),
          _metric(
            'Active',
            '${_count(_AccountStatus.active)}',
            Icons.check_circle_outline,
            width,
            _green,
          ),
          _metric(
            'Suspended',
            '${_count(_AccountStatus.suspended)}',
            Icons.pause_circle_outline_rounded,
            width,
            _orange,
          ),
          _metric(
            'Archived',
            '${_count(_AccountStatus.archived)}',
            Icons.inventory_2_outlined,
            width,
            _red,
          ),
        ],
      );
    },
  );

  Widget _metric(
    String title,
    String value,
    IconData icon,
    double width,
    Color color,
  ) => Container(
    width: width,
    padding: const EdgeInsets.all(19),
    decoration: _surface(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 23),
            ),
            const Spacer(),
            const Icon(Icons.more_horiz, color: Color(0xFFB1BDB4)),
          ],
        ),
        const SizedBox(height: 19),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: const TextStyle(
            color: _muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  Widget _statusDistribution() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
    decoration: _surface(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.donut_small_rounded, color: _green, size: 20),
            SizedBox(width: 9),
            Text(
              'Account status distribution',
              style: TextStyle(
                color: _ink,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 13,
            child: Row(
              children: [
                if (_count(_AccountStatus.active) > 0)
                  Expanded(
                    flex: _count(_AccountStatus.active),
                    child: const ColoredBox(color: _green),
                  ),
                if (_count(_AccountStatus.suspended) > 0)
                  Expanded(
                    flex: _count(_AccountStatus.suspended),
                    child: const ColoredBox(color: _yellow),
                  ),
                if (_count(_AccountStatus.archived) > 0)
                  Expanded(
                    flex: _count(_AccountStatus.archived),
                    child: const ColoredBox(color: _red),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _legend('Active', _green),
            _legend('Suspended', _yellow),
            _legend('Archived', _red),
          ],
        ),
      ],
    ),
  );

  Widget _legend(String title, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 6),
      Text(title, style: const TextStyle(color: _muted, fontSize: 11)),
    ],
  );

  Widget _directory(List<_Account> visible, bool narrow) => Container(
    padding: EdgeInsets.all(narrow ? 14 : 22),
    decoration: _surface(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account directory',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Search, review and manage fictional identities',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: _mint,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '${visible.length} results',
                style: const TextStyle(
                  color: _green,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 19),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: narrow ? 280 : 330,
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: _input(
                  'Search name, email, ID or role',
                  icon: Icons.search_rounded,
                ),
              ),
            ),
            SizedBox(
              width: 195,
              child: DropdownButtonFormField<String>(
                key: ValueKey(_statusFilter),
                initialValue: _statusFilter,
                isExpanded: true,
                decoration: _input('Status', icon: Icons.tune_rounded),
                items: const ['All statuses', 'Active', 'Suspended', 'Archived']
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _statusFilter = value);
                },
              ),
            ),
            SizedBox(
              width: 195,
              child: DropdownButtonFormField<String>(
                key: ValueKey(_roleFilter),
                initialValue: _roleFilter,
                isExpanded: true,
                decoration: _input('Account role', icon: Icons.badge_outlined),
                items:
                    const [
                          'All roles',
                          'Resident',
                          'Organization Admin',
                          'Organization Staff',
                          'IT Superadmin',
                          'Verification Superadmin',
                          'Operations Superadmin',
                        ]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _roleFilter = value);
                },
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _query = '';
                  _statusFilter = 'All statuses';
                  _roleFilter = 'All roles';
                });
              },
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Reset filters'),
            ),
          ],
        ),
        const SizedBox(height: 17),
        Row(
          children: [
            Expanded(
              child: Text(
                'Showing ${visible.length} of '
                '${_accounts.length} demo accounts',
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ),
            TextButton.icon(
              onPressed: _exporting ? null : _exportCsv,
              icon: const Icon(Icons.download_rounded, size: 17),
              label: const Text('Export filtered CSV'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (visible.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 38),
            child: Center(
              child: Text(
                'No accounts match those filters.',
                style: TextStyle(color: _muted),
              ),
            ),
          )
        else if (narrow)
          Column(
            children: [
              for (final account in visible) ...[
                _mobileAccount(account),
                const SizedBox(height: 10),
              ],
            ],
          )
        else
          LayoutBuilder(
            builder: (context, bounds) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: bounds.maxWidth),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(_paper),
                  columnSpacing: 26,
                  horizontalMargin: 20,
                  dataRowMinHeight: 65,
                  dataRowMaxHeight: 74,
                  columns: const [
                    DataColumn(
                      label: Padding(
                        padding: EdgeInsets.only(left: 51),
                        child: Text('ACCOUNT'),
                      ),
                    ),
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('ROLE / TIER')),
                    DataColumn(label: Text('STATUS')),
                    DataColumn(label: Text('CREATED AT')),
                    DataColumn(label: Text('ACTIONS')),
                  ],
                  rows: [
                    for (final account in visible)
                      DataRow(
                        cells: [
                          DataCell(_accountIdentity(account)),
                          DataCell(Text(account.id)),
                          DataCell(
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  account.role,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: _ink,
                                  ),
                                ),
                                Text(
                                  account.tier,
                                  style: const TextStyle(
                                    color: _muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(_statusChip(account.status)),
                          DataCell(Text(account.joined)),
                          DataCell(_actions(account)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _mobileAccount(_Account account) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _paper,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: _stroke),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _accountIdentity(account),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _statusChip(account.status),
            Text(account.role, style: const TextStyle(color: _muted)),
            Text(account.tier, style: const TextStyle(color: _muted)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                '${account.id} • ${account.joined}',
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ),
            _actions(account),
          ],
        ),
      ],
    ),
  );

  Widget _accountIdentity(_Account account) => Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      CircleAvatar(
        radius: 20,
        backgroundColor: _mint,
        child: Text(
          _initials(account.name),
          style: const TextStyle(
            color: _forest,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ),
      const SizedBox(width: 11),
      Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            account.name,
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            account.email,
            style: const TextStyle(color: _muted, fontSize: 10),
          ),
        ],
      ),
    ],
  );
  Widget _actions(_Account account) => PopupMenuButton<String>(
    tooltip: 'Actions for ${account.name}',
    icon: const Icon(Icons.more_horiz_rounded, color: _forest),
    onSelected: (action) {
      switch (action) {
        case 'view':
          _openDetails(account);
        case 'suspend':
          _confirmAction(account, _AccountStatus.suspended);
        case 'activate':
          _confirmAction(account, _AccountStatus.active);
        case 'archive':
          _confirmAction(account, _AccountStatus.archived);
        case 'restore':
          // Restored archived accounts stay suspended until activated.
          _confirmAction(account, _AccountStatus.suspended, restoring: true);
      }
    },
    itemBuilder: (context) => [
      const PopupMenuItem(
        value: 'view',
        child: _ActionItem(Icons.person_outline_rounded, 'View account', _ink),
      ),
      if (account.status == _AccountStatus.active)
        const PopupMenuItem(
          value: 'suspend',
          child: _ActionItem(
            Icons.pause_circle_outline,
            'Suspend account',
            _orange,
          ),
        ),
      if (account.status == _AccountStatus.suspended)
        const PopupMenuItem(
          value: 'activate',
          child: _ActionItem(
            Icons.check_circle_outline,
            'Activate account',
            _green,
          ),
        ),
      if (account.status != _AccountStatus.archived)
        const PopupMenuItem(
          value: 'archive',
          child: _ActionItem(
            Icons.inventory_2_outlined,
            'Archive account',
            _red,
          ),
        ),
      if (account.status == _AccountStatus.archived)
        const PopupMenuItem(
          value: 'restore',
          child: _ActionItem(
            Icons.unarchive_outlined,
            'Restore as suspended',
            _green,
          ),
        ),
    ],
  );

  Widget _statusChip(_AccountStatus status) {
    final (bg, fg, icon) = switch (status) {
      _AccountStatus.active => (_mint, _green, Icons.check_circle_rounded),
      _AccountStatus.suspended => (
        const Color(0xFFFFF2DE),
        _orange,
        Icons.pause_circle_rounded,
      ),
      _AccountStatus.archived => (
        const Color(0xFFF0EDEE),
        _red,
        Icons.inventory_2_outlined,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityLog() => Container(
    padding: const EdgeInsets.all(21),
    decoration: _surface(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.history_rounded, color: _green),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Recent account actions',
                style: TextStyle(
                  color: _ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Local session log of account creation and status changes.',
          style: TextStyle(color: _muted, fontSize: 12),
        ),
        const SizedBox(height: 16),
        if (_audit.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: _paper,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              children: [
                Icon(Icons.fact_check_outlined, color: _green, size: 30),
                SizedBox(height: 10),
                Text(
                  'No demo changes recorded yet',
                  style: TextStyle(color: _ink, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 4),
                Text(
                  'Account status changes will appear here.',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          )
        else
          for (final entry in _audit.take(8))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: _mint,
                    child: Icon(
                      Icons.history_rounded,
                      color: _forest,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.accountName} • ${entry.change}',
                          style: const TextStyle(
                            color: _ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${entry.accountId} · ${entry.reason}',
                          style: const TextStyle(color: _muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatDateTime(entry.when),
                    style: const TextStyle(color: _muted, fontSize: 10),
                  ),
                ],
              ),
            ),
      ],
    ),
  );

  InputDecoration _input(String hint, {required IconData icon}) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: _green),
        filled: true,
        fillColor: _paper,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 17,
          horizontal: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _stroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _stroke),
        ),
      );

  BoxDecoration _surface() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: _stroke),
    boxShadow: const [
      BoxShadow(color: Color(0x07092A21), blurRadius: 22, offset: Offset(0, 8)),
    ],
  );
}

class _DecorativeRing extends StatelessWidget {
  final double size;
  const _DecorativeRing({required this.size});
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: .07),
          width: 35,
        ),
      ),
    ),
  );
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _ActionItem(this.icon, this.label, this.color);
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 11),
      Text(label, style: TextStyle(color: color)),
    ],
  );
}

enum _AccountStatus {
  active('Active'),
  suspended('Suspended'),
  archived('Archived');

  const _AccountStatus(this.label);
  final String label;
}

class _Account {
  final String id;
  final String name;
  final String email;
  final String role;
  final String tier;
  _AccountStatus status;
  final String joined;

  _Account(
    this.id,
    this.name,
    this.email,
    this.role,
    this.tier,
    this.status,
    this.joined,
  );
}

class _AuditEntry {
  final String accountName;
  final String accountId;
  final String change;
  final String reason;
  final DateTime when;

  _AuditEntry(
    this.accountName,
    this.accountId,
    this.change,
    this.reason,
    this.when,
  );
}

class _NewAccountDraft {
  final String name;
  final String email;
  final String role;
  final String tier;

  const _NewAccountDraft({
    required this.name,
    required this.email,
    required this.role,
    required this.tier,
  });
}

class _PolicyOption {
  final String code;
  final String label;
  final String description;

  const _PolicyOption(this.code, this.label, this.description);
}
