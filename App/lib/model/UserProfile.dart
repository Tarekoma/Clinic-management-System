// lib/model/UserProfile.dart

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
  final String? specialization;
  final DateTime createdAt;

  // ── Assistant-only: the linked doctor's PK (doctors.id) ──────────────────
  // Populated from u['doctor_id'] in the assistants API response at login.
  // This is the exact FK the backend stores when an assistant is created with
  // doctor_email.  Mirrors how profile.id works for doctors — no discovery
  // chain needed.  Null for doctor accounts.
  final String? doctorId;

  // ── Assistant-only: the linked doctor's email ─────────────────────────────
  // Secondary identifier.  Used as fallback if doctor_id is absent.
  final String? doctorEmail;

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
    this.doctorId,
    this.doctorEmail,
  });

  String get fullName => '$firstName $lastName'.trim();
}
