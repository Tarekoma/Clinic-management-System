import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:Hakim/config/app_config.dart';
import 'package:Hakim/errors/error_handler.dart';

/// Central API service — all backend calls go through here.
class ApiService {
  static const String _baseUrl = AppConfig.backendBaseUrl;
  static const String _apiKey = AppConfig.apiKey;

  static const int _pageLimit = 100;
  static const int _pageSize = 20;

  /// Converts a backend-stored relative path (e.g. `storage/labs/abc.pdf`)
  /// to the public display URL (`https://…/uploads/labs/abc.pdf`).
  /// Pass-through if the value is already a full URL.
  static String toDisplayUrl(String storedPath) {
    if (storedPath.isEmpty) return storedPath;
    if (storedPath.startsWith('http://') ||
        storedPath.startsWith('https://')) {
      return storedPath;
    }
    final stripped = storedPath.startsWith('storage/')
        ? storedPath.substring('storage/'.length)
        : storedPath;
    return '$_baseUrl/uploads/$stripped';
  }

  /// Downloads a backend-stored file (e.g. `storage/labs/abc.pdf`) through
  /// the authenticated Dio client and saves it to the temp directory,
  /// returning the local file path.
  ///
  /// `/uploads/*` enforces the same `x-api-key`/JWT checks as the rest of
  /// the API, so a bare external-browser request to [toDisplayUrl]'s URL
  /// (which can't carry custom headers) always gets rejected with
  /// "Invalid or missing API key" — this is the only way to actually fetch
  /// the file from inside the app.
  static Future<String> downloadStoredFile(
    String storedPath, {
    String? fileName,
  }) async {
    final stripped = storedPath.startsWith('storage/')
        ? storedPath.substring('storage/'.length)
        : storedPath;
    final response = await _dio.get<List<int>>(
      '/uploads/$stripped',
      options: Options(responseType: ResponseType.bytes),
    );
    final dir = await getTemporaryDirectory();
    final name = fileName ?? stripped.split('/').last;
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(response.data!);
    return file.path;
  }

  static final _storage = const FlutterSecureStorage();
  static late Dio _dio;

  // ─────────────────────────────────────────────
  // UNAUTHORIZED CALLBACK
  // ─────────────────────────────────────────────

  static void Function()? _onUnauthorized;
  static bool _handlingUnauthorized = false;

  static void registerUnauthorizedHandler(void Function() handler) {
    _onUnauthorized = handler;
  }

  static void resetUnauthorizedGuard() {
    _handlingUnauthorized = false;
  }

  static Future<void> _handleUnauthorized() async {
    if (_handlingUnauthorized) {
      debugPrint('🔐 401 received — logout already in progress, skipping.');
      return;
    }
    _handlingUnauthorized = true;
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
            debugPrint(
              '⚠️  [${options.method}] ${options.uri} — '
              'no access_token in storage; Authorization header NOT attached.',
            );
          }

          debugPrint(
            '📤 [${options.method}] ${options.uri}'
            '  params=${options.queryParameters}'
            '  body=${options.data is FormData ? "<FormData>" : options.data}'
            '  auth=${options.headers.containsKey("Authorization") ? "✓ Bearer" : "✗ MISSING"}',
          );
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('✅ [${response.statusCode}] ${response.requestOptions.uri}');
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

          debugPrint('❌ API Error on ${error.requestOptions.uri}\n  $readable');

          if (status == 401) {
            debugPrint(
              '🔐 401 Unauthorized — clearing stored credentials and '
              'notifying app to redirect to login.',
            );
            await _handleUnauthorized();
          }

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
  // ROLE HELPERS
  // ─────────────────────────────────────────────

  static Future<void> saveRole(String role) async {
    await _storage.write(key: 'user_role', value: role.toLowerCase());
  }

  static Future<String?> getRole() async {
    return await _storage.read(key: 'user_role');
  }

  static Future<void> clearRole() async {
    await _storage.delete(key: 'user_role');
  }

