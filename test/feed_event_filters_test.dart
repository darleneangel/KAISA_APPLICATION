import 'package:flutter_test/flutter_test.dart';
import 'package:kaisa_application/features/resident/events/kaisa_events_repository.dart';
import 'package:kaisa_application/features/resident/feed/feed_event_filters.dart';

void main() {
  final now = DateTime.utc(2026, 11, 29, 16);

  KaisaEvent event(
    String id,
    DateTime start, {
    String category = 'Environment',
    String organization = 'Cavite Volunteers',
    String location = 'Samonte Park',
    int count = 0,
    String? registration,
  }) => KaisaEvent(
    id: id,
    title: 'Coastal cleanup',
    organization: organization,
    category: category,
    description: 'Bring gloves to help restore mangroves.',
    location: location,
    startsAt: start,
    endsAt: start.add(const Duration(hours: 2)),
    capacity: 10,
    registeredCount: count,
    registrationStatus: registration,
  );

  test(
    'followed events move ahead without changing order inside each group',
    () {
      final ordinary = event('ordinary', now);
      final followed = event('followed', now);
      final otherFollowed = event('second-followed', now);
      final other = event('second-ordinary', now);
      final groups = partitionFollowedEvents([
        ordinary,
        followed,
        other,
        otherFollowed,
      ], (event) => event.id == 'followed' || event.id == 'second-followed');
      expect(groups.followed, [followed, otherFollowed]);
      expect(groups.remaining, [ordinary, other]);
    },
  );

  test('combined filters use Manila calendar dates and search all fields', () {
    final matches = event('matches', DateTime.utc(2026, 11, 29, 17));
    final results = filterFeedEvents(
      [
        matches,
        event('previous day', DateTime.utc(2026, 11, 29, 15, 59)),
        event('next day', DateTime.utc(2026, 11, 30, 16)),
        event('full', matches.startsAt, count: 10),
        event('wrong category', matches.startsAt, category: 'Health'),
        event('wrong organizer', matches.startsAt, organization: 'Other'),
        event('wrong venue', matches.startsAt, location: 'Other'),
      ],
      now: now,
      query: '  MANGROVES cleanup   cavite samonte ',
      category: 'Environment',
      organizer: 'Cavite Volunteers',
      location: 'Samonte Park',
      dates: FeedDateFilter.today,
      availability: FeedAvailability.available,
    );

    expect(results, [matches]);
  });

  test('week, month and inclusive custom range use Manila boundaries', () {
    final monday = event('Monday', DateTime.utc(2026, 11, 29, 17));
    final december = event('December', DateTime.utc(2026, 11, 30, 16));
    final nextMonday = event('Next week', DateTime.utc(2026, 12, 6, 16));
    final events = [monday, december, nextMonday];

    expect(filterFeedEvents(events, now: now, dates: FeedDateFilter.week), [
      monday,
      december,
    ]);
    expect(filterFeedEvents(events, now: now, dates: FeedDateFilter.month), [
      monday,
    ]);
    expect(
      filterFeedEvents(
        events,
        now: now,
        dates: FeedDateFilter.custom,
        customDates: (DateTime(2026, 12, 1), DateTime(2026, 12, 1)),
      ),
      [december],
    );
  });

  test('sorts by availability, start time or actual creation time', () {
    final past = event('past', now.subtract(const Duration(hours: 4)));
    final full = event('full', now.add(const Duration(hours: 1)), count: 10);
    final open = event('open', now.add(const Duration(hours: 2)));
    final registered = event(
      'registered',
      now.add(const Duration(hours: 3)),
      registration: 'registered',
    );
    final events = [registered, open, full, past];
    expect(filterFeedEvents(events, now: now), [open, full, registered]);
    expect(filterFeedEvents(events, now: now, sort: FeedSort.upcoming), [
      full,
      open,
      registered,
    ]);
    expect(
      filterFeedEvents(
        events,
        now: now,
        sort: FeedSort.newest,
        creationDates: {'open': DateTime.utc(2026), 'registered': now},
      ),
      [registered, open, full],
    );
    expect(
      filterFeedEvents(
        events,
        now: now,
        availability: FeedAvailability.registered,
      ),
      [registered],
    );
  });
}
