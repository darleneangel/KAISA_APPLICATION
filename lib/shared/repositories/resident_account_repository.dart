import 'package:flutter/foundation.dart';

enum IdentityVerificationStatus { notSubmitted, pending, approved, rejected }

class ResidentAccountRepository extends ChangeNotifier {
  ResidentAccountRepository._();

  static final ResidentAccountRepository instance =
      ResidentAccountRepository._();

  String? _email;
  String _fullName = '';
  String _phone = '';
  String _address = '';
  String _barangay = '';
  DateTime? _birthDate;

  bool _emailVerified = false;

  IdentityVerificationStatus _verificationStatus =
      IdentityVerificationStatus.notSubmitted;

  String? get email => _email;
  String get fullName => _fullName;
  String get phone => _phone;
  String get address => _address;
  String get barangay => _barangay;
  DateTime? get birthDate => _birthDate;

  bool get emailVerified => _emailVerified;

  IdentityVerificationStatus get verificationStatus => _verificationStatus;

  bool get profileComplete =>
      _fullName.trim().isNotEmpty &&
      _address.trim().isNotEmpty &&
      _barangay.trim().isNotEmpty &&
      _birthDate != null &&
      _phone.trim().isNotEmpty;

  bool get isTier2Verified =>
      _verificationStatus == IdentityVerificationStatus.approved;

  bool get canJoinOrganizations =>
      _emailVerified && profileComplete && isTier2Verified;

  void setPrototypeAccount(String email) {
    _email = email.trim();
    _emailVerified = false;
    _fullName = '';
    _phone = '';
    _address = '';
    _barangay = '';
    _birthDate = null;
    _verificationStatus = IdentityVerificationStatus.notSubmitted;
    notifyListeners();
  }

  void markEmailVerified() {
    _emailVerified = true;
    notifyListeners();
  }

  void saveProfile({
    required String fullName,
    required String phone,
    required String address,
    required String barangay,
    required DateTime birthDate,
  }) {
    _fullName = fullName.trim();
    _phone = phone.trim();
    _address = address.trim();
    _barangay = barangay.trim();
    _birthDate = birthDate;
    notifyListeners();
  }

  void submitIdentityVerification() {
    if (!profileComplete || !_emailVerified) {
      throw StateError('Complete your profile and verify your email first.');
    }

    _verificationStatus = IdentityVerificationStatus.pending;
    notifyListeners();
  }

  // Prototype only. Approval must be restricted
  // to authorized backend users in production.
  void setDemoVerificationDecision(bool approved) {
    _verificationStatus = approved
        ? IdentityVerificationStatus.approved
        : IdentityVerificationStatus.rejected;
    notifyListeners();
  }
}
