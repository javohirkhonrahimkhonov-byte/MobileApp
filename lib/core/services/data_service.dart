import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'auth_service.dart';

class DataService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // 1. Get Profile
  Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse(ApiConstants.profile),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load profile');
  }

  // 2. Get Dashboard Stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await http.get(
      Uri.parse(ApiConstants.dashboard),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load dashboard');
  }

  // 3. Get Activities
  Future<List<dynamic>> getActivities() async {
    final response = await http.get(
      Uri.parse(ApiConstants.activities),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load activities');
  }

  // 4. Get Clubs
  Future<List<dynamic>> getMyClubs() async {
    final response = await http.get(
      Uri.parse(ApiConstants.clubsMy),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load clubs');
  }

  // 5. Get Feedback
  Future<List<dynamic>> getMyFeedback() async {
    final response = await http.get(
      Uri.parse(ApiConstants.feedback),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load feedback');
  }

  // 6. Send Feedback (Multipart)
  Future<void> sendFeedback(String text, String role, String? filePath) async {
    final token = await _authService.getToken();
    var request = http.MultipartRequest('POST', Uri.parse(ApiConstants.feedback));
    
    request.headers.addAll({
      'Authorization': 'Bearer $token',
    });

    request.fields['text'] = text;
    request.fields['role'] = role;

    if (filePath != null) {
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
    }

    var response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('Failed to send feedback');
    }
  }

  // 7. Get Documents
  Future<List<dynamic>> getMyDocuments() async {
    final response = await http.get(
      Uri.parse(ApiConstants.documents),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load documents');
  }

  // 8. Request Document
  Future<void> requestDocument(String type, String description) async {
    final response = await http.post(
      Uri.parse(ApiConstants.documents),
      headers: await _getHeaders(),
      body: json.encode({
        // Note: API expects Form data normally, but standard HTTP post often sends JSON.
        // Let's check api/documents.py again. It uses Form(...). 
        // So we must use form-urlencoded or multipart.
        // Simple body maps in http package for POST are x-www-form-urlencoded by default if body is map.
      }), 
    );
    
    // Correct way for Form Data
    final token = await _authService.getToken();
    final formResponse = await http.post(
      Uri.parse(ApiConstants.documents),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'type': type,
        'description': description,
      },
    );

    if (formResponse.statusCode != 200) {
      throw Exception('Failed to request document');
    }
  }
}

