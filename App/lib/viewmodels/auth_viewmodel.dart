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
  AuthViewModel() : super(const AuthState());

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
      // 1 — Exchange credentials for a JWT
      final result = await ApiService.login(email.trim(), password);
      final token = result['access_token'] as String;
      await ApiService.saveToken(token);

      // 2 — Decode the JWT to extract role + userId
      final payload = _decodeJwt(token);
      final role =
          (payload['role'] ?? payload['user_role'] ?? payload['type'] ?? '')
              .toString()
              .toLowerCase();
      final userId = payload['sub'] ?? payload['user_id'] ?? payload['id'] ?? 0;

      // 3 — Fetch the detailed user record for the resolved role
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
      } catch (_) {
        // Non-fatal — profile built from JWT payload only
      }

      // 4 — Build the UserProfile
      final profile = _buildProfile(userMap, email.trim(), role, userId);

      // 5 — Resolve destination; fall back to email lookup for unknown roles
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

      // 6 — Persist the role so SplashScreen can restore the session
      final roleToSave = dest == AuthDestination.doctor
          ? 'doctor'
          : 'assistant';
      await ApiService.saveRole(roleToSave);

      // 7 — Persist the profile so SplashScreen can pass it to the interface
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

  /// Fully resets auth state AND clears the persisted token + role.
  ///
  /// Bug fix: previously this only did `state = const AuthState()` without
  /// calling ApiService.logout(), so the token was never cleared here.
  /// The doctor/assistant interfaces called ApiService.logout() separately
  /// but never reset AuthState — leaving it as isAuthenticated=true with
  /// the old destination.  On the next login the listener in LoginPage
  /// would fire with stale destination and push the wrong interface.
  Future<void> logout() async {
    await ApiService.logout(); // clears token + role from secure storage
    state = const AuthState(); // resets Riverpod state (destination → none)
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE — Registration HTTP helpers
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
    id: (u['user_id'] ?? u['id'] ?? userId).toString(),
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
