import 'package:flutter/foundation.dart';

/// In-memory demo state shared by Verification Applications and Identity Review.
/// This does NOT update Supabase, user tiers, account roles, or actual evidence.
class VerificationApplication {
  VerificationApplication({
    required this.id,
    required this.name,
    required this.type,
    required this.platform,
    required this.status,
    required this.priority,
    required this.submitted,
    required this.purpose,
    this.archivedAt,
    this.archiveReason,
  });
  final String id, name, type, platform, priority, purpose;
  final DateTime submitted;
  String status;
  DateTime? archivedAt;
  String? archiveReason;
  bool get archived => archivedAt != null;
  bool get needsAction =>
      status == 'Pending' ||
      status == 'Under Review' ||
      status == 'Resubmission';
}

class VerificationCaseEvent {
  const VerificationCaseEvent({
    required this.caseId,
    required this.action,
    required this.reason,
    required this.at,
  });
  final String caseId, action, reason;
  final DateTime at;
}

class VerificationCaseRepository extends ChangeNotifier {
  VerificationCaseRepository._();
  static final instance = VerificationCaseRepository._();
  final List<VerificationApplication> _cases = [
    VerificationApplication(
      id: 'VER-DEMO-001',
      name: 'Demo Resident A',
      type: 'Resident Tier 2',
      platform: 'Web',
      status: 'Pending',
      priority: 'High',
      submitted: DateTime(2026, 11, 16, 9, 10),
      purpose: 'Tier 1 to Tier 2 identity verification',
    ),
    VerificationApplication(
      id: 'VER-DEMO-002',
      name: 'Demo Resident B',
      type: 'Resident Tier 2',
      platform: 'Mobile',
      status: 'Under Review',
      priority: 'Normal',
      submitted: DateTime(2026, 11, 16, 10, 20),
      purpose: 'Supporting identity-evidence review',
    ),
    VerificationApplication(
      id: 'VER-DEMO-003',
      name: 'Demo Resident C',
      type: 'Resident Tier 2',
      platform: 'Mobile',
      status: 'Pending',
      priority: 'Normal',
      submitted: DateTime(2026, 11, 15, 8, 25),
      purpose: 'Tier 1 to Tier 2 identity verification',
    ),
    VerificationApplication(
      id: 'VER-DEMO-004',
      name: 'Demo Resident D',
      type: 'Resident Tier 2',
      platform: 'Web',
      status: 'Approved',
      priority: 'Normal',
      submitted: DateTime(2026, 11, 15, 11, 30),
      purpose: 'Completed demonstration application',
    ),
    VerificationApplication(
      id: 'VER-DEMO-005',
      name: 'Demo Resident E',
      type: 'Resident Tier 2',
      platform: 'Mobile',
      status: 'Resubmission',
      priority: 'High',
      submitted: DateTime(2026, 11, 14, 15, 5),
      purpose: 'Clearer identity document requested',
    ),
    VerificationApplication(
      id: 'ORG-DEMO-001',
      name: 'Demo Youth Association',
      type: 'Org Accreditation',
      platform: 'Mobile',
      status: 'Pending',
      priority: 'High',
      submitted: DateTime(2026, 11, 16, 9, 40),
      purpose: 'Accreditation and representative authorization',
    ),
    VerificationApplication(
      id: 'ORG-DEMO-002',
      name: 'Demo Civic Volunteers',
      type: 'Org Accreditation',
      platform: 'Web',
      status: 'Under Review',
      priority: 'Normal',
      submitted: DateTime(2026, 11, 13, 14, 5),
      purpose: 'By-laws and officer roster review',
    ),
    VerificationApplication(
      id: 'ORG-DEMO-003',
      name: 'Demo Neighborhood Network',
      type: 'Org Accreditation',
      platform: 'Web',
      status: 'Approved',
      priority: 'Normal',
      submitted: DateTime(2026, 11, 12, 13, 15),
      purpose: 'Completed demonstration accreditation',
    ),
    VerificationApplication(
      id: 'VER-DEMO-006',
      name: 'Demo Resident F',
      type: 'Resident Tier 2',
      platform: 'Web',
      status: 'Rejected',
      priority: 'Normal',
      submitted: DateTime(2026, 11, 10, 9, 5),
      purpose: 'Demonstration rejection; no decision evidence recorded',
    ),
    VerificationApplication(
      id: 'VER-DEMO-007',
      name: 'Demo Resident G',
      type: 'Resident Tier 2',
      platform: 'Web',
      status: 'Approved',
      priority: 'Normal',
      submitted: DateTime(2026, 11, 9, 11, 45),
      purpose: 'Completed demonstration application',
    ),
  ];
  final List<VerificationCaseEvent> _events = [];
  List<VerificationApplication> get applications => List.unmodifiable(_cases);
  List<VerificationCaseEvent> get events => List.unmodifiable(_events.reversed);
  VerificationApplication? find(String id) {
    for (final a in _cases) {
      if (a.id == id) return a;
    }
    return null;
  }

  bool recordDecision(String id, String status, String reason) {
    final c = find(id);
    if (c == null ||
        c.archived ||
        !c.needsAction ||
        !const ['Approved', 'Rejected', 'Resubmission'].contains(status) ||
        reason.trim().length < 10) {
      return false;
    }
    c.status = status;
    _events.add(
      VerificationCaseEvent(
        caseId: id,
        action: status,
        reason: reason.trim(),
        at: DateTime.now(),
      ),
    );
    notifyListeners();
    return true;
  }

  bool archive(String id, String reason) {
    final c = find(id);
    // Pending cases may not be archived to conceal or bypass review.
    if (c == null || c.archived || c.needsAction || reason.trim().length < 10) {
      return false;
    }
    c.archivedAt = DateTime.now();
    c.archiveReason = reason.trim();
    _events.add(
      VerificationCaseEvent(
        caseId: id,
        action: 'Archived',
        reason: reason.trim(),
        at: c.archivedAt!,
      ),
    );
    notifyListeners();
    return true;
  }

  bool restore(String id) {
    final c = find(id);
    if (c == null || !c.archived) return false;
    c.archivedAt = null;
    c.archiveReason = null;
    _events.add(
      VerificationCaseEvent(
        caseId: id,
        action: 'Restored',
        reason: 'Restored from the prototype archive.',
        at: DateTime.now(),
      ),
    );
    notifyListeners();
    return true;
  }
}
