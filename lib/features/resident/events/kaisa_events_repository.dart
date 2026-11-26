import 'package:supabase_flutter/supabase_flutter.dart';

String? eventRegistrationRequirement(String? instructions) => RegExp(
  r'^Registration requirements:[ \t]*(\S[^\r\n]*)',
  multiLine: true,
  caseSensitive: false,
).firstMatch(instructions ?? '')?.group(1)?.trim();

List<int> eventSampleRatings(KaisaEvent event, String? instructions) {
  if (!event.title.startsWith('[TEST] ') ||
      !RegExp(
        r'^d32111fd-8580-48bc-9ab6-c7f4afb9630[1-7]$',
      ).hasMatch(event.id)) {
    return const [];
  }
  final sample = RegExp(
    r'^Sample ratings:[ \t]*([^\r\n]+)',
    multiLine: true,
  ).firstMatch(instructions ?? '')?.group(1);
  return (sample ?? '')
      .split(',')
      .map((item) => int.tryParse(item.trim()))
      .whereType<int>()
      .where((score) => score >= 1 && score <= 5)
      .toList();
}

/// Public event information only. Do not expose participant contact details.
class KaisaEvent {
  const KaisaEvent({
    required this.id,
    required this.title,
    required this.organization,
    required this.category,
    required this.description,
    required this.location,
    required this.startsAt,
    required this.endsAt,
    required this.capacity,
    required this.registeredCount,
    required this.registrationStatus,
  });
  final String id, title, organization, category, description, location;
  final DateTime startsAt, endsAt;
  final int capacity, registeredCount;
  final String? registrationStatus;

  bool get isFull => registeredCount >= capacity;
  bool get isRegistered =>
      registrationStatus == 'registered' || registrationStatus == 'attended';
  bool get isPast => endsAt.isBefore(DateTime.now());
  String get dateLabel =>
      '${_month(startsAt.month)} ${startsAt.day}, ${startsAt.year}';
  String get timeLabel => '${_clock(startsAt)} – ${_clock(endsAt)}';
  String get monthShort => _month(startsAt.month).substring(0, 3).toUpperCase();
  String get statusLabel => registrationStatus == 'cancelled'
      ? 'Cancelled'
      : registrationStatus == 'attended'
      ? 'Completed'
      : isPast
      ? 'Completed'
      : 'Upcoming';

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static String _month(int month) => _months[month - 1];
  static String _clock(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final min = time.minute.toString().padLeft(2, '0');
    return '$hour:$min ${time.hour < 12 ? 'AM' : 'PM'}';
  }

  static KaisaEvent fromJson(Map<String, dynamic> v) => KaisaEvent(
    id: '${v['id']}',
    title: '${v['title'] ?? ''}',
    organization: '${v['organization_name'] ?? 'KAISA'}',
    category: '${v['category'] ?? 'Community'}',
    description: '${v['description'] ?? ''}',
    location: '${v['location'] ?? ''}',
    startsAt: DateTime.parse('${v['starts_at']}').toLocal(),
    endsAt: DateTime.parse('${v['ends_at']}').toLocal(),
    capacity: (v['capacity'] as num).toInt(),
    registeredCount: (v['registered_count'] as num).toInt(),
    registrationStatus: v['my_status']?.toString(),
  );

  Map<String, dynamic> toRouteExtra() => {
    'event_id': id,
    'title': title,
    'organization': organization,
    'category': category,
    'description': description,
    'date': dateLabel,
    'time': timeLabel,
    'location': location,
    'participants': registeredCount,
    'capacity': capacity,
  };
}

class KaisaEventsRepository {
  KaisaEventsRepository._();
  static final instance = KaisaEventsRepository._();
  final _client = Supabase.instance.client;

  Future<List<KaisaEvent>> listEvents() async {
    final data = await _client.rpc('kaisa_events_catalog');
    return (data as List)
        .map((e) => KaisaEvent.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// The catalog RPC omits creation dates. This read uses published-event RLS.
  Future<Map<String, DateTime>> publishedEventCreationDates() async {
    const pageSize = 250;
    final dates = <String, DateTime>{};
    for (var offset = 0; ; offset += pageSize) {
      final rows = await _client
          .from('kaisa_events')
          .select('id, created_at')
          .eq('status', 'published')
          .order('id')
          .range(offset, offset + pageSize - 1);
      for (final row in rows) {
        final date = DateTime.tryParse('${row['created_at']}');
        if (date != null) dates[row['id'] as String] = date;
      }
      if (rows.length < pageSize) return dates;
    }
  }

  Future<KaisaEvent?> getEvent(String id) async {
    final events = await listEvents();
    for (final e in events) {
      if (e.id == id) return e;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getPublishedEventInfo(String id) => _client
      .from('kaisa_events')
      .select('instructions, contact_name, contact_email')
      .eq('status', 'published')
      .eq('id', id)
      .maybeSingle();

  Future<List<Map<String, dynamic>>?> getVerifiedFeedback(String id) async {
    try {
      final rows = await _client.rpc(
        'kaisa_event_modal_feedback',
        params: {'p_event_id': id},
      );
      return List<Map<String, dynamic>>.from(rows as List);
    } on PostgrestException catch (error) {
      if (error.code == 'PGRST202') return null;
      rethrow;
    }
  }

  Future<({double average, bool sample})?> getRatingSummary(
    KaisaEvent event,
  ) async {
    final verified = await getVerifiedFeedback(event.id);
    final scores =
        verified?.map((row) => row['rating'] as num).toList() ?? <num>[];
    final sample = scores.isEmpty && event.title.startsWith('[TEST] ');
    if (sample) {
      final info = await getPublishedEventInfo(event.id);
      scores.addAll(
        eventSampleRatings(event, info?['instructions'] as String?),
      );
    }
    if (scores.isEmpty) return null;
    return (
      average: scores.reduce((a, b) => a + b) / scores.length,
      sample: sample,
    );
  }

  Future<void> submitPrivateReport(
    String eventId,
    String category,
    String explanation,
  ) async {
    await _client.from('kaisa_event_private_reports').insert({
      'event_id': eventId,
      'category': category,
      'explanation': explanation,
    });
  }

  Future<bool> isTier2() async => await _client.rpc('kaisa_is_tier2') == true;
  Future<void> register(String eventId) async {
    await _client.rpc('kaisa_register_event', params: {'p_event_id': eventId});
  }

  Future<void> cancel(String eventId) async {
    await _client.rpc(
      'kaisa_cancel_event_registration',
      params: {'p_event_id': eventId},
    );
  }
}
