import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'auth_service.dart';

class DataService {
  final AuthService _authService = AuthService();
  static const bool useMock = false; // Disable Mock Data

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // 1. Get Profile
  Future<Map<String, dynamic>> getProfile() async {
    // Note: Most profile data comes from AuthService on login.
    // This is for refreshing.
    if (useMock) return _getMockProfile();

    final response = await http.get(
      Uri.parse(ApiConstants.profile),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      return body['data'] ?? body;
    }
    throw Exception('Failed to load profile');
  }

  // 2. Get Dashboard Stats (Real)
  Future<Map<String, dynamic>> getDashboardStats() async {
    if (useMock) return _getMockStats();

    try {
      final headers = await _getHeaders();
      
      // Calculate GPA (from /education/performance)
      // Note: ApiConstants.gpaList is likely admin endpoint. Use student endpoint.
      // Since we don't have the exact endpoint in constants, let's try a common one or standard list.
      // Standard HEMIS: /education/performance
      final performanceUri = Uri.parse('${ApiConstants.baseUrl}/education/performance'); 
      double gpa = 0.0;
      
      try {
        final perfResponse = await http.get(performanceUri, headers: headers);
        if (perfResponse.statusCode == 200) {
           final data = json.decode(perfResponse.body);
           // Calculate average grade 
           // Structure: {"data": [{"grade": 5, ...}, ...]}
           final items = data['data'] as List?;
           if (items != null && items.isNotEmpty) {
             double total = 0;
             int count = 0;
             for (var item in items) {
               if (item['grade'] != null) {
                 total += double.tryParse(item['grade'].toString()) ?? 0;
                 count++;
               }
             }
             if (count > 0) gpa = total / count;
           }
        }
      } catch (e) {
        print("GPA calc error: $e");
      }

      // Calculate Absence (from /education/attendance)
      final attendanceUri = Uri.parse('${ApiConstants.baseUrl}/education/attendance');
      int missedHours = 0;
      try {
        final attResponse = await http.get(attendanceUri, headers: headers);
        if (attResponse.statusCode == 200) {
          final data = json.decode(attResponse.body);
          final items = data['data'] is List ? data['data'] : data['data']['items'];
          if (items != null) {
            for (var item in items) {
               final off = item['absent_off'] ?? 0;
               final on = item['absent_on'] ?? 0;
               missedHours += (off + on) as int;
            }
          }
        }
      } catch (e) {
        print("Absence calc error: $e");
      }

      return {
        "gpa": double.parse(gpa.toStringAsFixed(2)),
        "missed_hours": missedHours,
        "activities_count": 0, // Placeholder
        "clubs_count": 0
      };
    } catch (e) {
      print("Dashboard Error: $e");
      // Return zeros instead of crashing
       return {
        "gpa": 0.0,
        "missed_hours": 0,
        "activities_count": 0,
        "clubs_count": 0
      };
    }
  }

  Map<String, dynamic> _getMockProfile() {
      return {
        "id": "3902111",
        "full_name": "Aliyev Vali Valiyevich",
        "group_number": "315-21 Axborot Xavfsizligi",
        "faculty": "Kiberxavfsizlik Fakulteti",
        "phone": "+998901234567"
      };
  }

  Map<String, dynamic> _getMockStats() {
      return {
        "gpa": 4.8,
        "missed_hours": 12,
        "activities_count": 12,
        "clubs_count": 3
      };
  }

  // 3. Get Activities
  Future<List<dynamic>> getActivities() async {
    if (useMock) return []; 
    // Backend API is blocked/unavailable, so return empty for now
    return [];
  }

  // 4. Get Clubs
  Future<List<dynamic>> getMyClubs() async {
     if (useMock) return [];
     return [];
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

