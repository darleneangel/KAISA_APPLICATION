
enum MembershipStatus {
  pending,
  approved,
  rejected,
}

extension MembershipStatusLabel on MembershipStatus {
  String get label {
    switch (this) {
      case MembershipStatus.pending:
        return 'Pending';
      case MembershipStatus.approved:
        return 'Approved';
      case MembershipStatus.rejected:
        return 'Rejected';
    }
  }
}

class OrganizationMembership {
  final String id;
  final String organizationId;
  final String residentId;
  final String residentName;
  final String residentEmail;
  final DateTime requestedAt;
  final MembershipStatus status;
  final DateTime? reviewedAt;

  const OrganizationMembership({
    required this.id,
    required this.organizationId,
    required this.residentId,
    required this.residentName,
    required this.residentEmail,
    required this.requestedAt,
    this.status = MembershipStatus.pending,
    this.reviewedAt,
  });

  OrganizationMembership copyWith({
    MembershipStatus? status,
    DateTime? reviewedAt,
  }) {
    return OrganizationMembership(
      id: id,
      organizationId: organizationId,
      residentId: residentId,
      residentName: residentName,
      residentEmail: residentEmail,
      requestedAt: requestedAt,
      status: status ?? this.status,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }
}
