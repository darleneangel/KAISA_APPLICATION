import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _forest = Color(0xFF00492C);
const _green = Color(0xFF287D55);
const _paper = Color(0xFFF6F8F5);
const _ink = Color(0xFF173D2B);
const _muted = Color(0xFF687B70);
const _gold = Color(0xFFFBBA16);
const _stroke = Color(0xFFE2EBE4);
const _mint = Color(0xFFEAF5EE);

/// Presentation-only preferences. Not an authorization or security-policy store.
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
  // Per-role session state, deliberately not persisted to Supabase.
  static final Map<String, Map<String, bool>> _sessionPreferences = {};
  late Map<String, bool> _values;

  @override
  void initState() {
    super.initState();
    _values = _sessionPreferences.putIfAbsent(
      widget.roleCode,
      () => {for (final option in widget.options) option.key: true},
    );
  }

  Future<void> _reset() async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore notification defaults?'),
        content: const Text(
          'This only resets local display preferences. It does not change '
          'Supabase accounts, roles, notification delivery, or security policies.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restore defaults'),
          ),
        ],
      ),
    );
    if (!mounted || answer != true) return;
    setState(() {
      _values = {for (final option in widget.options) option.key: true};
      _sessionPreferences[widget.roleCode] = _values;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Local preference defaults restored.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final currentRole = user?.appMetadata['kaisa_lgu_role']?.toString();
    final roleDetected =
        user?.appMetadata['is_super_admin'] == true &&
        currentRole == widget.roleCode;
    return LayoutBuilder(
      builder: (context, limits) {
        final compact = limits.maxWidth < 650;
        return ColoredBox(
          color: _paper,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 28,
              24,
              compact ? 16 : 28,
              48,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1260),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(compact),
                      const SizedBox(height: 22),
                      _section(
                        'Your ${widget.roleName} workspace',
                        'Signed-in account and role information',
                      ),
                      const SizedBox(height: 12),
                      _identity(user?.email, currentRole, roleDetected),
                      const SizedBox(height: 22),
                      _section(
                        'Notification preferences',
                        'Local prototype preferences for this application session',
                      ),
                      const SizedBox(height: 12),
                      _preferences(),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: _reset,
                          icon: const Icon(Icons.restart_alt_rounded),
                          label: const Text('Restore defaults'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _section(
                        'Responsibilities & safeguards',
                        'What this administrator is responsible for',
                      ),
                      const SizedBox(height: 12),
                      _responsibilities(),
                      const SizedBox(height: 20),
                      _security(),
                      const SizedBox(height: 18),
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: _muted,
                            size: 17,
                          ),
                          SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'PROTOTYPE: These preferences remain in memory and may '
                              'reset after a full restart. They do not send notifications '
                              'or modify Supabase Auth, RLS, AI thresholds or permissions. '
                              'Administrative access must be enforced by the backend.',
                              style: TextStyle(
                                fontSize: 11,
                                color: _muted,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _header(bool compact) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(compact ? 22 : 30),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        colors: [Color(0xFF0B3024), Color(0xFF15543A), Color(0xFF288258)],
      ),
    ),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 14,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'KAISA  /  LGU ${widget.roleName.toUpperCase()}  /  SETTINGS',
                style: const TextStyle(
                  color: _gold,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${widget.roleName} Settings',
                style: TextStyle(
                  fontSize: compact ? 27 : 34,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.subtitle,
                style: const TextStyle(
                  color: Color(0xFFE2F0E6),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield_outlined, color: _gold, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${widget.roleName.toUpperCase()} ADMIN',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _section(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: _ink,
        ),
      ),
      const SizedBox(height: 4),
      Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)),
    ],
  );

  Widget _identity(String? email, String? role, bool detected) => _card(
    Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 14,
      runSpacing: 12,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _icon(Icons.admin_panel_settings_outlined),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Signed-in administrator',
                    style: TextStyle(color: _ink, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email ?? 'No authenticated user',
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                  Text(
                    'KAISA role: ${role ?? 'Not available'}',
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: detected ? _mint : const Color(0xFFFFF3D8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            detected
                ? '${widget.roleName} role detected'
                : 'Role not confirmed',
            style: TextStyle(
              color: detected ? _forest : const Color(0xFF94670A),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _preferences() => _card(
    Column(
      children: [
        for (var i = 0; i < widget.options.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: _stroke),
          SwitchListTile.adaptive(
            contentPadding: const EdgeInsets.symmetric(vertical: 5),
            secondary: _icon(widget.options[i].icon),
            activeTrackColor: _green,
            activeThumbColor: Colors.white,
            title: Text(
              widget.options[i].title,
              style: const TextStyle(
                color: _ink,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              widget.options[i].description,
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
            value: _values[widget.options[i].key] ?? true,
            onChanged: (value) => setState(() {
              _values[widget.options[i].key] = value;
            }),
          ),
        ],
      ],
    ),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
  );

  Widget _responsibilities() => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 740 ? 2 : 1;
      final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final item in widget.responsibilities)
            SizedBox(
              width: width,
              child: _card(
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _icon(item.icon),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              color: _ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            item.description,
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 12,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(19),
              ),
            ),
        ],
      );
    },
  );

  Widget _security() => _card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.verified_user_outlined, color: _forest, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Security & access boundaries',
                style: TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < widget.safeguards.length; i++) ...[
          if (i > 0) const Divider(height: 22, color: _stroke),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: _green,
                size: 19,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.safeguards[i],
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );

  Widget _icon(IconData icon) => Container(
    width: 43,
    height: 43,
    decoration: BoxDecoration(
      color: _mint,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, color: _forest, size: 22),
  );

  Widget _card(Widget child, {EdgeInsets padding = const EdgeInsets.all(22)}) =>
      Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _stroke),
        ),
        child: child,
      );
}
