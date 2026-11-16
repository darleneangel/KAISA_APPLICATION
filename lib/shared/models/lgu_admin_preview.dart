
import 'package:flutter/foundation.dart';
import 'lgu_admin_role.dart';

class LguAdminPreview {
  LguAdminPreview._();

  // Frontend preview only.
  // This is NOT an authentication or authorization mechanism.
  static final ValueNotifier<LguAdminRole> selectedRole =
      ValueNotifier(LguAdminRole.operations);
}
