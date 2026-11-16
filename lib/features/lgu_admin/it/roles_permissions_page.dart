
import 'package:flutter/material.dart';

const _forest = Color(0xFF14532D);
const _green = Color(0xFF237A50);
const _paper = Color(0xFFF8FAF8);
const _ink = Color(0xFF173D2B);
const _muted = Color(0xFF687B70);
const _stroke = Color(0xFFE2EBE4);
const _soft = Color(0xFFEAF5EE);

enum _AdminRole { it, verification, operations }

class RolesPermissionsPage extends StatefulWidget {
  const RolesPermissionsPage({super.key});

  @override
  State<RolesPermissionsPage> createState() =>
      _RolesPermissionsPageState();
}

class _RolesPermissionsPageState
    extends State<RolesPermissionsPage> {
  _AdminRole _selected = _AdminRole.it;

  static const _roleNames = {
    _AdminRole.it: 'IT Administrator',
    _AdminRole.verification: 'Verification Administrator',
    _AdminRole.operations: 'Operations Administrator',
  };

  static const _roleKeys = {
    _AdminRole.it: 'lgu_it_admin',
    _AdminRole.verification: 'lgu_verification_admin',
    _AdminRole.operations: 'lgu_operations_admin',
  };

  // Proposed permission matrix. Not connected to Supabase.
  static const _permissions = <(String, _AdminRole)>[
    ('Account recovery & suspension', _AdminRole.it),
    ('Role configuration', _AdminRole.it),
    ('Security monitoring', _AdminRole.it),
    ('System maintenance', _AdminRole.it),
    ('Identity verification reviews', _AdminRole.verification),
    ('Tier 2 approval decisions', _AdminRole.verification),
    ('Verification reports', _AdminRole.verification),
    ('Organization registry', _AdminRole.operations),
    ('Organization admin assignments', _AdminRole.operations),
    ('Event & attendance monitoring', _AdminRole.operations),
    ('Organization reports', _AdminRole.operations),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedPermissions = _permissions
        .where((permission) => permission.$2 == _selected)
        .toList();

    return ColoredBox(
      color: _paper,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1260),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'KAISA / LGU ADMINISTRATION / IT',
                    style: TextStyle(
                      color: _green,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 9),
                  const Text(
                    'Roles & Permissions',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 29,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Review proposed access boundaries for '
                    'KAISA LGU administrator roles.',
                    style: TextStyle(color: _muted, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  _banner(),
                  const SizedBox(height: 24),
                  _roleCards(),
                  const SizedBox(height: 25),
                  _roleDetails(selectedPermissions),
                  const SizedBox(height: 25),
                  _permissionMatrix(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _banner() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8DE),
          borderRadius: BorderRadius.circular(13),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF92650D)),
            SizedBox(width: 11),
            Expanded(
              child: Text(
                'Development preview. These permissions are '
                'proposed UI definitions, not live database '
                'permissions. Changes are disabled.',
                style: TextStyle(
                  color: Color(0xFF73550E),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _roleCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 850
            ? 3
            : constraints.maxWidth >= 500
                ? 2
                : 1;
        const gap = 12.0;
        final width =
            (constraints.maxWidth - gap * (columns - 1)) /
                columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final role in _AdminRole.values)
              SizedBox(
                width: width,
                child: _roleCard(role),
              ),
          ],
        );
      },
    );
  }

  Widget _roleCard(_AdminRole role) {
    final selected = role == _selected;

    final icon = switch (role) {
      _AdminRole.it => Icons.computer_rounded,
      _AdminRole.verification =>
        Icons.verified_user_outlined,
      _AdminRole.operations => Icons.apartment_rounded,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selected = role),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            color: selected ? _soft : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected ? _green : _stroke,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: _forest, size: 25),
                  const Spacer(),
                  if (selected)
                    const Icon(
                      Icons.check_circle,
                      color: _green,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                _roleNames[role]!,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _roleKeys[role]!,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleDetails(
      List<(String, _AdminRole)> permissions) {
    return Container(
      padding: const EdgeInsets.all(21),
      decoration: _surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _roleNames[_selected]!,
            style: const TextStyle(
              color: _ink,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Proposed responsibilities for this administrator.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          for (final permission in permissions) ...[
            Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: _green,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    permission.$1,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
          ],
        ],
      ),
    );
  }

  Widget _permissionMatrix() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Role Access Matrix',
            style: TextStyle(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Illustrative permissions for the three '
            'LGU administration roles.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 15),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor:
                  WidgetStateProperty.all(_soft),
              columns: const [
                DataColumn(label: Text('PERMISSION')),
                DataColumn(label: Text('IT')),
                DataColumn(label: Text('VERIFICATION')),
                DataColumn(label: Text('OPERATIONS')),
              ],
              rows: [
                for (final permission in _permissions)
                  DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 230,
                          child: Text(permission.$1),
                        ),
                      ),
                      _accessCell(
                        permission.$2 == _AdminRole.it,
                      ),
                      _accessCell(
                        permission.$2 == _AdminRole.verification,
                      ),
                      _accessCell(
                        permission.$2 == _AdminRole.operations,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataCell _accessCell(bool allowed) {
    return DataCell(
      Icon(
        allowed ? Icons.check_circle : Icons.remove_circle_outline,
        color: allowed ? _green : _muted,
        size: 19,
      ),
    );
  }

  BoxDecoration _surface() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _stroke),
      );
}
