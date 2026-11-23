// Shared audit event model. Keep legacy enum cases for backwards compatibility
// with existing KAISA modules until all usages are migrated.
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
  String get label => switch (this) {
    AuditActionType.create => 'Created',
    AuditActionType.update => 'Updated',
    AuditActionType.assign => 'Assigned',
    AuditActionType.remove => 'Removed',
    AuditActionType.statusChange => 'Status Changed',
    AuditActionType.login => 'Login',
    AuditActionType.certificate => 'Certificate',
  };
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
