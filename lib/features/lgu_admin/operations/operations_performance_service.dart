/// KAISA Operations analytics DEMO source.
/// Purely in-memory fictional sample data. Does not read or write Supabase.
/// Remove/replace this provider when authorized performance tables are ready.
class OperationsPerformanceService {
  OperationsPerformanceService._();
  static final instance = OperationsPerformanceService._();

  Future<List<OrganizationPerformance>> fetch() async {
    // Asynchronous interface is intentionally compatible with a later
    // read-only Supabase implementation.
    return List<OrganizationPerformance>.unmodifiable(_sampleOrganizations);
  }

  static const _sampleOrganizations = <OrganizationPerformance>[
    OrganizationPerformance(
      id: 'demo-001',
      name: 'Cavite City Youth Action Network',
      category: 'Youth & Sports',
      barangay: 'San Roque',
      accreditationStatus: 'Accredited',
      members: 186,
      adminsOfficers: 9,
      events: 14,
      attendees: 842,
    ),
    OrganizationPerformance(
      id: 'demo-002',
      name: 'Green Harbor Volunteers',
      category: 'Environment',
      barangay: 'Dalahican',
      accreditationStatus: 'Accredited',
      members: 142,
      adminsOfficers: 7,
      events: 12,
      attendees: 716,
    ),
    OrganizationPerformance(
      id: 'demo-003',
      name: 'Caridad Community Health Circle',
      category: 'Health & Wellness',
      barangay: 'Caridad',
      accreditationStatus: 'Accredited',
      members: 121,
      adminsOfficers: 6,
      events: 10,
      attendees: 645,
    ),
    OrganizationPerformance(
      id: 'demo-004',
      name: 'San Antonio Neighborhood Responders',
      category: 'Disaster Preparedness',
      barangay: 'San Antonio',
      accreditationStatus: 'Accredited',
      members: 105,
      adminsOfficers: 6,
      events: 11,
      attendees: 577,
    ),
    OrganizationPerformance(
      id: 'demo-005',
      name: 'Sta. Cruz Skills Collective',
      category: 'Livelihood',
      barangay: 'Sta. Cruz',
      accreditationStatus: 'Pending Renewal',
      members: 99,
      adminsOfficers: 5,
      events: 8,
      attendees: 488,
    ),
    OrganizationPerformance(
      id: 'demo-006',
      name: 'Bayanihan Coastal Guardians',
      category: 'Environment',
      barangay: 'Dalahican',
      accreditationStatus: 'Accredited',
      members: 134,
      adminsOfficers: 8,
      events: 9,
      attendees: 533,
    ),
    OrganizationPerformance(
      id: 'demo-007',
      name: 'Cavite Women in Enterprise',
      category: 'Livelihood',
      barangay: 'Caridad',
      accreditationStatus: 'Under Review',
      members: 87,
      adminsOfficers: 5,
      events: 7,
      attendees: 352,
    ),
    OrganizationPerformance(
      id: 'demo-008',
      name: 'Kabataang Aktibo sa Kalikasan',
      category: 'Youth & Sports',
      barangay: 'San Roque',
      accreditationStatus: 'Accredited',
      members: 162,
      adminsOfficers: 9,
      events: 9,
      attendees: 610,
    ),
    OrganizationPerformance(
      id: 'demo-009',
      name: 'Community First Aid Partners',
      category: 'Health & Wellness',
      barangay: 'San Antonio',
      accreditationStatus: 'Pending Renewal',
      members: 63,
      adminsOfficers: 4,
      events: 5,
      attendees: 274,
    ),
    OrganizationPerformance(
      id: 'demo-010',
      name: 'Barangay Preparedness Alliance',
      category: 'Disaster Preparedness',
      barangay: 'Sta. Cruz',
      accreditationStatus: 'Under Review',
      members: 75,
      adminsOfficers: 5,
      events: 6,
      attendees: 301,
    ),
  ];
}

class OrganizationPerformance {
  const OrganizationPerformance({
    required this.id,
    required this.name,
    required this.category,
    required this.barangay,
    required this.accreditationStatus,
    required this.members,
    required this.adminsOfficers,
    required this.events,
    required this.attendees,
  });

  final String id;
  final String name;
  final String category;
  final String barangay;
  final String accreditationStatus;
  final int members;
  final int adminsOfficers;
  final int events;
  final int attendees;

  static int _number(dynamic value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
  static String _label(dynamic value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  factory OrganizationPerformance.fromJson(Map<String, dynamic> json) {
    return OrganizationPerformance(
      id: _label(json['organization_id'], ''),
      name: _label(json['organization_name'], 'Unnamed organization'),
      category: _label(json['category'], 'Uncategorized'),
      barangay: _label(json['barangay'], 'Unspecified barangay'),
      accreditationStatus: _label(json['accreditation_status'], 'Unknown'),
      members: _number(json['total_members']),
      adminsOfficers: _number(json['total_admins_officers']),
      events: _number(json['total_events_hosted']),
      attendees: _number(json['total_verified_attendees']),
    );
  }
}
