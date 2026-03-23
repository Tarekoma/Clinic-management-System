import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class AIService {
  // ✅ Production Endpoint
  static const String baseUrl =
      "https://ai-api.hakim-app.cloud/transcribe-report";

  // ✅ Image Analysis Endpoint
  static const String imageAnalysisUrl =
      "https://ai-api.hakim-app.cloud/analyze-medical-image";

  // ✅ Backend API Key
  static const String apiKey = "hakim-backend-key1-2026";

  /// Upload audio file → Receive structured medical report JSON
  static Future<Map<String, dynamic>> transcribeReport(File audioFile) async {
    try {
      // ✅ Build Request
      var request = http.MultipartRequest("POST", Uri.parse(baseUrl));

      // ✅ Add API Key Header
      request.headers["X-API-KEY"] = apiKey;

      // ✅ Attach Audio File
      request.files.add(
        await http.MultipartFile.fromPath("file", audioFile.path),
      );

      // ✅ Send Request
      final streamedResponse = await request.send();

      // ✅ Read Full Response Body
      final responseBody = await streamedResponse.stream.bytesToString();

      // Debug log (optional)
      print("STATUS CODE: ${streamedResponse.statusCode}");
      print("RESPONSE BODY: $responseBody");

      // ✅ Handle Errors
      if (streamedResponse.statusCode != 200) {
        throw Exception(
          "API Error: ${streamedResponse.statusCode}\n$responseBody",
        );
      }

      // ✅ Parse JSON Response
      final decoded = jsonDecode(responseBody);

      return decoded;
    } catch (e) {
      throw Exception("Transcribe Report Failed: $e");
    }
  }

  /// Pick image from gallery or camera
  static Future<File?> pickImage({required ImageSource source}) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  /// Upload image file → Receive AI medical analysis JSON
  static Future<Map<String, dynamic>> scanMedicalImage(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        throw Exception("Image file does not exist");
      }

      var request = http.MultipartRequest("POST", Uri.parse(imageAnalysisUrl));
      request.headers["X-API-KEY"] = apiKey;

      request.files.add(
        await http.MultipartFile.fromPath(
          "image",
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode != 200) {
        return {
          'error': 'API Error: ${streamedResponse.statusCode}',
          'findings': null,
          'severity': null,
          'confidence': null,
        };
      }

      final decoded = jsonDecode(responseBody);
      return {
        'findings': decoded['findings'] ?? 'No findings',
        'severity': decoded['severity'] ?? 'Unknown',
        'confidence': decoded['confidence'] ?? 0.0,
        'recommendations': decoded['recommendations'] ?? [],
        'detected_conditions': decoded['detected_conditions'] ?? [],
        'error': null,
      };
    } catch (e) {
      print("Image analysis failed: $e");
      return {
        'error': e.toString(),
        'findings': null,
        'severity': null,
        'confidence': null,
      };
    }
  }
}
