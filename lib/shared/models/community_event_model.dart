
enum CommunityEventStatus {
  upcoming,
  ongoing,
  completed,
  cancelled,
}

class CommunityEvent {
  final String id;
  final String organizationId;
  final String title;
  final String description;
  final String location;
  final DateTime startsAt;
  final DateTime endsAt;
  final CommunityEventStatus status;
  final int registrationCount;
  final int attendanceCount;
  final int capacity;

  const CommunityEvent({
    required this.id,
    required this.organizationId,
    required this.title,
    required this.description,
    required this.location,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.registrationCount,
    required this.attendanceCount,
    required this.capacity,
  });
}

extension CommunityEventStatusLabel on CommunityEventStatus {
  String get label {
    switch (this) {
      case CommunityEventStatus.upcoming:
        return 'Upcoming';
      case CommunityEventStatus.ongoing:
        return 'Ongoing';
      case CommunityEventStatus.completed:
        return 'Completed';
      case CommunityEventStatus.cancelled:
        return 'Cancelled';
    }
  }
}
