import '../events/kaisa_events_repository.dart';

enum FeedDateFilter {
  any('Any date'),
  today('Today'),
  week('This week'),
  month('This month'),
  custom('Custom dates');

  const FeedDateFilter(this.label);
  final String label;
}

enum FeedAvailability {
  any('Any availability'),
  available('Slots remaining'),
  full('Fully booked'),
  registered('Already registered');

  const FeedAvailability(this.label);
  final String label;
}

enum FeedSort {
  recommended('Recommended'),
  upcoming('Upcoming soon'),
  newest('Recently added');

  const FeedSort(this.label);
  final String label;
}

// Asia/Manila uses UTC+08:00 for present-day civic schedules. Represent the
// wall-clock values in UTC containers to avoid the device timezone.
DateTime feedManilaTime(DateTime value) =>
    value.toUtc().add(const Duration(hours: 8));

DateTime _calendarDate(DateTime value) =>
    DateTime.utc(value.year, value.month, value.day);

bool feedSearchMatches(String text, String query) {
  final normalized = text.toLowerCase();
  return query
      .trim()
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .every(normalized.contains);
}

bool feedEventHasSlots(KaisaEvent event, DateTime now) =>
    event.startsAt.isAfter(now) && !event.isFull && !event.isRegistered;

({List<KaisaEvent> followed, List<KaisaEvent> remaining})
partitionFollowedEvents(
  Iterable<KaisaEvent> events,
  bool Function(KaisaEvent event) isFollowed,
) {
  final followed = <KaisaEvent>[];
  final remaining = <KaisaEvent>[];
  for (final event in events) {
    (isFollowed(event) ? followed : remaining).add(event);
  }
  return (followed: followed, remaining: remaining);
}

List<KaisaEvent> filterFeedEvents(
  Iterable<KaisaEvent> events, {
  required DateTime now,
  String query = '',
  String? category,
  String? organizer,
  String? location,
  FeedDateFilter dates = FeedDateFilter.any,
  (DateTime, DateTime)? customDates,
  FeedAvailability availability = FeedAvailability.any,
  FeedSort sort = FeedSort.recommended,
  Map<String, DateTime> creationDates = const {},
  bool includeEnded = false,
}) {
  final today = _calendarDate(feedManilaTime(now));
  final monday = today.subtract(Duration(days: today.weekday - 1));
  const day = Duration(days: 1);
  final window = switch (dates) {
    FeedDateFilter.any => null,
    FeedDateFilter.today => (today, today.add(day)),
    FeedDateFilter.week => (monday, monday.add(const Duration(days: 7))),
    FeedDateFilter.month => (
      DateTime.utc(today.year, today.month),
      DateTime.utc(today.year, today.month + 1),
    ),
    FeedDateFilter.custom => (
      _calendarDate(customDates!.$1),
      _calendarDate(customDates.$2).add(day),
    ),
  };
  final results = events.where((event) {
    if (!includeEnded && !event.endsAt.isAfter(now)) return false;
    final date = _calendarDate(feedManilaTime(event.startsAt));
    final matchesDate =
        window == null ||
        (!date.isBefore(window.$1) && date.isBefore(window.$2));
    final matchesAvailability = switch (availability) {
      FeedAvailability.any => true,
      FeedAvailability.available => feedEventHasSlots(event, now),
      FeedAvailability.full => event.isFull,
      FeedAvailability.registered => event.isRegistered,
    };
    return matchesDate &&
        matchesAvailability &&
        (category == null || event.category == category) &&
        (organizer == null || event.organization == organizer) &&
        (location == null || event.location == location) &&
        feedSearchMatches(
          '${event.title} ${event.description} ${event.organization} '
          '${event.category} ${event.location}',
          query,
        );
  }).toList();
  final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  int priority(KaisaEvent event) {
    if (event.isRegistered) return 2;
    return feedEventHasSlots(event, now) ? 0 : 1;
  }

  results.sort((a, b) {
    final order = switch (sort) {
      FeedSort.recommended => priority(a).compareTo(priority(b)),
      FeedSort.upcoming => 0,
      FeedSort.newest => (creationDates[b.id] ?? epoch).compareTo(
        creationDates[a.id] ?? epoch,
      ),
    };
    if (order != 0) return order;
    final byStart = a.startsAt.compareTo(b.startsAt);
    return byStart != 0 ? byStart : a.id.compareTo(b.id);
  });
  return results;
}
