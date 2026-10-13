
import 'package:flutter/foundation.dart';

import '../models/organization_membership_model.dart';

class OrganizationMembershipRepository extends ChangeNotifier {
  OrganizationMembershipRepository._();

  static final OrganizationMembershipRepository instance =
      OrganizationMembershipRepository._();

  final List<OrganizationMembership> _memberships = [
    OrganizationMembership(
      id: 'MEM-001',
      organizationId: 'ORG-001',
      residentId: 'RES-001',
      residentName: 'Maria Santos',
      residentEmail: 'maria@example.com',
      requestedAt: DateTime(2026, 10, 2),
      status: MembershipStatus.approved,
      reviewedAt: DateTime(2026, 10, 3),
    ),
    OrganizationMembership(
      id: 'MEM-002',
      organizationId: 'ORG-001',
      residentId: 'RES-002',
      residentName: 'Juan Dela Cruz',
      residentEmail: 'juan@example.com',
      requestedAt: DateTime(2026, 10, 5),
      status: MembershipStatus.approved,
      reviewedAt: DateTime(2026, 10, 6),
    ),
    OrganizationMembership(
      id: 'MEM-003',
      organizationId: 'ORG-001',
      residentId: 'RES-003',
      residentName: 'Ana Reyes',
      residentEmail: 'ana@example.com',
      requestedAt: DateTime(2026, 10, 9),
    ),
    OrganizationMembership(
      id: 'MEM-004',
      organizationId: 'ORG-001',
      residentId: 'RES-004',
      residentName: 'Paolo Garcia',
      residentEmail: 'paolo@example.com',
      requestedAt: DateTime(2026, 10, 10),
    ),
    OrganizationMembership(
      id: 'MEM-005',
      organizationId: 'ORG-001',
      residentId: 'RES-005',
      residentName: 'Sofia Mendoza',
      residentEmail: 'sofia@example.com',
      requestedAt: DateTime(2026, 10, 7),
      status: MembershipStatus.rejected,
      reviewedAt: DateTime(2026, 10, 8),
    ),
    OrganizationMembership(
      id: 'MEM-006',
      organizationId: 'ORG-002',
      residentId: 'RES-006',
      residentName: 'Carlo Ramos',
      residentEmail: 'carlo@example.com',
      requestedAt: DateTime(2026, 10, 10),
    ),
  ];

  List<OrganizationMembership> forOrganization(
    String organizationId,
  ) {
    return List.unmodifiable(
      _memberships.where(
        (membership) =>
            membership.organizationId == organizationId,
      ),
    );
  }

  int countByStatus(
    String organizationId,
    MembershipStatus status,
  ) {
    return _memberships.where(
      (membership) =>
          membership.organizationId == organizationId &&
          membership.status == status,
    ).length;
  }

  void requestMembership({
    required String organizationId,
    required String residentId,
    required String residentName,
    required String residentEmail,
  }) {
    final existing = _memberships.any(
      (membership) =>
          membership.organizationId == organizationId &&
          membership.residentId == residentId,
    );

    if (existing) {
      throw StateError(
        'This resident already has a membership record.',
      );
    }

    _memberships.add(
      OrganizationMembership(
        id: 'MEM-${DateTime.now().microsecondsSinceEpoch}',
        organizationId: organizationId,
        residentId: residentId,
        residentName: residentName,
        residentEmail: residentEmail,
        requestedAt: DateTime.now(),
      ),
    );

    notifyListeners();
  }

  void approveMembership(
    String membershipId,
    String organizationId,
  ) {
    _reviewMembership(
      membershipId,
      organizationId,
      MembershipStatus.approved,
    );
  }

  void rejectMembership(
    String membershipId,
    String organizationId,
  ) {
    _reviewMembership(
      membershipId,
      organizationId,
      MembershipStatus.rejected,
    );
  }

  void _reviewMembership(
    String membershipId,
    String organizationId,
    MembershipStatus newStatus,
  ) {
    final index = _memberships.indexWhere(
      (membership) =>
          membership.id == membershipId &&
          membership.organizationId == organizationId,
    );

    if (index == -1) {
      throw StateError('Membership record not found.');
    }

    final membership = _memberships[index];

    if (membership.status != MembershipStatus.pending) {
      throw StateError(
        'Only pending applications can be reviewed.',
      );
    }

    _memberships[index] = membership.copyWith(
      status: newStatus,
      reviewedAt: DateTime.now(),
    );

    notifyListeners();
  }
}
