import 'package:supabase_flutter/supabase_flutter.dart';

class KaisaManagedOrganization {
  const KaisaManagedOrganization({required this.id, required this.name, required this.role});
  final String id;
  final String name;
  final String role;
  factory KaisaManagedOrganization.fromJson(Map<String, dynamic> v) => KaisaManagedOrganization(
    id: '${v['id']}', name: '${v['name'] ?? ''}', role: '${v['role'] ?? 'Officer'}');
}

class KaisaOrganizationAccess {
  KaisaOrganizationAccess._();
  static final instance = KaisaOrganizationAccess._();
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<KaisaManagedOrganization>> managedOrganizations() async {
    final result = await _client.rpc('kaisa_my_managed_organizations');
    return (result as List).map((e) => KaisaManagedOrganization.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<List<Map<String, dynamic>>> searchResidents(String organizationId, String query) async {
    if (query.trim().length < 3) return [];
    final result = await _client.rpc('kaisa_org_invite_search', params: {
      'p_organization_id': organizationId, 'p_query': query.trim(),
    });
    return (result as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> invite({required String organizationId, required String residentId,
    required String role, String note = ''}) async {
    await _client.rpc('kaisa_org_send_staff_invite', params: {
      'p_organization_id': organizationId, 'p_user_id': residentId,
      'p_role': role, 'p_note': note,
    });
  }

  Future<List<Map<String, dynamic>>> pendingInvitations() async {
    final result = await _client.rpc('kaisa_my_staff_invitations');
    return (result as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<String> respond(String id, {required bool accept}) async =>
      (await _client.rpc('kaisa_org_respond_staff_invite',
          params: {'p_invitation_id': id, 'p_accept': accept})).toString();
}
