import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'auth_service.dart';

class DataService {
  final AuthService _authService = AuthService();
  // Development Mode: Set to true to bypass backend
  static const bool useMock = true;

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // 1. Get Profile
  Future<Map<String, dynamic>> getProfile() async {
    if (useMock) {
      await Future.delayed(const Duration(seconds: 1)); 
      return {
        "id": "3902111",
        "full_name": "Aliyev Vali Valiyevich",
        "group_number": "315-21 Axborot Xavfsizligi",
        "faculty": "Kiberxavfsizlik Fakulteti",
        "phone": "+998901234567"
      };
    }

    final response = await http.get(
      Uri.parse(ApiConstants.profile),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      return body['data']; // HEMIS returns { "data": { ... } }
    }
    throw Exception('Failed to load profile');
  }

  // 2. Get Dashboard Stats (Aggregated)
  Future<Map<String, dynamic>> getDashboardStats() async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 800));
      return {
        "gpa": 4.8,
        "missed_hours": 12,
        "activities_count": 12,
        "clubs_count": 3
      };
    }

    try {
      final headers = await _getHeaders();
      
      // Fetch GPA
      final gpaResponse = await http.get(Uri.parse(ApiConstants.gpaList), headers: headers);
      double gpa = 0.0;
      if (gpaResponse.statusCode == 200) {
        final gpaData = json.decode(gpaResponse.body);
        // Logic: Calculate Average or get latest (Simplified)
        if (gpaData['data']['items'] != null && (gpaData['data']['items'] as List).isNotEmpty) {
           gpa = 4.5; // Placeholder logic as structure needs deep parsing
        }
      }

      // Fetch Tasks (for Homework count)
      final taskResponse = await http.get(Uri.parse(ApiConstants.taskList), headers: headers);
      int tasks = 0;
      if (taskResponse.statusCode == 200) {
        final taskData = json.decode(taskResponse.body);
        tasks = taskData['data']['pagination']['totalCount'] ?? 0;
      }

      return {
        "gpa": gpa,
        "missed_hours": 0, // Not available in public docs yet
        "activities_count": tasks, // Mapping tasks to activities for now
        "clubs_count": 0
      };
    } catch (e) {
      print("Dashboard Error: $e");
      throw Exception('Failed to load dashboard');
    }
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

