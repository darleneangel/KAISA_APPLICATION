import 'package:supabase_flutter/supabase_flutter.dart';

class KaisaNotification {
  final String id, kind, title, body, targetPath;
  final DateTime createdAt;
  final bool isRead;
  KaisaNotification.fromJson(Map<String, dynamic> json)
    : id = json['id'].toString(),
      kind = json['kind']?.toString() ?? 'system',
      title = json['title']?.toString() ?? 'Notification',
      body = json['body']?.toString() ?? '',
      targetPath = json['target_path']?.toString() ?? '/resident/home',
      isRead = json['is_read'] == true,
      createdAt =
          DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now();
}

class KaisaNotificationsRepository {
  KaisaNotificationsRepository._();
  static final instance = KaisaNotificationsRepository._();
  SupabaseClient get client => Supabase.instance.client;
  String? get userId => client.auth.currentUser?.id;

  Future<List<KaisaNotification>> list() async {
    if (userId == null) return [];
    final data = await client
        .from('kaisa_notifications')
        .select('id,kind,title,body,target_path,is_read,created_at')
        .eq('recipient_id', userId!)
        .order('created_at', ascending: false)
        .limit(100);
    return data.map((r) => KaisaNotification.fromJson(r)).toList();
  }

  Future<int> unreadCount() async {
    if (userId == null) return 0;
    final data = await client
        .from('kaisa_notifications')
        .select('id')
        .eq('recipient_id', userId!)
        .eq('is_read', false);
    return data.length;
  }

  Future<void> markRead(String id) async =>
      client.rpc('kaisa_notification_mark_read', params: {'p_id': id});
  Future<void> markAllRead() async =>
      client.rpc('kaisa_notification_mark_all_read');

  RealtimeChannel subscribe(void Function() onChange) {
    final uid = userId;
    if (uid == null) {
      throw StateError('Sign in to receive notifications');
    }
    return client
        .channel(
          'kaisa-notifications-$uid-${DateTime.now().microsecondsSinceEpoch}',
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'kaisa_notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_id',
            value: uid,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
  }
}
