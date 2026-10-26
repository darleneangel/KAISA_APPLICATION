import 'package:supabase_flutter/supabase_flutter.dart';

class KaisaOtpState {
  final DateTime? expiresAt;
  final int attempts;
  final int resends;
  final bool sent;
  final bool verified;
  const KaisaOtpState({
    this.expiresAt,
    this.attempts = 0,
    this.resends = 0,
    this.sent = false,
    this.verified = false,
  });
  factory KaisaOtpState.fromMap(Map<String, dynamic> map) => KaisaOtpState(
    expiresAt: DateTime.tryParse('${map['expires_at'] ?? ''}')?.toLocal(),
    attempts: (map['attempts'] as num?)?.toInt() ?? 0,
    resends: (map['resends'] as num?)?.toInt() ?? 0,
    sent: map['sent'] == true,
    verified: map['verified'] == true,
  );
  int get secondsLeft {
    final end = expiresAt;
    if (end == null) return 0;
    final remaining = end.difference(DateTime.now()).inSeconds;
    return remaining < 0 ? 0 : (remaining > 60 ? 60 : remaining);
  }
}

class SocialOtpService {
  SocialOtpService._();
  static final instance = SocialOtpService._();
  SupabaseClient get _db => Supabase.instance.client;
  bool isSocial(User user) =>
      (user.identities ?? []).any(
        (i) => i.provider == 'google' || i.provider == 'facebook',
      ) ||
      ['google', 'facebook'].contains(user.appMetadata['provider']);

  Future<bool> hasCompleted(User user) async {
    if (!isSocial(user)) return true;
    final record = await _db
        .from('social_otp_verifications')
        .select('user_id')
        .eq('user_id', user.id)
        .maybeSingle();
    return record != null;
  }

  Future<Map<String, dynamic>> _invoke(
    String name,
    Map<String, dynamic> body,
  ) async {
    final result = await _db.functions.invoke(name, body: body);
    final raw = result.data;
    if (raw is! Map)
      throw Exception('OTP server returned an unexpected response.');
    final data = Map<String, dynamic>.from(raw);
    if (data['error'] != null) throw Exception(data['error'].toString());
    return data;
  }

  Future<KaisaOtpState> status() async => KaisaOtpState.fromMap(
    await _invoke('request-social-otp', {'action': 'status'}),
  );
  Future<KaisaOtpState> send() async => KaisaOtpState.fromMap(
    await _invoke('request-social-otp', {'action': 'send'}),
  );
  Future<KaisaOtpState> resend() async => KaisaOtpState.fromMap(
    await _invoke('request-social-otp', {'action': 'resend'}),
  );
  Future<void> verify(String code) async {
    final data = await _invoke('confirm-social-otp', {'code': code});
    if (data['verified'] != true) throw Exception('Verification failed.');
  }
}
