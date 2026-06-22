// ─────────────────────────────────────────────────────────────────────────────
// lib/services/AI_Service.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class AIService {
  static const String _transcribeUrl =
      'https://ai-api.hakim-app.cloud/transcribe-report';

  static const String _imagingUrl =
      'https://ai-api.hakim-app.cloud/analyze-medical-image';

  static const String _apiKey =
      '66ba4126aa3b9f227adde3d1e8e143ad0076ad0fdaf861501051eabec00ccc0b';

  static Map<String, String> get _headers => {
    'X-API-KEY': _apiKey,
    'Authorization': 'Bearer $_apiKey',
  };

  // ── Transcribe audio report ──────────────────────────────────────────────

  static Future<Map<String, dynamic>> transcribeReport(File audioFile) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_transcribeUrl))
        ..headers.addAll(_headers)
        ..files.add(await http.MultipartFile.fromPath('file', audioFile.path));

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode != 200) {
        throw Exception('API Error ${streamed.statusCode}: $body');
      }

      return Map<String, dynamic>.from(jsonDecode(body) as Map);
    } catch (e) {
      throw Exception('Transcribe report failed: $e');
    }
  }

  // ── Pick image from camera / gallery ────────────────────────────────────

  static Future<File?> pickImage({required ImageSource source}) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return picked == null ? null : File(picked.path);
    } catch (e) {
      print('pickImage error: $e');
      return null;
    }
  }

  // ── Analyse a medical image ──────────────────────────────────────────────
  //
  // FIX: Previously this method manually filtered the AI response down to
  // only 5 keys (findings, severity, confidence, recommendations,
  // detected_conditions), silently discarding imageType, region, quality,
  // impressions, and differentials — the exact fields the consultation page
  // needs to build the structured display.
  //
  // Now the method returns the COMPLETE raw AI response so callers have full
  // access to every field.  The only addition is a top-level 'error' key
  // (null on success, error string on failure) so callers can do a single
  // null-check instead of catching exceptions.

  static Future<Map<String, dynamic>> scanMedicalImage(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        return {'error': 'Image file does not exist at ${imageFile.path}'};
      }

      final request = http.MultipartRequest('POST', Uri.parse(_imagingUrl))
        ..headers.addAll(_headers)
        ..files.add(
          await http.MultipartFile.fromPath(
            'image',
            imageFile.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode != 200) {
        return {'error': 'API Error ${streamed.statusCode}: $body'};
      }

      // ── Return the full response, just annotate success with error = null ──
      final decoded = Map<String, dynamic>.from(jsonDecode(body) as Map);
      return {...decoded, 'error': null};
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
