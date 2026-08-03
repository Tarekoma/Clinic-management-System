// ─────────────────────────────────────────────────────────────────────────────
// lib/viewmodels/auth_viewmodel.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:Hakim/config/app_config.dart';
import 'package:Hakim/errors/app_error.dart';
import 'package:Hakim/errors/error_handler.dart';
import 'package:Hakim/services/API_Service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:Hakim/model/UserProfile.dart';

// ══════════════════════════════════════════════════════════════════════════════
// DESTINATION
// ══════════════════════════════════════════════════════════════════════════════

enum AuthDestination { none, doctor, assistant, admin }

// ══════════════════════════════════════════════════════════════════════════════
// REGISTRATION DATA
// ══════════════════════════════════════════════════════════════════════════════

class RegistrationData {
  final String userType;
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String gender;
  final String phone;
  final DateTime? dateOfBirth;
  final String? country;
  final String? region;
  final String? city;
  final String clinicName;
  final String? specialization;
  final String? licenseNumber;

  // ── REQUIRED for assistant registration ─────────────────────────────────────
  // The backend links an assistant to a doctor via doctor_email at creation.
  // Without this field the assistant record has no clinic/doctor scope and
  // the JWT will return empty data for all clinic endpoints.
  final String? doctorEmail;

  const RegistrationData({
    required this.userType,
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.phone,
    this.dateOfBirth,
    this.country,
    this.region,
    this.city,
    required this.clinicName,
    this.specialization,
    this.licenseNumber,
    this.doctorEmail, // nullable: only required when userType == 'Assistant'
  });

  bool get isDoctor => userType == 'Doctor';
}

// ══════════════════════════════════════════════════════════════════════════════
// STATE
// ══════════════════════════════════════════════════════════════════════════════