  // ─────────────────────────────────────────────
  // USER PROFILE HELPERS
  // ─────────────────────────────────────────────

  static Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    await _storage.write(key: 'user_profile', value: jsonEncode(profile));
  }

  static Future<Map<String, dynamic>?> getUserProfile() async {
    final raw = await _storage.read(key: 'user_profile');
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

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

  static Future<void> logout() async {
    try {
      await _dio.post('/api/v1/auth/logout');
    } catch (_) {}
    await clearToken();
    await clearRole();
    await clearUserProfile();
  }

  /// Changes the authenticated user's password.
  /// Backend: POST /api/v1/auth/change-password
  ///
  /// FIX: the backend's request schema requires THREE fields —
  ///   current_password, new_password, confirm_new_password
  /// Previously this sent old_password/new_password only, which the
  /// backend rejected with HTTP 422:
  ///   "current_password: Field required"
  ///   "confirm_new_password: Field required"
  static Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _dio.post(
      '/api/v1/auth/change-password',
      data: {
        'current_password': oldPassword,
        'new_password': newPassword,
        'confirm_new_password': newPassword,
      },
    );
  }

  // ─────────────────────────────────────────────
  // PATIENTS
  // ─────────────────────────────────────────────

  static Future<List<dynamic>> getPatients({
    String search = '',
    int? doctorId,
    int skip = 0,
    int limit = _pageSize,
  }) async {
    final Map<String, dynamic> queryParams = {'skip': skip, 'limit': limit};
    if (search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (doctorId != null && doctorId > 0) {
      queryParams['doctor_id'] = doctorId;
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

  static Future<Map<String, dynamic>> getPatientById(int id) async {
    final response = await _dio.get('/api/v1/clinic/patients/$id');
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
    int skip = 0,
    int limit = _pageSize,
  }) async {
    final Map<String, dynamic> queryParams = {'skip': skip, 'limit': limit};

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

  static Future<Map<String, dynamic>> updateAppointmentType(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch(
      '/api/v1/clinic/appointment-types/$id',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createAppointmentType(
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post(
      '/api/v1/clinic/appointment-types',
      data: data,
    );
    return response.data as Map<String, dynamic>;
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
    int skip = 0,
    int limit = _pageLimit,
  }) async {
    final Map<String, dynamic> queryParams = {'skip': skip, 'limit': limit};
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

  static Future<Map<String, dynamic>> updateVisit(
    int visitId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch(
      '/api/v1/clinic/visits/$visitId',
      data: data,
    );
    return response.data as Map<String, dynamic>;
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
    int skip = 0,
    int limit = _pageLimit,
  }) async {
    final Map<String, dynamic> queryParams = {'skip': skip, 'limit': limit};
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

  /// GET /reports/medical-reports/{id} — fetches a single report's current
  /// state. Used to re-verify the true server-side status after a finalize
  /// call errors out client-side (e.g. a timeout), since the backend may
  /// have completed the request despite the client never seeing the response.
  static Future<Map<String, dynamic>> getMedicalReportById(int id) async {
    final response = await _dio.get('/api/v1/reports/medical-reports/$id');
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

  /// Finalizes a medical report: auto-steps REVIEWED → APPROVED → FINALIZED,
  /// generates a branded PDF, and triggers WhatsApp delivery to patient + doctor.
  /// The report must be in REVIEWED status before calling this — call
  /// [updateReportStatus] with 'REVIEWED' first if the report is still DRAFT.
  ///
  /// Per the API guide:
  ///  - PDF generation and WhatsApp delivery are fire-and-forget (non-fatal).
  ///  - The report will be FINALIZED even if WhatsApp fails.
  ///  - The response does NOT contain the PDF URL — only the audit log does.
  static Future<Map<String, dynamic>> finalizeReport(int reportId) async {
    debugPrint(
      '📋 finalizeReport: POST /api/v1/reports/medical-reports/$reportId/finalize',
    );
    final response = await _dio.post(
      '/api/v1/reports/medical-reports/$reportId/finalize',
      // PDF generation + a live WhatsApp send happen synchronously inside
      // this request, so it legitimately needs more headroom than the
      // app-wide default — a premature client timeout here is what causes
      // doctors to retry a request the backend was still completing.
      options: Options(receiveTimeout: const Duration(seconds: 120)),
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<void> deleteMedicalReport(int id) async {
    await _dio.delete('/api/v1/reports/medical-reports/$id');
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
    CancelToken? cancelToken,
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
      cancelToken: cancelToken,
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getVisitImages(
    int visitId, {
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      '/api/v1/reports/visits/$visitId/medical-images',
      cancelToken: cancelToken,
    );
    return _asList(response.data);
  }

  /// Fetch a single medical image record by its ID.
  static Future<Map<String, dynamic>> getMedicalImageById(int id) async {
    final response = await _dio.get('/api/v1/reports/medical-images/$id');
    return response.data as Map<String, dynamic>;
  }

  /// Confirm (approve) a medical image report after doctor review.
  /// [reportFields] contains only the fields the doctor modified.
  /// Pass an empty map {} when no changes were made.
  /// Uses PATCH .../review — never use this for doctor_notes updates.
  static Future<Map<String, dynamic>> reviewMedicalImage(
    int id,
    Map<String, dynamic> reportFields,
  ) async {
    final response = await _dio.patch(
      '/api/v1/reports/medical-images/$id/review',
      data: reportFields,
    );
    return response.data as Map<String, dynamic>;
  }

  /// Update doctor notes on a medical image record.
  /// Only touches doctor_notes — never affects ai_report, ai_report_raw, or is_confirmed.
  static Future<Map<String, dynamic>> updateMedicalImageNotes(
    int id,
    String doctorNotes,
  ) async {
    final response = await _dio.patch(
      '/api/v1/reports/medical-images/$id',
      data: {'doctor_notes': doctorNotes},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Fetch all medical images for a patient across all their visits.
  static Future<List<dynamic>> getPatientImages(int patientId) async {
    final response = await _dio.get(
      '/api/v1/reports/medical-images',
      queryParameters: {
        'patient_id': patientId,
        'skip': 0,
        'limit': _pageLimit,
      },
    );
    return _asList(response.data);
  }

  // ─────────────────────────────────────────────
  // LAB REPORTS
  // ─────────────────────────────────────────────

  static Future<List<dynamic>> getVisitLabReports(int visitId) async {
    final response = await _dio.get(
      '/api/v1/reports/visits/$visitId/lab-reports',
    );
    return _asList(response.data);
  }

  static Future<Map<String, dynamic>> getLabReportById(int id) async {
    final response = await _dio.get('/api/v1/reports/lab-reports/$id');
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> uploadLabReport({
    required File pdfFile,
    required int visitId,
  }) async {
    // test_name is required by the backend's Pydantic schema but is silently
    // dropped (never persisted). Derive a value from the filename so the
    // validator is satisfied without burdening the user with a field whose
    // data gets discarded.
    final rawName = pdfFile.path.split(RegExp(r'[/\\]')).last;
    final testName = rawName
        .replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '')
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .trim();

    final formData = FormData.fromMap({
      'visit_id': visitId.toString(),
      'test_name': testName.isEmpty ? 'Lab Report' : testName,
      'report_file': await MultipartFile.fromFile(
        pdfFile.path,
        filename: rawName,
      ),
    });

    debugPrint(
      '📋 Lab report FormData — '
      'fields: ${formData.fields.map((e) => '${e.key}=${e.value}').join(', ')}, '
      'files: ${formData.files.map((e) => e.key).toList()}',
    );

    final response = await _dio.post(
      '/api/v1/reports/lab-reports',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateLabReport(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch(
      '/api/v1/reports/lab-reports/$id',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  // ─────────────────────────────────────────────
  // PATIENT VITALS
  // ─────────────────────────────────────────────

  static Future<List<dynamic>> getPatientVitals({
    int? appointmentId,
    int? patientId,
    int? visitId,
  }) async {
    final Map<String, dynamic> queryParams = {'skip': 0, 'limit': _pageLimit};
    if (appointmentId != null && appointmentId > 0) {
      queryParams['appointment_id'] = appointmentId;
    }
    if (patientId != null && patientId > 0) {
      queryParams['patient_id'] = patientId;
    }
    if (visitId != null && visitId > 0) {
      queryParams['visit_id'] = visitId;
    }

    final response = await _dio.get(
      '/api/v1/clinic/patient-vitals',
      queryParameters: queryParams,
    );
    return _asList(response.data);
  }

  static Future<Map<String, dynamic>> createPatientVitals(
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post(
      '/api/v1/clinic/patient-vitals',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updatePatientVitals(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch(
      '/api/v1/clinic/patient-vitals/$id',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<void> deletePatientVitals(int id) async {
    await _dio.delete('/api/v1/clinic/patient-vitals/$id');
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

  static Future<Map<String, dynamic>> updateDoctor(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch('/api/v1/users/doctors/$id', data: data);
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

  /// Returns the assistant profile record by its profile-table PK.
  /// Prefer this over scanning getAssistants() — it is a direct O(1) lookup
  /// that works regardless of how many assistants exist in the system.
  static Future<Map<String, dynamic>?> getAssistantById(int id) async {
    try {
      final response = await _dio.get('/api/v1/users/assistants/$id');
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        debugPrint('   getAssistantById($id): 404 — record not found');
        return null;
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> updateAssistant(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch(
      '/api/v1/users/assistants/$id',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  // ─────────────────────────────────────────────
  // ADMINS
  // ─────────────────────────────────────────────

  static Future<List<dynamic>> getAdmins() async {
    final response = await _dio.get(
      '/api/v1/users/admins',
      queryParameters: {'skip': 0, 'limit': _pageLimit},
    );
    return _asList(response.data);
  }

  static Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await _dio.get('/api/v1/admin/dashboard/stats');
    return response.data as Map<String, dynamic>;
  }

  static Future<void> updateUserStatus(int userId, bool isActive) async {
    await _dio.patch(
      '/api/v1/users/users/$userId/status',
      data: {'is_active': isActive},
    );
  }

  static Future<List<dynamic>> getAuditLogs({
    int skip = 0,
    int limit = 50,
    String? action,
    String? dateFrom,
    String? dateTo,
  }) async {
    final Map<String, dynamic> queryParams = {'skip': skip, 'limit': limit};
    if (action != null && action.isNotEmpty) queryParams['action'] = action;
    if (dateFrom != null && dateFrom.isNotEmpty) queryParams['date_from'] = dateFrom;
    if (dateTo != null && dateTo.isNotEmpty) queryParams['date_to'] = dateTo;
    final response = await _dio.get(
      '/api/v1/reports/audit-logs',
      queryParameters: queryParams,
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
      const vitalsKeys = ['vitals', 'patient_vitals'];
      for (final key in [...knownKeys, ...vitalsKeys]) {
        if (data.containsKey(key) && data[key] is List) {
          return data[key] as List<dynamic>;
        }
      }

      for (final value in data.values) {
        if (value is List) {
          debugPrint(
            '⚠️  _asList: unknown wrapper key — '
            'using first List found. Keys: ${data.keys.toList()}',
          );
          return value;
        }
      }
      debugPrint(
        '⚠️  _asList: response was a Map but no List value found. '
        'Keys: ${data.keys.toList()} | Raw: $data',
      );
    }

    if (data != null) {
      debugPrint('⚠️  _asList: unexpected data type ${data.runtimeType}: $data');
    }

    return [];
  }

  /// Returns a user-friendly error message suitable for display to users.
  /// Delegates to [ErrorHandler] for consistent classification across the app.
  static String extractError(Object e) => ErrorHandler.friendlyMessage(e);
}
