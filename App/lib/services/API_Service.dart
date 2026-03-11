import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Central API service — all backend calls go through here.
class ApiService {
  static const String _baseUrl = 'https://backend.hakim-app.cloud';
  static const String _apiKey =
      '66ba4126aa3b9f227adde3d1e8e143ad0076ad0fdaf861501051eabec00ccc0b';

  static const int _pageLimit = 100;

  static final _storage = const FlutterSecureStorage();
  static late Dio _dio;

  // ─────────────────────────────────────────────
  // UNAUTHORIZED CALLBACK
  // Registered once in main() via registerUnauthorizedHandler().
  // Fired whenever any request returns HTTP 401 so the app can
  // navigate back to the login page and clear Riverpod state.
  // ─────────────────────────────────────────────

  /// Optional callback invoked on every 401 response.
  /// Register it in main() AFTER ApiService.init():
  ///   ApiService.registerUnauthorizedHandler(() { /* navigate to login */ });
  static void Function()? _onUnauthorized;

  static void registerUnauthorizedHandler(void Function() handler) {
    _onUnauthorized = handler;
  }

  /// Clears all persisted auth data and fires the unauthorized callback.
  /// Called automatically by the 401 interceptor.
  static Future<void> _handleUnauthorized() async {
    await clearToken();
    await clearRole();
    await clearUserProfile();
    _onUnauthorized?.call();
  }

  /// Call this once in main() before runApp()
  static void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.headers['X-API-KEY'] = _apiKey;

          final token = await _storage.read(key: 'access_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            // No token in storage — this request will reach the backend
            // without an Authorization header.  Any endpoint that requires
            // authentication will respond with 401.
            print(
              '⚠️  [${options.method}] ${options.uri} — '
              'no access_token in storage; Authorization header NOT attached.',
            );
          }

          print(
            '📤 [${options.method}] ${options.uri}'
            '  params=${options.queryParameters}'
            '  body=${options.data is FormData ? "<FormData>" : options.data}'
            '  auth=${options.headers.containsKey("Authorization") ? "✓ Bearer" : "✗ MISSING"}',
          );
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('✅ [${response.statusCode}] ${response.requestOptions.uri}');
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          final status = error.response?.statusCode;
          final responseData = error.response?.data;
          String detail = '';

          if (responseData is Map) {
            final raw = responseData['detail'];
            if (raw is List && raw.isNotEmpty) {
              detail = raw
                  .map((e) {
                    final loc = (e['loc'] as List?)?.join(' → ') ?? '';
                    final msg = e['msg'] ?? '';
                    return loc.isEmpty ? msg : '$loc: $msg';
                  })
                  .join('\n');
            } else if (raw is String) {
              detail = raw;
            }
          } else if (responseData is String) {
            detail = responseData;
          }

          final readable = detail.isNotEmpty
              ? '[$status] $detail'
              : '[$status] ${error.message}';

          print('❌ API Error on ${error.requestOptions.uri}\n  $readable');

          // ── 401 handler ──────────────────────────────────────────────────
          // The backend rejected the request because the token is missing,
          // expired, or invalid.  Clear all persisted credentials so the
          // next request does not keep sending a bad token, then notify the
          // app so it can redirect the user to the login page.
          if (status == 401) {
            print(
              '🔐 401 Unauthorized — clearing stored credentials and '
              'notifying app to redirect to login.',
            );
            await _handleUnauthorized();
          }
          // ─────────────────────────────────────────────────────────────────

