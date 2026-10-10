
import 'package:flutter/foundation.dart';

class LguSettingsRepository extends ChangeNotifier {
  LguSettingsRepository._();

  static final LguSettingsRepository instance =
      LguSettingsRepository._();

  bool _administrativeNotifications = true;
  bool _eventNotifications = true;
  bool _assignmentNotifications = true;

  bool get administrativeNotifications =>
      _administrativeNotifications;

  bool get eventNotifications => _eventNotifications;

  bool get assignmentNotifications => _assignmentNotifications;

  void setAdministrativeNotifications(bool value) {
    if (_administrativeNotifications == value) return;
    _administrativeNotifications = value;
    notifyListeners();
  }

  void setEventNotifications(bool value) {
    if (_eventNotifications == value) return;
    _eventNotifications = value;
    notifyListeners();
  }

  void setAssignmentNotifications(bool value) {
    if (_assignmentNotifications == value) return;
    _assignmentNotifications = value;
    notifyListeners();
  }

  void resetDefaults() {
    _administrativeNotifications = true;
    _eventNotifications = true;
    _assignmentNotifications = true;
    notifyListeners();
  }
}
