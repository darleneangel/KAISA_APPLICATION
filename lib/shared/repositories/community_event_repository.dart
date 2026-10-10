
import 'package:flutter/foundation.dart';

import '../models/community_event_model.dart';

class CommunityEventRepository extends ChangeNotifier {
  CommunityEventRepository._();

  static final CommunityEventRepository instance =
      CommunityEventRepository._();

  final List<CommunityEvent> _events = [
    CommunityEvent(
      id: 'EVT-001',
      organizationId: 'ORG-001',
      title: 'Youth Leadership Workshop',
      description:
          'A leadership development workshop for young community volunteers.',
      location: 'Cavite City Community Hall',
      startsAt: DateTime(2026, 10, 22, 9),
      endsAt: DateTime(2026, 10, 22, 16),
      status: CommunityEventStatus.upcoming,
      registrationCount: 68,
      attendanceCount: 0,
      capacity: 100,
    ),
    CommunityEvent(
      id: 'EVT-002',
      organizationId: 'ORG-002',
      title: 'Community Health Awareness Day',
      description:
          'A community outreach activity promoting health awareness.',
      location: 'Cavite City Covered Court',
      startsAt: DateTime(2026, 10, 28, 8),
      endsAt: DateTime(2026, 10, 28, 15),
      status: CommunityEventStatus.upcoming,
      registrationCount: 84,
      attendanceCount: 0,
      capacity: 150,
    ),
    CommunityEvent(
      id: 'EVT-003',
      organizationId: 'ORG-003',
      title: 'Coastal Cleanup Drive',
      description:
          'A volunteer cleanup activity supporting coastal conservation.',
      location: 'Cavite City Coastal Area',
      startsAt: DateTime(2026, 9, 20, 7),
      endsAt: DateTime(2026, 9, 20, 12),
      status: CommunityEventStatus.completed,
      registrationCount: 55,
      attendanceCount: 47,
      capacity: 80,
    ),
  ];

  List<CommunityEvent> get events =>
      List.unmodifiable(_events);

  int get totalEvents => _events.length;

  int get upcomingEvents => _events
      .where((event) =>
          event.status == CommunityEventStatus.upcoming)
      .length;

  int get ongoingEvents => _events
      .where((event) =>
          event.status == CommunityEventStatus.ongoing)
      .length;

  int get completedEvents => _events
      .where((event) =>
          event.status == CommunityEventStatus.completed)
      .length;

  int get totalRegistrations => _events.fold<int>(
        0,
        (total, event) => total + event.registrationCount,
      );

  int get totalAttendance => _events.fold<int>(
        0,
        (total, event) => total + event.attendanceCount,
      );

  void addEvent(CommunityEvent event) {
    if (_events.any((existing) => existing.id == event.id)) {
      throw StateError('Event ID already exists.');
    }

    _events.add(event);
    notifyListeners();
  }

  void updateEvent(CommunityEvent event) {
    final index = _events.indexWhere(
      (existing) => existing.id == event.id,
    );

    if (index == -1) {
      throw StateError('Event not found.');
    }

    _events[index] = event;
    notifyListeners();
  }
}
