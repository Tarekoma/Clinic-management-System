import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Central API service — all backend calls go through here.
class ApiService {
  static const String _baseUrl = 'https://backend.hakim-app.cloud';
  static const String _apiKey =
      '66ba4126aa3b9f227adde3d1e8e143ad0076ad0fdaf861501051eabec00ccc0b';

  static final _storage = const FlutterSecureStorage();
  static late Dio _dio;

  /// Call this once in main() before runApp()
  static void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Content-Type': 'application/json', 'X-API-KEY': _apiKey},
      ),
    );

    // Attach token to every request automatically
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          return handler.next(error);
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
  }

  // ─────────────────────────────────────────────
  // PATIENTS
  // ─────────────────────────────────────────────

  /// ✅ FIX: Added doctorId parameter to filter patients by doctor
  static Future<List<dynamic>> getPatients({
    String search = '',
    int? doctorId,
  }) async {
    final queryParams = {
      'search': search,
      'skip': 0,
      'limit': 200,
      if (doctorId != null) 'doctor_id': doctorId,
    };

    final response = await _dio.get(
      '/api/v1/clinic/patients',
      queryParameters: queryParams,
    );
    return response.data as List<dynamic>;
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
    return response.data as List<dynamic>;
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
    final response = await _dio.get(
      '/api/v1/clinic/appointments',
      queryParameters: {
        if (doctorId != null) 'doctor_id': doctorId,
        if (patientId != null) 'patient_id': patientId,
        if (status != null) 'status': status,
        'skip': 0,
        'limit': 200,
      },
    );
    return response.data as List<dynamic>;
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
      data: {'status': status},
    );
  }

  static Future<void> deleteAppointment(int id) async {
    await _dio.delete('/api/v1/clinic/appointments/$id');
  }

  // ─────────────────────────────────────────────
  // APPOINTMENT TYPES
  // ─────────────────────────────────────────────

  static Future<List<dynamic>> getAppointmentTypes({int? doctorId}) async {
    final response = await _dio.get(
      '/api/v1/clinic/appointment-types',
      queryParameters: {if (doctorId != null) 'doctor_id': doctorId},
    );
    return response.data as List<dynamic>;
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
    final response = await _dio.get(
      '/api/v1/clinic/visits',
      queryParameters: {
        if (doctorId != null) 'doctor_id': doctorId,
        if (patientId != null) 'patient_id': patientId,
        if (status != null) 'status': status,
        'skip': 0,
        'limit': 200,
      },
    );
    return response.data as List<dynamic>;
  }

  static Future<void> updateVisitStatus(int visitId, String status) async {
    await _dio.patch(
      '/api/v1/clinic/visits/$visitId/status',
      data: {'status': status},
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
    final response = await _dio.get(
      '/api/v1/reports/medical-reports',
      queryParameters: {
        if (patientId != null) 'patient_id': patientId,
        if (doctorId != null) 'doctor_id': doctorId,
        if (visitId != null) 'visit_id': visitId,
        'skip': 0,
        'limit': 200,
      },
    );
    return response.data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createMedicalReport(
    Map<String, dynamic> data,
  ) async {
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
    return response.data as List<dynamic>;
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
      queryParameters: {'skip': 0, 'limit': 100},
    );
    return response.data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getDoctorById(int id) async {
    final response = await _dio.get('/api/v1/users/doctors/$id');
    return response.data as Map<String, dynamic>;
  }

  // ─────────────────────────────────────────────
  // ASSISTANTS  ← NEW
  // ─────────────────────────────────────────────

  static Future<List<dynamic>> getAssistants() async {
    final response = await _dio.get(
      '/api/v1/users/assistants',
      queryParameters: {'skip': 0, 'limit': 100},
    );
    return response.data as List<dynamic>;
  }
}
