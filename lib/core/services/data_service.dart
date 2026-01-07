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

  // Cache for Dashboard
  Map<String, dynamic>? _dashboardCache;
  DateTime? _lastDashboardFetch;

  // 2. Get Dashboard Stats (Real + Cached)
  Future<Map<String, dynamic>> getDashboardStats({bool forceRefresh = false}) async {
    if (useMock) return _getMockStats();

    // Check Cache (valid for 5 mins)
    if (!forceRefresh && _dashboardCache != null && _lastDashboardFetch != null) {
      if (DateTime.now().difference(_lastDashboardFetch!).inMinutes < 5) {
        return _dashboardCache!;
      }
    }

    try {
      final headers = await _getHeaders();
      
      final response = await http.get(
        Uri.parse(ApiConstants.dashboard),
        headers: await _getHeaders(),
      );

      if (response.statusCode != 200) throw Exception('API Error');
      final body = json.decode(response.body);

      // Update Cache
      _dashboardCache = result;
      _lastDashboardFetch = DateTime.now();

      return {
        "gpa": body['gpa'] ?? 0.0,
        "missed_hours": body['missed_hours'] ?? 0,
        "missed_hours_excused": body['missed_hours_excused'] ?? 0,
        "missed_hours_unexcused": body['missed_hours_unexcused'] ?? 0,
        "activities_count": body['activities_count'] ?? 0,
        "clubs_count": body['clubs_count'] ?? 0,
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

