import 'package:supabase_flutter/supabase_flutter.dart';

class KaisaNotification {
  const KaisaNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.targetPath,
    required this.isRead,
    required this.createdAt,
  });
  final String id, kind, title, body, targetPath;
  final bool isRead;
  final DateTime? createdAt;
  factory KaisaNotification.fromMap(Map<String, dynamic> row) =>
      KaisaNotification(
        id: row['id'].toString(),
        kind: (row['kind'] ?? 'system').toString(),
        title: (row['title'] ?? 'Notification').toString(),
        body: (row['body'] ?? '').toString().trim(),
        targetPath: (row['target_path'] ?? '').toString(),
        isRead: row['is_read'] == true,
        createdAt: DateTime.tryParse(
          (row['created_at'] ?? '').toString(),
        )?.toLocal(),
      );
  KaisaNotification read() => KaisaNotification(
    id: id,
    kind: kind,
    title: title,
    body: body,
    targetPath: targetPath,
    isRead: true,
    createdAt: createdAt,
  );
}

class KaisaNotificationRepository {
  SupabaseClient get _db => Supabase.instance.client;
  Future<List<KaisaNotification>> fetch({
    int offset = 0,
    int limit = 50,
    bool unreadOnly = false,
    String? kind,
  }) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw StateError('Please sign in again.');
    var query = _db
        .from('kaisa_notifications')
        .select('id,kind,title,body,target_path,is_read,created_at')
        .eq('recipient_id', uid);
    if (unreadOnly) query = query.eq('is_read', false);
    if (kind != null) query = query.eq('kind', kind);
    final rows = await query
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(offset, offset + limit - 1);
    return rows.map(KaisaNotification.fromMap).toList();
  }

  Future<int> unreadCount() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return 0;
    final result = await _db
        .from('kaisa_notifications')
        .select('id')
        .eq('recipient_id', uid)
        .eq('is_read', false)
        .count(CountOption.exact);
    return result.count;
  }

  Future<void> markRead(String id) async {
    await _db.rpc('kaisa_notification_mark_read', params: {'p_id': id});
  }

  Future<void> markAllRead() async {
    await _db.rpc('kaisa_notification_mark_all_read');
  }

  Future<void> delete(String id) async {
    await _db.rpc('kaisa_notification_delete_own', params: {'p_id': id});
  }
}
