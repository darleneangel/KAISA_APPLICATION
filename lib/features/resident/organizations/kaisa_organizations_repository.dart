import 'package:supabase_flutter/supabase_flutter.dart';

class KaisaOrganization {
  const KaisaOrganization({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.mission,
    required this.location,
    required this.contactEmail,
    required this.memberCount,
    this.myStatus,
    this.myRole,
  });
  final String id, name, category, description, mission, location, contactEmail;
  final int memberCount;
  final String? myStatus, myRole;
  bool get isMember => myStatus == 'approved';
  bool get isPending => myStatus == 'pending';
  Map<String, dynamic> toRouteExtra() => {
    'organization_id': id,
    'name': name,
    'category': category,
    'description': description,
    'members': memberCount,
  };
  factory KaisaOrganization.fromJson(Map<String, dynamic> json) =>
      KaisaOrganization(
        id: '${json['id']}',
        name: '${json['name'] ?? ''}',
        category: '${json['category'] ?? 'Community'}',
        description: '${json['description'] ?? ''}',
        mission: '${json['mission'] ?? ''}',
        location: '${json['location'] ?? ''}',
        contactEmail: '${json['contact_email'] ?? ''}',
        memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
        myStatus: json['my_status']?.toString(),
        myRole: json['my_role']?.toString(),
      );
}

class KaisaOrganizationsRepository {
  KaisaOrganizationsRepository._();
  static final instance = KaisaOrganizationsRepository._();
  final _db = Supabase.instance.client;
  Future<List<KaisaOrganization>> getOrganizations() async {
    final data = await _db.rpc('kaisa_organizations_catalog');
    return (data as List)
        .map(
          (row) =>
              KaisaOrganization.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<KaisaOrganization?> getOrganization(String id) async {
    final list = await getOrganizations();
    for (final org in list) {
      if (org.id == id) return org;
    }
    return null;
  }

  Future<bool> isTier2() async => await _db.rpc('kaisa_is_tier2') == true;
  Future<void> requestMembership(String id) async {
    await _db.rpc('kaisa_join_organization', params: {'p_organization_id': id});
  }

  Future<void> withdrawRequest(String id) async {
    await _db.rpc(
      'kaisa_withdraw_organization',
      params: {'p_organization_id': id},
    );
  }

  Future<void> propose({
    required String name,
    required String category,
    required String description,
    required String mission,
    required String representative,
    required String reason,
  }) async {
    await _db.rpc(
      'kaisa_request_organization',
      params: {
        'p_name': name,
        'p_category': category,
        'p_description': description,
        'p_mission': mission,
        'p_representative_name': representative,
        'p_reason': reason,
      },
    );
  }
}
