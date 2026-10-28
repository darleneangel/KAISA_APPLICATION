import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/kaisa_account_refresh.dart';

class KaisaProfileRepository {
  KaisaProfileRepository._();
  static final instance = KaisaProfileRepository._();
  final db = Supabase.instance.client;
  String get myId => db.auth.currentUser!.id;

  Future<Map<String, dynamic>?> publicProfile(String uid) async {
    final value = await db.rpc(
      'kaisa_public_profile',
      params: {'p_user_id': uid},
    );
    if (value == null) return null;
    return Map<String, dynamic>.from(value as Map);
  }

  Future<List<Map<String, dynamic>>> posts(String uid) async {
    final value = await db.rpc(
      'kaisa_public_profile_posts',
      params: {'p_user_id': uid},
    );
    return (value as List)
        .map((v) => Map<String, dynamic>.from(v as Map))
        .toList();
  }

  Future<Map<String, dynamic>?> privateProfile() async => await db
      .from('resident_profiles')
      .select(
        'first_name,last_name,middle_name,province,city_municipality,barangay,bio,avatar_path',
      )
      .eq('user_id', myId)
      .maybeSingle();

  Future<bool> isTier2() async => await db.rpc('kaisa_is_tier2') == true;

  Future<void> saveProfile({required String bio, String? avatarPath}) async {
    await db.rpc(
      'kaisa_set_public_profile',
      params: {'p_bio': bio, 'p_avatar_path': avatarPath},
    );
    notifyKaisaAccountChanged();
  }

  Future<String> uploadAvatar(Uint8List bytes, String mime) async {
    if (bytes.lengthInBytes > 2 * 1024 * 1024)
      throw StateError('Maximum profile photo size is 2 MB.');
    if (!['image/jpeg', 'image/png', 'image/webp'].contains(mime)) {
      throw StateError('Only JPG, PNG or WEBP photos are supported.');
    }
    final ext = mime == 'image/png'
        ? 'png'
        : mime == 'image/webp'
        ? 'webp'
        : 'jpg';
    final path = '$myId/${DateTime.now().microsecondsSinceEpoch}.$ext';
    await db.storage
        .from('kaisa-avatars')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mime, upsert: false),
        );
    return path;
  }

  String avatarUrl(String path) =>
      db.storage.from('kaisa-avatars').getPublicUrl(path);
  String feedImageUrl(String path) =>
      db.storage.from('kaisa-feed').getPublicUrl(path);

  Future<List<Map<String, dynamic>>> attendance() async {
    final result = await db
        .from('kaisa_event_registrations')
        .select(
          'status,registered_at, event:kaisa_events(title,starts_at,location)',
        )
        .eq('user_id', myId)
        .eq('status', 'attended')
        .order('registered_at', ascending: false);
    return (result as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> certificates() async {
    final result = await db
        .from('kaisa_resident_certificates')
        .select('id,title,issued_at')
        .eq('resident_id', myId)
        .order('issued_at', ascending: false);
    return (result as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }
}
