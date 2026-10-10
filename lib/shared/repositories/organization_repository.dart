import 'package:flutter/foundation.dart';

import '../models/organization_model.dart';
import '../models/audit_log_model.dart';
import 'audit_log_repository.dart';

class OrganizationRepository extends ChangeNotifier {
  OrganizationRepository._();

  static final OrganizationRepository instance = OrganizationRepository._();

  final List<RegistryOrganization> _organizations = [
    RegistryOrganization(
      id: 'ORG-001',
      name: 'Cavite City Youth Volunteers',
      category: 'Youth',
      description: 'Youth volunteer and community service activities.',
      email: 'youth@example.com',
      registryReference: 'LGU-001',
      adminEmail: 'representative@example.com',
    ),
    RegistryOrganization(
      id: 'ORG-002',
      name: 'Community Health Advocates',
      category: 'Health',
      description: 'Community health awareness and outreach.',
      email: 'health@example.com',
      registryReference: 'LGU-002',
    ),
    RegistryOrganization(
      id: 'ORG-003',
      name: 'Coastal Care Network',
      category: 'Environment',
      description: 'Coastal conservation and cleanup programs.',
      email: 'coastal@example.com',
      registryReference: 'LGU-003',
      status: 'Inactive',
    ),
  ];

  List<RegistryOrganization> get organizations =>
      List.unmodifiable(_organizations);

  int get totalOrganizations => _organizations.length;

  int get activeOrganizations =>
      _organizations.where((org) => org.status == 'Active').length;

  int get inactiveOrganizations =>
      _organizations.where((org) => org.status == 'Inactive').length;

  int get unassignedOrganizations =>
      _organizations.where((org) => org.adminEmail.isEmpty).length;

  String generateId() {
    final numbers = _organizations.map(
      (org) => int.tryParse(org.id.split('-').last) ?? 0,
    );

    final maxId = numbers.fold<int>(
      0,
      (max, value) => value > max ? value : max,
    );

    return 'ORG-${(maxId + 1).toString().padLeft(3, '0')}';
  }

  void _recordAudit({
  required AuditActionType action,
  required String module,
  required String description,
  required String organizationId,
}) {
  AuditLogRepository.instance.record(
    actorName: 'LGU Administrator (Demo)',
    actorRole: 'LGU Admin',
    action: action,
    module: module,
    description: description,
    targetId: organizationId,
  );
}

  void addOrganization(RegistryOrganization organization) {
  if (_organizations.any((org) => org.id == organization.id)) {
    throw StateError('Organization ID already exists.');
  }

  _organizations.add(organization);
  notifyListeners();

  _recordAudit(
    action: AuditActionType.create,
    module: 'Organization Registry',
    description: 'Registered organization: ${organization.name}.',
    organizationId: organization.id,
  );
}

  void updateOrganization(RegistryOrganization updated) {
  final index = _organizations.indexWhere(
    (org) => org.id == updated.id,
  );

  if (index == -1) {
    throw StateError('Organization not found.');
  }

  final previous = _organizations[index];

  _organizations[index] = updated;
  notifyListeners();

  _recordAudit(
    action: AuditActionType.update,
    module: 'Organization Registry',
    description: 'Updated organization: ${previous.name}.',
    organizationId: updated.id,
  );
}

  void assignAdmin(String organizationId, String email) {
  final index = _organizations.indexWhere(
    (org) => org.id == organizationId,
  );

  if (index == -1) {
    throw StateError('Organization not found.');
  }

  final organization = _organizations[index];
  final oldEmail = organization.adminEmail.trim();
  final newEmail = email.trim();

  if (oldEmail == newEmail) return;

  _organizations[index] = organization.copyWith(
    adminEmail: newEmail,
  );

  notifyListeners();

  final AuditActionType action;
  final String description;

  if (newEmail.isEmpty) {
    action = AuditActionType.remove;
    description =
        'Removed administrator $oldEmail from ${organization.name}.';
  } else if (oldEmail.isEmpty) {
    action = AuditActionType.assign;
    description =
        'Assigned administrator $newEmail to ${organization.name}.';
  } else {
    action = AuditActionType.update;
    description =
        'Changed administrator of ${organization.name} '
        'from $oldEmail to $newEmail.';
  }

  _recordAudit(
    action: action,
    module: 'Admin Assignments',
    description: description,
    organizationId: organizationId,
  );
}

  void setStatus(String organizationId, String status) {
  if (status != 'Active' && status != 'Inactive') {
    throw ArgumentError('Invalid organization status.');
  }

  final index = _organizations.indexWhere(
    (org) => org.id == organizationId,
  );

  if (index == -1) {
    throw StateError('Organization not found.');
  }

  final organization = _organizations[index];

  if (organization.status == status) return;

  _organizations[index] = organization.copyWith(
    status: status,
  );

  notifyListeners();

  _recordAudit(
    action: AuditActionType.statusChange,
    module: 'Organization Registry',
    description:
        'Changed ${organization.name} status '
        'from ${organization.status} to $status.',
    organizationId: organizationId,
  );
}
}
