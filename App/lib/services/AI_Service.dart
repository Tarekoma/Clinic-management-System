import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class AIService {
  static const String baseUrl =
      "https://ai-api.hakim-app.cloud/transcribe-report";
  static const String imageAnalysisUrl =
      "https://ai-api.hakim-app.cloud/analyze-medical-image"; // ✅ ADD YOUR IMAGE API ENDPOINT
  static const String apiKey = "hakim-backend-key1-2026";

  // Existing transcribeReport method stays the same...
  static Future<Map<String, dynamic>> transcribeReport(File audioFile) async {
    try {
      if (!await audioFile.exists()) {
        throw Exception("Audio file does not exist");
      }

      var request = http.MultipartRequest("POST", Uri.parse(baseUrl));
      request.headers["X-API-KEY"] = apiKey;

      request.files.add(
        await http.MultipartFile.fromPath(
          "file",
          audioFile.path,
          contentType: MediaType('audio', 'mp4'),
        ),
      );

      print("Uploading file: ${audioFile.path}");
      print("File size: ${await audioFile.length()} bytes");

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      print("STATUS CODE: ${streamedResponse.statusCode}");
      print("RESPONSE BODY: $responseBody");

      if (streamedResponse.statusCode != 200) {
        throw Exception(
          "API Error: ${streamedResponse.statusCode}\n$responseBody",
        );
      }

      final decoded = jsonDecode(responseBody);
      return decoded;
    } catch (e) {
      throw Exception("Transcribe Report Failed: $e");
    }
  }

  // ✅ NEW: Pick image from gallery or camera
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

  // ✅ NEW: Scan medical image with AI
  static Future<Map<String, dynamic>> scanMedicalImage(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        throw Exception("Image file does not exist");
      }

      var request = http.MultipartRequest("POST", Uri.parse(imageAnalysisUrl));
      request.headers["X-API-KEY"] = apiKey;

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath(
          "image",
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      print("Uploading image: ${imageFile.path}");
      print("Image size: ${await imageFile.length()} bytes");

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      print("IMAGE ANALYSIS STATUS CODE: ${streamedResponse.statusCode}");
      print("IMAGE ANALYSIS RESPONSE: $responseBody");

      if (streamedResponse.statusCode != 200) {
        return {
          'error': 'API Error: ${streamedResponse.statusCode}',
          'findings': null,
          'severity': null,
          'confidence': null,
        };
      }

      final decoded = jsonDecode(responseBody);

      // Expected response format from your API:
      // {
      //   "findings": "Normal chest X-ray, no abnormalities detected",
      //   "severity": "Low",
      //   "confidence": 0.92,
      //   "recommendations": ["Follow up in 6 months"],
      //   "detected_conditions": []
      // }

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
