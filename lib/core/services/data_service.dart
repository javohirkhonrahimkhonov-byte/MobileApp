import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import 'auth_service.dart';
import '../models/attendance.dart';
import '../models/lesson.dart';

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
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      return body['data'] ?? body;
    }
    throw Exception('Failed to load profile');
  }

  // Cache for Dashboard
  Map<String, dynamic>? _dashboardCache;
  DateTime? _lastDashboardFetch;

  // 2. Get Dashboard Stats (Direct HEMIS Fetch to bypass Server Block)
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
      final token = headers['Authorization']?.replaceFirst('Bearer ', '') ?? '';

      // Check for Legacy/Mock Token
      if (token.startsWith('student_id_') || token.startsWith('jwt_token_')) {
        print("Legacy Token Detected. Skipping Real Fetch.");
        throw Exception("Legacy Token");
      }
      
      // A. Calculate GPA (Direct from HEMIS)
      final performanceUri = Uri.parse('${ApiConstants.baseUrl}/education/performance'); 
      double gpa = 0.0;
      
      try {
        final perfResponse = await http.get(performanceUri, headers: headers).timeout(const Duration(seconds: 10));
        if (perfResponse.statusCode == 200) {
           final data = json.decode(perfResponse.body);
           final items = data['data'] is List ? data['data'] : [];
           if (items.isNotEmpty) {
             double total = 0;
             int count = 0;
             for (var item in items) {
               if (item['grade'] != null) {
                 final g = double.tryParse(item['grade'].toString());
                 if (g != null) {
                   total += g;
                   count++;
                 }
               }
             }
             if (count > 0) gpa = total / count;
           }
        }
      } catch (e) {
        print("GPA local calc error: $e");
      }

      // B. Calculate Absence (Direct from HEMIS)
      final attendanceUri = Uri.parse('${ApiConstants.baseUrl}/education/attendance');
      int missedHours = 0;
      int missedExcused = 0;
      int missedUnexcused = 0;
      
      try {
        final attResponse = await http.get(attendanceUri, headers: headers).timeout(const Duration(seconds: 10));
        if (attResponse.statusCode == 200) {
          final data = json.decode(attResponse.body);
          final items = data['data'] is List ? data['data'] : (data['data']['items'] ?? []);
          
          for (var item in items) {
             final int hour = int.tryParse(item['hour'].toString()) ?? 2;
             // Logic: 11 = Sababli, 12 = Sababsiz. Or check "is_valid"
             final statusId = item['absent_status'];
             final bool isValid = item['is_valid'] == true;
             
             if (statusId == 11 || isValid) {
               missedExcused += hour;
             } else {
               missedUnexcused += hour;
             }
          }
          missedHours = missedExcused + missedUnexcused;
        }
      } catch (e) {
        print("Absence local calc error: $e");
      }

      final result = {
        "gpa": double.parse(gpa.toStringAsFixed(2)),
        "missed_hours": missedHours,
        "missed_hours_excused": missedExcused,
        "missed_hours_unexcused": missedUnexcused,
        "activities_count": 0,
        "clubs_count": 0
      };

      // Update Cache
      _dashboardCache = result;
      _lastDashboardFetch = DateTime.now();

      return result;
    } catch (e) {
      print("Dashboard Error: $e");
      
      // Fallback: Return Zeros if error
      return {
        "gpa": 0.0,
        "missed_hours": 0,
        "missed_hours_excused": 0, 
        "missed_hours_unexcused": 0,
        "activities_count": 0,
        "clubs_count": 0
      };
      
      return {
        "gpa": 0.0,
        "missed_hours": 0,
        "missed_hours_excused": 0, 
        "missed_hours_unexcused": 0,
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
    // Attempt to fetch from backend
    try {
      print("DataService: Fetching activities...");
      final response = await http.get(
        Uri.parse(ApiConstants.activities), 
        headers: await _getHeaders()
      ).timeout(const Duration(seconds: 10));
      
      print("DataService: Activities response: ${response.statusCode}");
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint("DataService API error: $e");
    }
    
    // Fallback or empty if offline
    if (useMock) {
       // ... existing mock data logic if desired, or return empty
    }
    return [];
  }

  Future<void> addActivity(String category, String name, String description, String date, {List<String>? imagePaths}) async {
    final token = await _authService.getToken();
    var request = http.MultipartRequest('POST', Uri.parse(ApiConstants.activities));
    request.headers['Authorization'] = 'Bearer $token';
    
    request.fields['category'] = category;
    request.fields['name'] = name;
    request.fields['description'] = description;
    request.fields['date'] = date;
    
    if (imagePaths != null && imagePaths.isNotEmpty) {
      for (var path in imagePaths) {
         request.files.add(await http.MultipartFile.fromPath('files', path));
      }
    }
    
    final response = await request.send();
    
    if (response.statusCode != 200) {
      // Consume response to debug
      final respStr = await response.stream.bytesToString();
      debugPrint("Add Activity Failed: ${response.statusCode} - $respStr");
      throw Exception('Failed to add activity: ${response.statusCode}');
    }
  }

  // 4. Get Clubs
  Future<List<dynamic>> getMyClubs() async {
     if (useMock) return [];
     return [];
  }

  // 5. Get Feedback
  Future<List<dynamic>> getMyFeedback() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.feedback),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return json.decode(response.body);
    } catch (e) {
      debugPrint("Feedback Load Error: $e");
    }
    return [];
  }

  // 6. Send Feedback (Multipart)
  Future<bool> sendFeedback(String text, String role, String? filePath, {bool isAnonymous = false}) async {
    try {
      final token = await _authService.getToken();
      var request = http.MultipartRequest('POST', Uri.parse(ApiConstants.feedback));
      
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      request.fields['text'] = text;
      request.fields['role'] = role;
      request.fields['is_anonymous'] = isAnonymous.toString();

      if (filePath != null) {
        request.files.add(await http.MultipartFile.fromPath('file', filePath));
      }

      var response = await request.send().timeout(const Duration(seconds: 30));
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("Feedback Send Error: $e");
      return false;
    }
  }

  // 6.5 Get Feedback Detail (Chat)
  Future<Map<String, dynamic>?> getFeedbackDetail(int id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.feedback}$id'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint("Feedback Detail Error: $e");
    }
    return null;
  }

  // 6.6 Reply to Feedback
  Future<void> replyToFeedback(int id, String text) async {
    final token = await _authService.getToken();
    final response = await http.post(
      Uri.parse('${ApiConstants.feedback}$id/reply'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {'text': text},
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Failed to reply');
    }
  }


  // 7. Get Documents
  Future<List<dynamic>> getMyDocuments() async {
    final response = await http.get(
      Uri.parse(ApiConstants.documents),
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load documents');
  }

  // 9. Get Detailed Attendance List
  // 9. Get Detailed Attendance List
  Future<List<Attendance>> getAttendanceList() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.attendanceList),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        // Robust parsing: 'data' can be a List OR a Map with 'items'
        final data = body['data'];
        final List<dynamic> items = (data is List) ? data : (data['items'] ?? []);
        
        return items.map((json) => Attendance.fromJson(json)).toList();
      } else {
        throw Exception("Failed to load attendance: ${response.statusCode}");
      }
    } catch (e) {
       print("DataService: Error fetching attendance: $e");
       return [];
    }
  }

  // 11. Get Weekly Schedule
  Future<List<Lesson>> getSchedule() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.scheduleList),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final data = body['data'];
        final List<dynamic> items = (data is List) ? data : (data['items'] ?? []);
        return items.map((json) => Lesson.fromJson(json)).toList();
      } else {
        throw Exception("Failed to load schedule: ${response.statusCode}");
      }
    } catch (e) {
      print("DataService: Error fetching schedule: $e");
      if (useMock) {
        return [];
      }
      return [];
    }
  }

  // 10. Request Document (Already Exists above)
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

