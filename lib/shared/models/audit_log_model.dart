enum AuditActionType {
  create,
  update,
  assign,
  remove,
  statusChange,
  login,
  certificate,
}

extension AuditActionTypeLabel on AuditActionType {
  String get label {
    switch (this) {
      case AuditActionType.create:
        return 'Created';
      case AuditActionType.update:
        return 'Updated';
      case AuditActionType.assign:
        return 'Assigned';
      case AuditActionType.remove:
        return 'Removed';
      case AuditActionType.statusChange:
        return 'Status Changed';
      case AuditActionType.login:
        return 'Login';
      case AuditActionType.certificate:
        return 'Certificate';
    }
  }
}

class AuditLog {
  final String id;
  final String actorName;
  final String actorRole;
  final AuditActionType action;
  final String module;
  final String description;
  final String targetId;
  final DateTime timestamp;

  const AuditLog({
    required this.id,
    required this.actorName,
    required this.actorRole,
    required this.action,
    required this.module,
    required this.description,
    required this.targetId,
    required this.timestamp,
  });
}
