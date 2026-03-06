// User Profile Model
class UserProfile {
  final String id;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final String userType;
  final String gender;
  final DateTime? birthDate;
  final String? clinicName;
  final String? licenseNumber;
  final String? phone;
  final String? region;
  final String? specialization; // doctors only
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.userType,
    required this.gender,
    this.birthDate,
    this.clinicName,
    this.licenseNumber,
    this.phone,
    this.region,
    this.specialization,
    required this.createdAt,
  });

  /// Full display name — kept for backward compatibility
  String get fullName => '$firstName $lastName'.trim();
}
