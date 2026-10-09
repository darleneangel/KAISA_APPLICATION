import 'package:flutter/foundation.dart';

import '../models/organization_model.dart';

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

  void addOrganization(RegistryOrganization organization) {
    if (_organizations.any((org) => org.id == organization.id)) {
      throw StateError('Organization ID already exists.');
    }

    _organizations.add(organization);
    notifyListeners();
  }

  void updateOrganization(RegistryOrganization updated) {
    final index = _organizations.indexWhere((org) => org.id == updated.id);

    if (index == -1) {
      throw StateError('Organization not found.');
    }

    _organizations[index] = updated;
    notifyListeners();
  }

  void assignAdmin(String organizationId, String email) {
    final index = _organizations.indexWhere((org) => org.id == organizationId);

    if (index == -1) {
      throw StateError('Organization not found.');
    }

    _organizations[index] = _organizations[index].copyWith(
      adminEmail: email.trim(),
    );

    notifyListeners();
  }

  void setStatus(String organizationId, String status) {
    if (status != 'Active' && status != 'Inactive') {
      throw ArgumentError('Invalid organization status.');
    }

    final index = _organizations.indexWhere((org) => org.id == organizationId);

    if (index == -1) {
      throw StateError('Organization not found.');
    }

    _organizations[index] = _organizations[index].copyWith(status: status);

    notifyListeners();
  }
}
