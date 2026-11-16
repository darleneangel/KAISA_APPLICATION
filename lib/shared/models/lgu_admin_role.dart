
enum LguAdminRole {
  it,
  verification,
  operations,
}

extension LguAdminRoleDetails on LguAdminRole {
  String get label {
    switch (this) {
      case LguAdminRole.it:
        return 'IT Administrator';
      case LguAdminRole.verification:
        return 'Verification Administrator';
      case LguAdminRole.operations:
        return 'Operations Administrator';
    }
  }

  String get databaseValue {
    switch (this) {
      case LguAdminRole.it:
        return 'lgu_it_admin';
      case LguAdminRole.verification:
        return 'lgu_verification_admin';
      case LguAdminRole.operations:
        return 'lgu_operations_admin';
    }
  }
}
