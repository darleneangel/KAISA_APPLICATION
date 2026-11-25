import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _forest = Color(0xFF00492C);
const _green = Color(0xFF287D55);
const _ink = Color(0xFF173D2B);
const _muted = Color(0xFF687B70);
const _gold = Color(0xFFFBBA16);
const _paper = Color(0xFFF6F8F5);
const _stroke = Color(0xFFE2EBE4);
const _mint = Color(0xFFEAF5EE);

class LguSettingOption {
  const LguSettingOption(this.key, this.title, this.description, this.icon);
  final String key;
  final String title;
  final String description;
  final IconData icon;
}

class LguResponsibility {
  const LguResponsibility(this.title, this.description, this.icon);
  final String title;
  final String description;
  final IconData icon;
}

/// Consistent Settings UI for Operations, IT, and Verification.
/// Identity is read from the authenticated Supabase user; settings are local.
/// This widget does NOT grant roles or change protected authorization data.
class LguRoleSettingsView extends StatefulWidget {
  const LguRoleSettingsView({
    super.key,
    required this.roleName,
    required this.roleCode,
    required this.subtitle,
    required this.options,
    required this.responsibilities,
    required this.safeguards,
  });
  final String roleName;
  final String roleCode;
  final String subtitle;
  final List<LguSettingOption> options;
  final List<LguResponsibility> responsibilities;
  final List<String> safeguards;

  @override
  State<LguRoleSettingsView> createState() => _LguRoleSettingsViewState();
}

class _LguRoleSettingsViewState extends State<LguRoleSettingsView> {
  static final Map<String, Map<String, bool>> _localSettings = {};
  late Map<String, bool> _preferences;
  final TextEditingController _nameController = TextEditingController();
  StreamSubscription<AuthState>? _authSubscription;
  bool _saving = false;
  bool _sendingReset = false;

  SupabaseClient get _client => Supabase.instance.client;
  User? get _user => _client.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _preferences = _localSettings.putIfAbsent(
      widget.roleCode,
      () => {for (final option in widget.options) option.key: true},
    );
    _authSubscription = _client.auth.onAuthStateChange.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  String _displayName(User? user) {
    final metadata = user?.userMetadata;
    for (final key in ['full_name', 'display_name', 'name']) {
      final value = metadata?[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return 'Not provided';
  }

  String _date(String? raw) {
    if (raw == null || raw.isEmpty) return 'Not available';
    final d = DateTime.tryParse(raw)?.toLocal();
    if (d == null) return 'Not available';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        backgroundColor: error ? const Color(0xFF9B342A) : _forest,
        content: Text(message),
      ));
  }

