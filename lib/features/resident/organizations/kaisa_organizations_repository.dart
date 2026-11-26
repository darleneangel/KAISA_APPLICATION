import 'package:flutter/foundation.dart';
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
  final followsChanged = ValueNotifier<int>(0);

  Future<Set<String>?> followedOrganizations() async {
    try {
      final rows = await _db
          .from('kaisa_organization_follows')
          .select('organization_id');
      return rows.map((row) => row['organization_id'] as String).toSet();
    } on PostgrestException catch (error) {
      if (error.code == 'PGRST205' || error.code == '42P01') return null;
      rethrow;
    }
  }

  Future<void> setFollowing(String id, bool following) async {
    if (following) {
      try {
        await _db.from('kaisa_organization_follows').insert({
          'organization_id': id,
        });
      } on PostgrestException catch (error) {
        if (error.code != '23505') rethrow;
      }
    } else {
      await _db
          .from('kaisa_organization_follows')
          .delete()
          .eq('organization_id', id);
    }
    followsChanged.value++;
  }

  Future<Map<String, Map<String, dynamic>>> profiles([String? id]) async {
    try {
      final query = _db
          .from('kaisa_organization_profiles')
          .select(
            'organization_id, cover_image, logo_image, gallery_images, vision, website, office_hours, sdg_goals',
          );
      final rows = await (id == null ? query : query.eq('organization_id', id));
      return {for (final row in rows) row['organization_id'] as String: row};
    } on PostgrestException catch (error) {
      if (error.code == 'PGRST205' || error.code == '42P01') return {};
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> feedback(String id) async {
    try {
      final value = await _db.rpc(
        'kaisa_resident_organization_feedback',
        params: {'p_organization_id': id},
      );
      return Map<String, dynamic>.from(value as Map);
    } on PostgrestException catch (error) {
      if (error.code == 'PGRST202') return null;
      rethrow;
    }
  }

  Future<void> rate(String id, int stars, String comment) async {
    await _db.rpc(
      'kaisa_resident_rate_organization',
      params: {
        'p_organization_id': id,
        'p_rating': stars,
        'p_comment': comment,
      },
    );
  }

  Future<List<Map<String, dynamic>>> announcements(String id) async {
    final rows = await _db.rpc(
      'kaisa_org_announcements_list',
      params: {'p_organization_id': id},
    );
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<List<Map<String, dynamic>>> followedAnnouncements() =>
      _optionalRows('kaisa_resident_followed_announcements');

  Future<Map<String, String>> eventOrganizations() async {
    final rows = await _optionalRows('kaisa_resident_event_organizations');
    return {
      for (final row in rows)
        row['event_id'] as String: row['organization_id'] as String,
    };
  }

  Future<List<Map<String, dynamic>>> _optionalRows(String function) async {
    try {
      final rows = await _db.rpc(function);
      return List<Map<String, dynamic>>.from(rows as List);
    } on PostgrestException catch (error) {
      if (error.code == 'PGRST202') return [];
      rethrow;
    }
  }

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
