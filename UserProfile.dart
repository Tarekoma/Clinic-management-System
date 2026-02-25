// User Profile Model
class UserProfile {
  final String id;
  final String email;
  final String username;
  final String fullName;
  final String userType;
  final String gender;
  final DateTime? birthDate;
  final String? clinicName;
  final String? licenseNumber;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.username,
    required this.fullName,
    required this.userType,
    required this.gender,
    this.birthDate,
    this.clinicName,
    this.licenseNumber,
    required this.createdAt,
  });
}
