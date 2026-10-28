import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<KaisaEvent?> getEvent(String id) async {
    final events = await listEvents();
    for (final e in events) {
      if (e.id == id) return e;
    }
    return null;
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