class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final bool isAuthenticated;
  final UserProfile? user;
  final AuthDestination destination;
  final bool registrationSuccess;

  const AuthState({
    this.isLoading = false,
    this.errorMessage = null,
    this.isAuthenticated = false,
    this.user = null,
    this.destination = AuthDestination.none,
    this.registrationSuccess = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? isAuthenticated,
    UserProfile? user,
    AuthDestination? destination,
    bool? registrationSuccess,
    bool clearRegistrationSuccess = false,
  }) => AuthState(
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    user: user ?? this.user,
    destination: destination ?? this.destination,
    registrationSuccess: clearRegistrationSuccess
        ? false
        : registrationSuccess ?? this.registrationSuccess,
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// VIEWMODEL
// ══════════════════════════════════════════════════════════════════════════════

class AuthViewModel extends StateNotifier<AuthState> {
  AuthViewModel() : super(const AuthState()) {
    _instance = this;
  }

  // ── Static instance (used by the 401 handler in main.dart) ──────────────────
  static AuthViewModel? _instance;

  static void resetCurrentInstance() {
    _instance?.state = const AuthState();
  }

  static void updateUser(UserProfile profile) {
    _instance?.state = _instance!.state.copyWith(user: profile);
  }


  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC API — Login
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await ApiService.login(email.trim(), password);
      final token = result['access_token'] as String;
      await ApiService.saveToken(token);

      final payload = _decodeJwt(token);
      final role =
          (payload['role'] ?? payload['user_role'] ?? payload['type'] ?? '')
              .toString()
              .toLowerCase();
      final userId = payload['sub'] ?? payload['user_id'] ?? payload['id'] ?? 0;

      Map<String, dynamic> userMap = {};
      try {
        if (role == 'doctor') {
          final list = await ApiService.getDoctors();
          final match = list.firstWhere(
            (d) => d['email'] == email.trim(),
            orElse: () => {},
          );
          if (match.isNotEmpty) userMap = Map<String, dynamic>.from(match);
        } else if (role == 'assistant') {
          final list = await ApiService.getAssistants();
          final match = list.firstWhere(
            (a) => a['email'] == email.trim(),
            orElse: () => {},
          );
          if (match.isNotEmpty) userMap = Map<String, dynamic>.from(match);
        }
      } catch (_) {}

      final profile = _buildProfile(userMap, email.trim(), role, userId);

      AuthDestination dest;
      UserProfile resolvedProfile = profile;

      if (role == 'doctor') {
        dest = AuthDestination.doctor;
      } else if (role == 'assistant') {
        dest = AuthDestination.assistant;
      } else if (role == 'admin') {
        dest = AuthDestination.admin;
      } else {
        final resolved = await _resolveRoleByEmail(email.trim());
        if (resolved == null) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'Unknown role. Contact support.',
          );
          return;
        }
        dest = resolved.$1;
        resolvedProfile = resolved.$2;
      }

      String roleToSave;
      if (dest == AuthDestination.doctor) {
        roleToSave = 'doctor';
      } else if (dest == AuthDestination.assistant) {
        roleToSave = 'assistant';
      } else if (dest == AuthDestination.admin) {
        roleToSave = 'admin';
      } else {
        roleToSave = 'doctor';
      }
      await ApiService.saveRole(roleToSave);

      await ApiService.saveUserProfile({
        'id': resolvedProfile.id,
        'email': resolvedProfile.email,
        'username': resolvedProfile.username,
        'first_name': resolvedProfile.firstName,
        'last_name': resolvedProfile.lastName,
        'role': resolvedProfile.userType,
        'gender': resolvedProfile.gender,
        'date_of_birth': resolvedProfile.birthDate?.toIso8601String(),
        'clinic_name': resolvedProfile.clinicName,
        'license_number': resolvedProfile.licenseNumber,
        'phone_number': resolvedProfile.phone,
        'region': resolvedProfile.region,
        'specialization': resolvedProfile.specialization,
        'created_at': resolvedProfile.createdAt.toIso8601String(),
        // Persist doctor_id + doctor_email so SplashScreen can restore both
        // into UserProfile — AssistantViewModel reads doctor_id directly,
        // the same way DoctorViewModel reads profile.id.
        if (resolvedProfile.doctorId != null)
          'doctor_id': resolvedProfile.doctorId,
        if (resolvedProfile.doctorEmail != null)
          'doctor_email': resolvedProfile.doctorEmail,
      });

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: resolvedProfile,
        destination: dest,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _mapLoginError(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC API — Registration
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> register(RegistrationData data) async {
    state = state.copyWith(isLoading: true, clearError: true);

    // Validate that doctor_email is provided for assistant registration.
    if (!data.isDoctor &&
        (data.doctorEmail == null || data.doctorEmail!.trim().isEmpty)) {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'A doctor email is required to register an assistant account.',
      );
      return;
    }

    try {
      if (data.isDoctor) {
        await _registerDoctor(data);
      } else {
        await _registerAssistant(data);
      }

      // Accounts start inactive (is_active = false) — admin must activate.
      // Do NOT attempt auto-login. The view shows a "pending approval" screen.
      state = state.copyWith(isLoading: false, registrationSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapRegistrationError(e),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }

  void clearRegistrationSuccess() {
    if (state.registrationSuccess) {
      state = state.copyWith(clearRegistrationSuccess: true);
    }
  }

  Future<void> logout() async {
    await ApiService.logout();
    state = const AuthState();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE — Registration helpers
  // Uses the new public self-registration endpoints (no auth required).
  // Accounts start inactive (is_active = false) — admin activates separately.
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _registerDoctor(RegistrationData d) async {
    final firstName = d.firstName.trim();
    final lastName = d.lastName.trim().isEmpty ? '-' : d.lastName.trim();
    final dob = d.dateOfBirth != null
        ? DateFormat('yyyy-MM-dd').format(d.dateOfBirth!)
        : null;

    final body = <String, dynamic>{
      'email': d.email.trim(),
      'password': d.password,
      'first_name': firstName,
      'last_name': lastName,
      'gender': d.gender,
      'phone_number': d.phone.trim(),
      'country': d.country ?? '',
      'region': d.region ?? '',
      'city': d.city ?? '',
      'clinic_name': d.clinicName.trim(),
      'specialization': (d.specialization?.trim().isEmpty ?? true)
          ? 'General Medicine'
          : d.specialization!.trim(),
      'license_number': d.licenseNumber?.trim() ?? '',
    };
    if (dob != null) body['date_of_birth'] = dob;

    final response = await http.post(
      Uri.parse('${AppConfig.backendBaseUrl}/api/v1/users/doctors/register'),
      headers: {
        'Content-Type': 'application/json',
        'X-API-KEY': AppConfig.apiKey,
      },
      body: jsonEncode(body),
    );
    if (response.statusCode != 201) {
      throw Exception('Doctor registration failed: ${response.body}');
    }
  }

  Future<void> _registerAssistant(RegistrationData d) async {
    final firstName = d.firstName.trim();
    final lastName = d.lastName.trim().isEmpty ? '-' : d.lastName.trim();
    final dob = d.dateOfBirth != null
        ? DateFormat('yyyy-MM-dd').format(d.dateOfBirth!)
        : null;

    final body = <String, dynamic>{
      'email': d.email.trim(),
      'password': d.password,
      'first_name': firstName,
      'last_name': lastName,
      'doctor_email': d.doctorEmail!.trim(),
      'gender': d.gender,
      'phone_number': d.phone.trim(),
      'country': d.country ?? '',
      'region': d.region ?? '',
      'city': d.city ?? '',
      // clinic_name intentionally omitted: backend auto-copies it from the
      // linked doctor's record, avoiding a case/whitespace mismatch 400.
    };
    if (dob != null) body['date_of_birth'] = dob;

    final response = await http.post(
      Uri.parse('${AppConfig.backendBaseUrl}/api/v1/users/assistants/register'),
      headers: {
        'Content-Type': 'application/json',
        'X-API-KEY': AppConfig.apiKey,
      },
      body: jsonEncode(body),
    );
    if (response.statusCode != 201) {
      throw Exception('Assistant registration failed: ${response.body}');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE — Login helpers
  // ═══════════════════════════════════════════════════════════════════════════

  Map<String, dynamic> _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};
      String p = parts[1];
      while (p.length % 4 != 0) p += '=';
      return jsonDecode(utf8.decode(base64Url.decode(p)))
          as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  UserProfile _buildProfile(
    Map<String, dynamic> u,
    String email,
    String role,
    dynamic userId,
  ) => UserProfile(
    // FIX: prefer u['id'] (doctors/assistants table PK) over u['user_id']
    // (users table FK).  appointments.doctor_id references doctors.id — the
    // PK.  Previously user_id was tested first, so profile.id was set to the
    // wrong key and setDoctorId() stored the wrong value in state.
    id: (u['id'] ?? u['user_id'] ?? userId).toString(),
    email: u['email'] ?? email,
    username: u['username'] ?? email.split('@')[0],
    firstName: (u['first_name'] ?? '').toString(),
    lastName: (u['last_name'] ?? '').toString(),
    userType: u['role'] ?? role,
    gender: u['gender'] ?? '',
    birthDate: u['date_of_birth'] != null
        ? DateTime.tryParse(u['date_of_birth'].toString())
        : null,
    clinicName: u['clinic_name']?.toString(),
    licenseNumber: u['license_number']?.toString(),
    phone: (u['phone_number'] ?? u['phone'])?.toString(),
    region: u['region']?.toString(),
    specialization: u['specialization']?.toString(),
    createdAt: u['created_at'] != null
        ? DateTime.tryParse(u['created_at'].toString()) ?? DateTime.now()
        : DateTime.now(),
    // doctor_id: the linked doctor's PK (doctors.id) stored on the assistant
    // record by the backend at creation time.  Mirrors how profile.id holds
    // the doctor PK for doctor accounts — no discovery chain needed.
    // Null for doctor accounts.
    doctorId: u['doctor_id']?.toString(),
    doctorEmail: u['doctor_email']?.toString(),
  );

  Future<(AuthDestination, UserProfile)?> _resolveRoleByEmail(
    String email,
  ) async {
    try {
      final doctors = await ApiService.getDoctors();
      final docMatch = doctors.firstWhere(
        (d) => d['email'] == email,
        orElse: () => {},
      );
      if (docMatch.isNotEmpty) {
        return (
          AuthDestination.doctor,
          _buildProfile(
            Map<String, dynamic>.from(docMatch),
            email,
            'doctor',
            0,
          ),
        );
      }

      final assistants = await ApiService.getAssistants();
      final asstMatch = assistants.firstWhere(
        (a) => a['email'] == email,
        orElse: () => {},
      );
      if (asstMatch.isNotEmpty) {
        return (
          AuthDestination.assistant,
          _buildProfile(
            Map<String, dynamic>.from(asstMatch),
            email,
            'assistant',
            0,
          ),
        );
      }

      // Check admin accounts
      try {
        final admins = await ApiService.getAdmins();
        final adminMatch = admins.firstWhere(
          (a) => a['email'] == email,
          orElse: () => {},
        );
        if (adminMatch.isNotEmpty) {
          return (
            AuthDestination.admin,
            _buildProfile(
              Map<String, dynamic>.from(adminMatch),
              email,
              'admin',
              0,
            ),
          );
        }
      } catch (_) {
        // Admin endpoint may not return a list — treat as admin role if email matches
        if (email == AppConfig.registrationAdminEmail) {
          return (
            AuthDestination.admin,
            _buildProfile({}, email, 'admin', 0),
          );
        }
      }
    } catch (_) {}
    return null;
  }

  String _mapLoginError(Object e) {
    final err = ErrorHandler.parse(e, context: 'login');
    switch (err.type) {
      case AppErrorType.sessionExpired:
      case AppErrorType.forbidden:
        return 'Incorrect email or password. Please try again.';
      case AppErrorType.network:
        return err.userMessage;
      case AppErrorType.timeout:
        return err.userMessage;
      case AppErrorType.serverUnavailable:
        return err.userMessage;
      default:
        return 'Login failed. Please check your credentials and try again.';
    }
  }

  String _mapRegistrationError(Object e) {
    final err = ErrorHandler.parse(e, context: 'register');
    switch (err.type) {
      case AppErrorType.network:
      case AppErrorType.timeout:
      case AppErrorType.serverUnavailable:
        return err.userMessage;
      case AppErrorType.conflict:
        return 'An account with this email or license number already exists.';
      case AppErrorType.notFound:
        return "The doctor's email address was not found. "
            'Please verify the email and try again.';
      case AppErrorType.validation:
        return err.userMessage;
      default:
        final s = e.toString();
        // Doctor email not found can come back as a 400 with detail text.
        if (s.toLowerCase().contains('doctor') &&
            (s.toLowerCase().contains('not found') ||
                s.toLowerCase().contains('does not exist'))) {
          return "The doctor's email address was not found. "
              'Please verify the email and try again.';
        }
        // 422 with string detail: {"detail": "some message"}
        final stringDetail =
            RegExp(r'"detail"\s*:\s*"([^"]+)"').firstMatch(s);
        if (stringDetail != null) return stringDetail.group(1)!;
        // 422 with array detail — extract the first "msg" value from the list
        // e.g. {"detail":[{"msg":"Input should be 'MALE' or 'FEMALE'", ...}]}
        final firstMsg =
            RegExp(r'"msg"\s*:\s*"([^"]+)"').firstMatch(s);
        if (firstMsg != null) {
          final raw = firstMsg.group(1)!;
          // Strip FastAPI "Value error, " prefix for readability
          return raw.replaceFirst(RegExp(r'^Value error,\s*'), '');
        }
        return 'Registration failed. Please check your information and try again.';
    }
  }
}
