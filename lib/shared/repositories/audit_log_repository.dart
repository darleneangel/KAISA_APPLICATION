import 'package:flutter/foundation.dart';

import '../models/audit_log_model.dart';

class AuditLogRepository extends ChangeNotifier {
  AuditLogRepository._();

  static final AuditLogRepository instance = AuditLogRepository._();

  final List<AuditLog> _logs = [
    AuditLog(
      id: 'LOG-001',
      actorName: 'LGU Administrator (Demo)',
      actorRole: 'LGU Admin',
      action: AuditActionType.create,
      module: 'Organization Registry',
      description:
          'Created the organization record for Cavite City Youth Volunteers.',
      targetId: 'ORG-001',
      timestamp: DateTime(2026, 10, 10, 9, 30),
    ),
    AuditLog(
      id: 'LOG-002',
      actorName: 'LGU Administrator (Demo)',
      actorRole: 'LGU Admin',
      action: AuditActionType.assign,
      module: 'Admin Assignments',
      description: 'Assigned a representative to Cavite City Youth Volunteers.',
      targetId: 'ORG-001',
      timestamp: DateTime(2026, 10, 10, 10, 15),
    ),
    AuditLog(
      id: 'LOG-003',
      actorName: 'LGU Administrator (Demo)',
      actorRole: 'LGU Admin',
      action: AuditActionType.statusChange,
      module: 'Organization Registry',
      description: 'Changed the status of Coastal Care Network.',
      targetId: 'ORG-003',
      timestamp: DateTime(2026, 10, 10, 11, 20),
    ),
    AuditLog(
      id: 'LOG-004',
      actorName: 'Super Administrator (Demo)',
      actorRole: 'Super Admin',
      action: AuditActionType.login,
      module: 'Authentication',
      description: 'Signed in to the KAISA administration portal.',
      targetId: 'DEMO-ADMIN',
      timestamp: DateTime(2026, 10, 10, 13, 45),
    ),
  ];

  List<AuditLog> get logs {
    final sorted = List<AuditLog>.of(_logs);
    sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return List.unmodifiable(sorted);
  }

  int get totalLogs => _logs.length;

  int get todayLogs {
    final now = DateTime.now();

    return _logs.where((log) {
      return log.timestamp.year == now.year &&
          log.timestamp.month == now.month &&
          log.timestamp.day == now.day;
    }).length;
  }

  int get securityLogs =>
      _logs.where((log) => log.action == AuditActionType.login).length;

  int get administrativeChanges =>
      _logs.where((log) => log.action != AuditActionType.login).length;

  void record({
    required String actorName,
    required String actorRole,
    required AuditActionType action,
    required String module,
    required String description,
    required String targetId,
  }) {
    final log = AuditLog(
      id: 'LOG-${DateTime.now().microsecondsSinceEpoch}',
      actorName: actorName,
      actorRole: actorRole,
      action: action,
      module: module,
      description: description,
      targetId: targetId,
      timestamp: DateTime.now(),
    );

    _logs.add(log);
    notifyListeners();
  }
}