          return handler.next(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: readable,
              message: readable,
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TOKEN HELPERS
  // ─────────────────────────────────────────────

  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'access_token', value: token);
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: 'access_token');
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }

  // ─────────────────────────────────────────────
  // ROLE HELPERS  ← NEW
  // Persists the resolved role ('doctor' | 'assistant') so SplashScreen
  // can restore the session without going through LoginPage again.
  // ─────────────────────────────────────────────

  /// Saves the user role to secure storage after a successful login.
  static Future<void> saveRole(String role) async {
    await _storage.write(key: 'user_role', value: role.toLowerCase());
  }

  /// Reads the persisted role. Returns null when no session exists.
  static Future<String?> getRole() async {
    return await _storage.read(key: 'user_role');
  }

  /// Removes the persisted role. Called from logout().
  static Future<void> clearRole() async {
    await _storage.delete(key: 'user_role');
  }

  // ─────────────────────────────────────────────
  // USER PROFILE HELPERS  ← NEW
  // Persists the UserProfile as JSON so SplashScreen can restore
  // the session and pass it directly to DoctorInterface / AssistantInterface.
  // ─────────────────────────────────────────────

  /// Saves the user profile map to secure storage after a successful login.
  static Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    await _storage.write(key: 'user_profile', value: jsonEncode(profile));
  }

  /// Reads the persisted user profile. Returns null when no session exists.
  static Future<Map<String, dynamic>?> getUserProfile() async {
    final raw = await _storage.read(key: 'user_profile');
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Removes the persisted profile. Called from logout().
  static Future<void> clearUserProfile() async {
    await _storage.delete(key: 'user_profile');
  }

  // ─────────────────────────────────────────────
  // AUTH
  // ─────────────────────────────────────────────

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await _dio.post(
      '/api/v1/auth/login',
      data: {'email': email, 'password': password},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Clears BOTH the token and the role so the session is fully invalidated.
  /// Bug fix: previously only clearToken() was called, leaving a stale role
  /// that caused SplashScreen to restore the wrong account.
  static Future<void> logout() async {
    try {
      await _dio.post('/api/v1/auth/logout');
    } catch (_) {}
    await clearToken();
    await clearRole();
    await clearUserProfile(); // ← also wipe the saved profile
  }

  // ─────────────────────────────────────────────
  // PATIENTS
  // ─────────────────────────────────────────────

  static Future<List<dynamic>> getPatients({String search = ''}) async {
    final Map<String, dynamic> queryParams = {'skip': 0, 'limit': _pageLimit};
    if (search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final response = await _dio.get(
      '/api/v1/clinic/patients',
      queryParameters: queryParams,
    );

    return _asList(response.data);
  }

  static Future<Map<String, dynamic>> createPatient(
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post('/api/v1/clinic/patients', data: data);
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updatePatient(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch(
      '/api/v1/clinic/patients/$id',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<void> deletePatient(int id) async {
    await _dio.delete('/api/v1/clinic/patients/$id');
  }

  static Future<void> assignCondition(
    int patientId,
    int conditionId,
    String? notes,
  ) async {
    await _dio.post(
      '/api/v1/clinic/patients/$patientId/conditions',
      data: {'condition_id': conditionId, 'notes': notes ?? ''},
    );
  }

  static Future<void> removeCondition(int patientId, int conditionId) async {
    await _dio.delete(
      '/api/v1/clinic/patients/$patientId/conditions/$conditionId',
    );
  }

  // ─────────────────────────────────────────────
  // CONDITIONS CATALOG
  // ─────────────────────────────────────────────

  static Future<List<dynamic>> getConditions({String search = ''}) async {
    final response = await _dio.get(
      '/api/v1/clinic/conditions',
      queryParameters: {'search': search},
    );
    return _asList(response.data);
  }

  static Future<Map<String, dynamic>> createCondition(
    String name,
    String category,
  ) async {
    final response = await _dio.post(
      '/api/v1/clinic/conditions',
      data: {'name': name, 'category': category},
    );
    return response.data as Map<String, dynamic>;
  }

  // ─────────────────────────────────────────────
  // APPOINTMENTS
  // ─────────────────────────────────────────────

  static Future<List<dynamic>> getAppointments({
    int? doctorId,
    int? patientId,
    String? status,
  }) async {
    final Map<String, dynamic> queryParams = {'skip': 0, 'limit': _pageLimit};

    if (doctorId != null && doctorId > 0) {
      queryParams['doctor_id'] = doctorId;
    }
    if (patientId != null && patientId > 0) {
      queryParams['patient_id'] = patientId;
    }
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status.toUpperCase();
    }

    final response = await _dio.get(
      '/api/v1/clinic/appointments',
      queryParameters: queryParams,
    );

    return _asList(response.data);
  }

  static Future<Map<String, dynamic>> createAppointment(
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post('/api/v1/clinic/appointments', data: data);
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateAppointment(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch(
      '/api/v1/clinic/appointments/$id',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<void> updateAppointmentStatus(int id, String status) async {
    await _dio.patch(
      '/api/v1/clinic/appointments/$id/status',
      data: {'status': status.toUpperCase()},
    );
  }

  static Future<void> deleteAppointment(int id) async {
    await _dio.delete('/api/v1/clinic/appointments/$id');
  }

  // ─────────────────────────────────────────────
  // APPOINTMENT TYPES
  // ─────────────────────────────────────────────

  static Future<List<dynamic>> getAppointmentTypes({int? doctorId}) async {
    final Map<String, dynamic> queryParams = {
      'skip': 0,
      'limit': _pageLimit,
      if (doctorId != null && doctorId > 0) 'doctor_id': doctorId,
    };

    final response = await _dio.get(
      '/api/v1/clinic/appointment-types',
      queryParameters: queryParams,
    );
    return _asList(response.data);
  }

  // ─────────────────────────────────────────────
  // VISITS
  // ─────────────────────────────────────────────

  static Future<Map<String, dynamic>> startVisit(
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post('/api/v1/clinic/visits', data: data);
    return response.data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getVisits({
    int? doctorId,
    int? patientId,
    String? status,
  }) async {
    final Map<String, dynamic> queryParams = {'skip': 0, 'limit': _pageLimit};
    if (doctorId != null && doctorId > 0) queryParams['doctor_id'] = doctorId;
    if (patientId != null && patientId > 0) {
      queryParams['patient_id'] = patientId;
    }
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status.toUpperCase();
    }

    final response = await _dio.get(
      '/api/v1/clinic/visits',
      queryParameters: queryParams,
    );
    return _asList(response.data);
  }

  static Future<void> updateVisitStatus(int visitId, String status) async {
    await _dio.patch(
      '/api/v1/clinic/visits/$visitId/status',
      data: {'status': status.toUpperCase()},
    );
  }

  // ─────────────────────────────────────────────
  // MEDICAL REPORTS
  // ─────────────────────────────────────────────

  static Future<List<dynamic>> getMedicalReports({
    int? patientId,
    int? doctorId,
    int? visitId,
  }) async {
    final Map<String, dynamic> queryParams = {'skip': 0, 'limit': _pageLimit};
    if (patientId != null) queryParams['patient_id'] = patientId;
    if (doctorId != null) queryParams['doctor_id'] = doctorId;
    if (visitId != null) queryParams['visit_id'] = visitId;

    final response = await _dio.get(
      '/api/v1/reports/medical-reports',
      queryParameters: queryParams,
    );
    return _asList(response.data);
  }

  static Future<Map<String, dynamic>> createMedicalReport(
    Map<String, dynamic> data,
  ) async {
    assert(
      data.containsKey('visit_id'),
      'createMedicalReport: visit_id is required by the backend',
    );
    final response = await _dio.post(
      '/api/v1/reports/medical-reports',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateMedicalReport(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch(
      '/api/v1/reports/medical-reports/$id',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<void> updateReportStatus(int id, String status) async {
    await _dio.patch(
      '/api/v1/reports/medical-reports/$id/status',
      data: {'status': status},
    );
  }

  // ─────────────────────────────────────────────
  // VOICE TRANSCRIPTION (AI)
  // ─────────────────────────────────────────────

  static Future<Map<String, dynamic>> transcribeAudio({
    required File audioFile,
    required int visitId,
  }) async {
    final formData = FormData.fromMap({
      'visit_id': visitId.toString(),
      'audio_file': await MultipartFile.fromFile(
        audioFile.path,
        filename: audioFile.path.split('/').last,
      ),
    });

    final response = await _dio.post(
      '/api/v1/reports/transcribe',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return response.data as Map<String, dynamic>;
  }

  // ─────────────────────────────────────────────
  // MEDICAL IMAGES (AI)
  // ─────────────────────────────────────────────

  static Future<Map<String, dynamic>> uploadMedicalImage({
    required File imageFile,
    required int visitId,
    required String imageType,
    String description = '',
  }) async {
    final formData = FormData.fromMap({
      'visit_id': visitId.toString(),
      'image_type': imageType,
      'description': description,
      'image_file': await MultipartFile.fromFile(
        imageFile.path,
        filename: imageFile.path.split('/').last,
      ),
    });

    final response = await _dio.post(
      '/api/v1/reports/medical-images',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getVisitImages(int visitId) async {
    final response = await _dio.get(
      '/api/v1/reports/visits/$visitId/medical-images',
    );
    return _asList(response.data);
  }

  // ─────────────────────────────────────────────
  // LAB REPORTS
  // ─────────────────────────────────────────────

  static Future<Map<String, dynamic>> uploadLabReport({
    required File pdfFile,
    required int visitId,
    required String testName,
    String labName = '',
  }) async {
    final formData = FormData.fromMap({
      'visit_id': visitId.toString(),
      'test_name': testName,
      'lab_name': labName,
      'report_file': await MultipartFile.fromFile(
        pdfFile.path,
        filename: pdfFile.path.split('/').last,
      ),
    });

    final response = await _dio.post(
      '/api/v1/reports/lab-reports',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return response.data as Map<String, dynamic>;
  }

  // ─────────────────────────────────────────────
  // DOCTORS
  // ─────────────────────────────────────────────

  static Future<List<dynamic>> getDoctors() async {
    final response = await _dio.get(
      '/api/v1/users/doctors',
      queryParameters: {'skip': 0, 'limit': _pageLimit},
    );
    return _asList(response.data);
  }

  static Future<Map<String, dynamic>> getDoctorById(int id) async {
    final response = await _dio.get('/api/v1/users/doctors/$id');
    return response.data as Map<String, dynamic>;
  }

  // ─────────────────────────────────────────────
  // ASSISTANTS
  // ─────────────────────────────────────────────

  static Future<List<dynamic>> getAssistants() async {
    final response = await _dio.get(
      '/api/v1/users/assistants',
      queryParameters: {'skip': 0, 'limit': _pageLimit},
    );
    return _asList(response.data);
  }

  // ─────────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────────

  static List<dynamic> _asList(dynamic data) {
    if (data is List) return data;

    if (data is Map) {
      const knownKeys = [
        'items',
        'data',
        'results',
        'appointments',
        'patients',
        'visits',
        'records',
        'reports',
        'list',
        'types',
        'appointment_types',
      ];
      for (final key in knownKeys) {
        if (data.containsKey(key) && data[key] is List) {
          return data[key] as List<dynamic>;
        }
      }

      for (final value in data.values) {
        if (value is List) {
          print(
            '⚠️  _asList: unknown wrapper key — '
            'using first List found. Keys: ${data.keys.toList()}',
          );
          return value;
        }
      }
      print(
        '⚠️  _asList: response was a Map but no List value found. '
        'Keys: ${data.keys.toList()} | Raw: $data',
      );
    }

    if (data != null) {
      print('⚠️  _asList: unexpected data type ${data.runtimeType}: $data');
    }

    return [];
  }

  static String extractError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final detail = data['detail'];
        if (detail is String) return detail;
        if (detail is List && detail.isNotEmpty) {
          return detail
              .map((d) => '${d['loc']?.last ?? ''}: ${d['msg'] ?? ''}')
              .join(', ');
        }
      }
      return e.message ?? e.toString();
    }
    return e.toString();
  }
}