  Future<void> _editDisplayName() async {
    final user = _user;
    if (user == null || _saving) return;
    _nameController.text = _displayName(user) == 'Not provided'
        ? ''
        : _displayName(user);
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit display name'),
        content: SizedBox(
          width: 430,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              maxLength: 80,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Display name',
                helperText: 'For display only; not verified legal identity.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Administrator role and official identity cannot be changed here.',
              style: TextStyle(color: _muted, fontSize: 12),
            ),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save name'),
          ),
        ],
      ),
    );
    if (!mounted || shouldSave != true) return;
    final name = _nameController.text.trim();
    if (name.length < 2 || name.length > 80) {
      _snack('Enter a display name between 2 and 80 characters.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final result = await _client.auth.updateUser(
        UserAttributes(data: {'full_name': name}),
      );
      if (result.user == null) throw StateError('Profile update was not confirmed.');
      if (mounted) setState(() {});
      _snack('Display name updated in your Supabase account.');
    } on AuthException catch (e) {
      _snack(e.message, error: true);
    } catch (_) {
      _snack('Could not save the display name. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _requestPasswordReset() async {
    final email = _user?.email;
    if (email == null || email.isEmpty || _sendingReset) {
      _snack('No email address is available for this account.', error: true);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Send password reset email?'),
        content: Text('Request a Supabase password recovery email for $email? '
            'Your project must have a configured recovery URL and email delivery.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Send email')),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => _sendingReset = true);
    try {
      await _client.auth.resetPasswordForEmail(email);
      _snack('Password recovery requested. Check your email if delivery is configured.');
    } on AuthException catch (e) {
      _snack(e.message, error: true);
    } catch (_) {
      _snack('Could not request password recovery.', error: true);
    } finally {
      if (mounted) setState(() => _sendingReset = false);
    }
  }

  Future<void> _restoreDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore preference defaults?'),
        content: const Text(
          'This only resets the local preview switches. It does not '
          'update security controls or server notification delivery.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Restore')),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() {
      _preferences = {for (final option in widget.options) option.key: true};
      _localSettings[widget.roleCode] = _preferences;
    });
    _snack('Local preference defaults restored.');
  }

  Widget _surface(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _stroke),
    ),
    child: child,
  );

  Widget _section(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.w800, color: _ink)),
      const SizedBox(height: 5),
      Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)),
    ],
  );

  Widget _field(String label, String value, {bool copied = false}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: _muted, fontSize: 11)),
        const SizedBox(height: 5),
        Row(children: [
          Expanded(child: SelectableText(value,
              style: const TextStyle(color: _ink, fontSize: 13,
                  fontWeight: FontWeight.w700))),
          if (copied) IconButton(
            icon: const Icon(Icons.copy_outlined, size: 18),
            tooltip: 'Copy administrator ID',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: value));
              _snack('Administrator ID copied.');
            },
          ),
        ]),
      ]);

  Widget _profile(User? user) {
    if (user == null) {
      return _surface(const Row(children: [
        Icon(Icons.lock_outline, color: _forest),
        SizedBox(width: 12),
        Expanded(child: Text('No authenticated administrator account.')),
      ]));
    }
    final roleCode = user.appMetadata['kaisa_lgu_role']?.toString() ?? '';
    final assigned = user.appMetadata['is_super_admin'] == true &&
        roleCode == widget.roleCode;
    return _surface(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12, runSpacing: 10, children: [
        SizedBox(width: 295, child: Row(children: [
          const CircleAvatar(radius: 27, backgroundColor: _mint,
              child: Icon(Icons.person_outline_rounded, color: _forest, size: 28)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_displayName(user), maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                color: _ink, fontWeight: FontWeight.w800, fontSize: 17)),
            const SizedBox(height: 4),
            Text(user.email ?? 'Email unavailable', maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _muted, fontSize: 12)),
          ])),
        ])),
        OutlinedButton.icon(
          onPressed: _saving ? null : _editDisplayName,
          icon: const Icon(Icons.edit_outlined, size: 17),
          label: Text(_saving ? 'Saving...' : 'Edit display name'),
        ),
      ]),
      const Divider(height: 28, color: _stroke),
      LayoutBuilder(builder: (context, constraints) {
        final cols = constraints.maxWidth >= 610 ? 2 : 1;
        const gap = 20.0;
        final width = (constraints.maxWidth - gap * (cols - 1)) / cols;
        final fields = [
          _field('Administrator ID (Supabase Auth UID)', user.id, copied: true),
          _field('Assigned role (read-only)', assigned
              ? '${widget.roleName} Administrator'
              : 'Role not confirmed for this workspace'),
          _field('Email (read-only)', user.email ?? 'Not available'),
          _field('Account created', _date(user.createdAt)),
          _field('Last successful sign-in', _date(user.lastSignInAt)),
          _field('Account status', 'Not available from client session'),
        ];
        return Wrap(spacing: gap, runSpacing: 16, children: [
          for (final field in fields) SizedBox(width: width, child: field),
        ]);
      }),
      if (!assigned) ...[
        const SizedBox(height: 12),
        const Text('Account role could not be verified for this page. '
            'Your router and backend must enforce actual authorization.',
            style: TextStyle(color: Color(0xFFAB6815), fontSize: 12)),
      ],
      const SizedBox(height: 13),
      const Text('Display names are self-entered and are not proof of legal identity. '
          'Official staff identity and account status require a trusted admin directory.',
          style: TextStyle(color: _muted, fontSize: 11)),
    ]));
  }

  Widget _preferencesPanel() => _surface(Column(children: [
    for (var i = 0; i < widget.options.length; i++) ...[
      if (i != 0) const Divider(height: 1, color: _stroke),
      SwitchListTile.adaptive(
        contentPadding: const EdgeInsets.symmetric(vertical: 5),
        secondary: Icon(widget.options[i].icon, color: _forest),
        title: Text(widget.options[i].title,
            style: const TextStyle(color: _ink,
                fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text(widget.options[i].description,
            style: const TextStyle(color: _muted, fontSize: 12)),
        value: _preferences[widget.options[i].key] ?? true,
        activeTrackColor: _green,
        onChanged: (v) => setState(() {
          _preferences[widget.options[i].key] = v;
        }),
      ),
    ],
  ]));

  Widget _responsibilityPanel() => LayoutBuilder(builder: (context, c) {
    final cols = c.maxWidth >= 760 ? 2 : 1;
    const gap = 12.0;
    final width = (c.maxWidth - (cols - 1) * gap) / cols;
    return Wrap(spacing: gap, runSpacing: gap, children: [
      for (final item in widget.responsibilities)
        SizedBox(width: width, child: _surface(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(item.icon, color: _forest, size: 23),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(
                    color: _ink, fontWeight: FontWeight.w800, fontSize: 13)),
                const SizedBox(height: 5),
                Text(item.description, style: const TextStyle(
                    color: _muted, height: 1.4, fontSize: 12)),
              ],
            )),
          ],
        ))),
    ]);
  });

  Widget _safeguardsPanel() => _surface(Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Security & access boundaries', style: TextStyle(
        color: _ink, fontWeight: FontWeight.w800, fontSize: 16,
      )),
      const SizedBox(height: 12),
      for (final item in widget.safeguards) ...[
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.shield_outlined, color: _green, size: 18),
          const SizedBox(width: 9),
          Expanded(child: Text(item, style: const TextStyle(
            color: _muted, fontSize: 12, height: 1.5,
          ))),
        ]),
        const SizedBox(height: 10),
      ],
    ],
  ));

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: _paper,
    child: LayoutBuilder(builder: (context, bounds) {
      final compact = bounds.maxWidth < 650;
      return ListView(
        padding: EdgeInsets.fromLTRB(compact ? 14 : 26, 24,
            compact ? 14 : 26, 44),
        children: [Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1260),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(compact ? 22 : 30),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(colors: [
                    Color(0xFF0A3325), _forest, Color(0xFF287D55),
                  ]),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('KAISA / LGU ADMINISTRATION / SETTINGS',
                        style: TextStyle(color: _gold, fontSize: 11,
                            fontWeight: FontWeight.w800, letterSpacing: 1.1)),
                    const SizedBox(height: 12),
                    Text('${widget.roleName} Settings', style: TextStyle(
                        color: Colors.white, fontSize: compact ? 26 : 32,
                        fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text(widget.subtitle, style: const TextStyle(
                        color: Color(0xFFE4F2E9), height: 1.5, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _section('Administrator profile',
                  'Authenticated account details and read-only access information'),
              const SizedBox(height: 12),
              _profile(_user),
              const SizedBox(height: 24),
              _section('Account security', 'Request a password recovery email'),
              const SizedBox(height: 12),
              _surface(Wrap(spacing: 12, runSpacing: 9,
                crossAxisAlignment: WrapCrossAlignment.center, children: [
                  const Icon(Icons.lock_reset_outlined, color: _forest),
                  const Text('Password recovery', style: TextStyle(
                      fontWeight: FontWeight.w800, color: _ink)),
                  OutlinedButton.icon(
                    onPressed: _sendingReset || _user == null
                        ? null : _requestPasswordReset,
                    icon: const Icon(Icons.mail_outline, size: 18),
                    label: Text(_sendingReset ? 'Requesting...' : 'Send reset email'),
                  ),
                ],
              )),
              const SizedBox(height: 24),
              _section('Notification preferences',
                  'Local display preferences only; email/push delivery is not configured here'),
              const SizedBox(height: 12),
              _preferencesPanel(),
              const SizedBox(height: 9),
              Align(alignment: Alignment.centerRight,
                child: TextButton.icon(onPressed: _restoreDefaults,
                  icon: const Icon(Icons.restart_alt_outlined),
                  label: const Text('Restore defaults')),
              ),
              const SizedBox(height: 22),
              _section('Administrator responsibilities',
                  'What the ${widget.roleName} Administrator is assigned to oversee'),
              const SizedBox(height: 12),
              _responsibilityPanel(),
              const SizedBox(height: 18),
              _safeguardsPanel(),
              const SizedBox(height: 15),
              const Text('PROTOTYPE: Notification switches remain in local memory. '
                  'They do not modify Supabase role permissions or send alerts. '
                  'Never rely on this page for backend access enforcement.',
                  style: TextStyle(fontSize: 11, color: _muted, height: 1.5)),
            ],
          ),
        ))],
      );
    }),
  );
}
