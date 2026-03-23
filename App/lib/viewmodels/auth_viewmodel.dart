// ─────────────────────────────────────────────────────────────────────────────
// lib/viewmodels/auth_viewmodel.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:Hakim/services/API_Service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:Hakim/model/UserProfile.dart';

// ══════════════════════════════════════════════════════════════════════════════
// DESTINATION
// ══════════════════════════════════════════════════════════════════════════════

enum AuthDestination { none, doctor, assistant }

// ══════════════════════════════════════════════════════════════════════════════
// REGISTRATION DATA
// ══════════════════════════════════════════════════════════════════════════════

class RegistrationData {
  final String userType;
  final String email;
  final String password;
  final String fullName;
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
    required this.fullName,
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

  static const String _baseUrl = 'https://backend.hakim-app.cloud';
  static const String _apiKey =
      '66ba4126aa3b9f227adde3d1e8e143ad0076ad0fdaf861501051eabec00ccc0b';
  static const String _adminEmail = 'admin@system.com';
  static const String _adminPassword = 'admin123!';

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

      final roleToSave = dest == AuthDestination.doctor
          ? 'doctor'
          : 'assistant';
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
      final adminToken = await _getAdminToken();

      if (data.isDoctor) {
        await _createDoctor(adminToken, data);
      } else {
        await _createAssistant(adminToken, data);
      }

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
  // ═══════════════════════════════════════════════════════════════════════════

  Future<String> _getAdminToken() async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/auth/login'),
      headers: {'Content-Type': 'application/json', 'X-API-KEY': _apiKey},
      body: jsonEncode({'email': _adminEmail, 'password': _adminPassword}),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin authentication failed: ${response.body}');
    }
    final token = jsonDecode(response.body)['access_token'] as String?;
    if (token == null) throw Exception('No access_token in admin response');
    return token;
  }

  Future<void> _createDoctor(String adminToken, RegistrationData d) async {
    final parts = d.fullName.trim().split(' ');
    final firstName = parts.first;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '-';
    final dob = d.dateOfBirth != null
        ? DateFormat('yyyy-MM-dd').format(d.dateOfBirth!)
        : '1990-01-01';

    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/users/doctors'),
      headers: {
        'Content-Type': 'application/json',
        'X-API-KEY': _apiKey,
        'Authorization': 'Bearer $adminToken',
      },
      body: jsonEncode({
        'email': d.email.trim(),
        'password': d.password,
        'first_name': firstName,
        'last_name': lastName,
        'date_of_birth': dob,
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
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create doctor: ${response.body}');
    }
  }

  /// Creates an assistant account.
  ///
  /// FIX: The previous version was missing `doctor_email` in the request body.
  /// Per the API spec, `doctor_email` is REQUIRED — the backend uses it to link
  /// the assistant to a doctor at creation time. Without it, the assistant JWT
  /// has no clinic scope and every call to /clinic/patients and
  /// /clinic/appointments returns an empty list.
  Future<void> _createAssistant(String adminToken, RegistrationData d) async {
    final parts = d.fullName.trim().split(' ');
    final firstName = parts.first;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '-';

    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/users/assistants'),
      headers: {
        'Content-Type': 'application/json',
        'X-API-KEY': _apiKey,
        'Authorization': 'Bearer $adminToken',
      },
      body: jsonEncode({
        'email': d.email.trim(),
        'password': d.password,
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': d.phone.trim(),
        'clinic_name': d.clinicName.trim(),
        // FIX: doctor_email was missing — it is REQUIRED by the backend.
        // Without it the assistant is created with no doctor link, which means
        // the JWT scope has no clinic and all clinic queries return empty lists.
        'doctor_email': d.doctorEmail!.trim(),
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create assistant: ${response.body}');
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
    } catch (_) {}
    return null;
  }

  String _mapLoginError(Object e) {
    final s = e.toString();
    if (s.contains('401') || s.contains('403')) {
      return 'Incorrect email or password.';
    }
    if (s.contains('SocketException') || s.contains('connection')) {
      return 'No internet connection. Please check your network.';
    }
    return 'Login failed. Please try again.';
  }

  String _mapRegistrationError(Object e) {
    final s = e.toString();
    if (s.contains('SocketException') || s.contains('connection')) {
      return 'No internet connection. Please check your network.';
    }
    if (s.contains('409') ||
        s.toLowerCase().contains('already exists') ||
        s.toLowerCase().contains('duplicate')) {
      return 'An account with this email already exists.';
    }
    final match = RegExp(r'"detail"\s*:\s*"([^"]+)"').firstMatch(s);
    if (match != null) return match.group(1)!;
    return 'Registration failed. Please try again.';
  }
}
