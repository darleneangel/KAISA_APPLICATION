import 'package:flutter/foundation.dart';
import '../models/audit_log_model.dart';

/// Shared, session-only prototype. Not a tamper-proof security audit.
class AuditLogRepository extends ChangeNotifier {
  AuditLogRepository._();
  static final AuditLogRepository instance = AuditLogRepository._();

  // Fictional Operations examples; NOT actual actor identities or activity.
  final List<AuditLog> _logs = [
    AuditLog(
      id: 'OPS-DEMO-001',
      actorName: 'Operations Administrator (Demo)',
      actorRole: 'Operations Administrator',
      action: AuditActionType.create,
      module: 'Organization Registry',
      description: 'Created a sample organization registry record.',
      targetId: 'ORG-DEMO-001',
      timestamp: DateTime(2026, 11, 16, 9, 30),
    ),
    AuditLog(
      id: 'OPS-DEMO-002',
      actorName: 'Operations Administrator (Demo)',
      actorRole: 'Operations Administrator',
      action: AuditActionType.assign,
      module: 'Admin Assignments',
      description: 'Assigned a representative to a sample organization.',
      targetId: 'ORG-DEMO-001',
      timestamp: DateTime(2026, 11, 16, 10, 15),
    ),
    AuditLog(
      id: 'OPS-DEMO-003',
      actorName: 'Operations Administrator (Demo)',
      actorRole: 'Operations Administrator',
      action: AuditActionType.update,
      module: 'Event Monitoring',
      description: 'Updated a sample community event schedule.',
      targetId: 'EVT-DEMO-001',
      timestamp: DateTime(2026, 11, 17, 11, 20),
    ),
  ];

  List<AuditLog> get logs {
    final sorted = List<AuditLog>.of(_logs)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return List.unmodifiable(sorted);
  }

  int get totalLogs => _logs.length;
  int get todayLogs {
    final now = DateTime.now();
    return _logs.where((log) => log.timestamp.year == now.year &&
        log.timestamp.month == now.month && log.timestamp.day == now.day).length;
  }
  // Retained getters for callers outside Operations. These are prototype counts.
  int get securityLogs => _logs.where((log) => log.action == AuditActionType.login).length;
  int get administrativeChanges => _logs.where((log) => log.action != AuditActionType.login).length;

  void record({
    required String actorName,
    required String actorRole,
    required AuditActionType action,
    required String module,
    required String description,
    required String targetId,
  }) {
    final timestamp = DateTime.now();
    _logs.add(AuditLog(
      id: 'LOG-${timestamp.microsecondsSinceEpoch}',
      actorName: actorName,
      actorRole: actorRole,
      action: action,
      module: module,
      description: description,
      targetId: targetId,
      timestamp: timestamp,
    ));
    notifyListeners();
  }
}
