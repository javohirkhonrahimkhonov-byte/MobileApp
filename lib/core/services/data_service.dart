import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import 'auth_service.dart';
import '../models/attendance.dart';
import '../models/lesson.dart';
import 'package:talabahamkor_mobile/features/social/models/social_activity.dart';

class DataService {
  final AuthService _authService = AuthService();
  static const bool useMock = false; // Disable Mock Data

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
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

  // 2. Get Dashboard Stats (Via Backend Proxy for Real Data)
  Future<Map<String, dynamic>> getDashboardStats({bool forceRefresh = false}) async {
    // Check Cache (valid for 5 mins)
    if (!forceRefresh && _dashboardCache != null && _lastDashboardFetch != null) {
      if (DateTime.now().difference(_lastDashboardFetch!).inMinutes < 5) {
        return _dashboardCache!;
      }
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConstants.dashboard),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Backend returns top-level fields directly in current Schema
        final result = {
          "gpa": double.tryParse(data['gpa']?.toString() ?? "0") ?? 0.0,
          "missed_hours": data['missed_hours'] ?? 0,
          "missed_hours_excused": data['missed_hours_excused'] ?? 0,
          "missed_hours_unexcused": data['missed_hours_unexcused'] ?? 0,
          "activities_count": data['activities_count'] ?? 0,
          "clubs_count": data['clubs_count'] ?? 0,
          "activities_approved_count": data['activities_approved_count'] ?? 0
        };

        // Update Cache
        _dashboardCache = result;
        _lastDashboardFetch = DateTime.now();
        return result;
      }
    } catch (e) {
      print("Dashboard Error: $e");
    }

    // Fallback: Real 0s (Clean Data Policy)
    return {
      "gpa": 0.0,
      "missed_hours": 0,
      "missed_hours_excused": 0, 
      "missed_hours_unexcused": 0,
      "activities_count": 0,
      "clubs_count": 0
    };
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

  // NEW: Init Upload Session
  Future<void> initUploadSession(String sessionId, String category) async {
    final token = await _authService.getToken();
    final response = await http.post(
      Uri.parse('${ApiConstants.activities}/upload/init'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'session_id': sessionId,
        'category': category
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to init session: ${response.body}');
    }
  }

  // NEW: Check Upload Status
  Future<Map<String, dynamic>> checkUploadStatus(String sessionId) async {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse('${ApiConstants.activities}/upload/status/$sessionId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return {"status": "pending"};
  }

  Future<SocialActivity?> addActivity(String category, String name, String description, String date, {String? sessionId}) async {
    final token = await _authService.getToken();
    var request = http.MultipartRequest('POST', Uri.parse(ApiConstants.activities));
    request.headers['Authorization'] = 'Bearer $token';
    
    request.fields['category'] = category;
    request.fields['name'] = name;
    request.fields['description'] = description;
    request.fields['date'] = date;
    
    if (sessionId != null) {
      request.fields['session_id'] = sessionId;
    }
    
    final response = await request.send();
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final respStr = await response.stream.bytesToString();
      return SocialActivity.fromJson(json.decode(respStr));
    } else {
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
  Future<List<Attendance>> getAttendanceList({String? semester}) async {
    try {
      String url = ApiConstants.attendanceList;
      if (semester != null && semester.isNotEmpty) {
        url += "?semester=$semester";
      }

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        // Robust parsing: 'data' can be a List OR a Map with 'items'
        final data = body is Map && body.containsKey('data') ? body['data'] : body;
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



  // 12. Get Detailed Grades (O'zlashtirish)
  Future<List<dynamic>> getGrades() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.grades),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true) {
           return body['data'];
        }
      } 
      return [];
    } catch (e) {
      print("DataService: Error fetching grades: $e");
      return [];
    }
  }

  // 13. Get Detailed Subjects
  Future<List<dynamic>> getSubjects() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.subjects),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true) return body['data'];
      }
      return [];
    } catch (e) {
      print("DataService: Error fetching subjects: $e");
      return [];
    }
  }

  // 14. Get Subject Resources
  Future<List<dynamic>> getResources(String subjectId) async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConstants.resources}/$subjectId"),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true) return body['data'];
      }
      return [];
    } catch (e) {
      print("DataService: Error fetching resources: $e");
      return [];
    }
  }

  // 15. Send Resource to Bot
  Future<bool> sendResourceToBot(String url, String name) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConstants.resources}/send"),
        headers: await _getHeaders(),
        body: json.encode({"url": url, "name": name})
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        print("Bot Send Response: $body");
        return body['success'] == true;
      }
      return false;
    } catch (e) {
      print("DataService: Error sending resource: $e");
      return false;
    }
  }

  // 16. Get Subject Details
  Future<Map<String, dynamic>?> getSubjectDetails(String subjectId) async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConstants.academic}/subject/$subjectId/details"),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true) {
          return body['data'];
        }
      }
      return null;
    } catch (e) {
      print("DataService: Error fetching subject details: $e");
      return null;
    }
  }

  // 17. Send AI Message
  Future<String?> sendAiMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.aiChat),
        headers: await _getHeaders(),
        body: json.encode({'message': message}),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true) {
           return body['data'];
        }
      }
      return null;
    } catch (e) {
      print("DataService: Error sending AI message: $e");
      return null;
    }
  }

  // 18. Get AI History
  Future<List<dynamic>?> getAiHistory() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.backendUrl}/ai/history'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true) {
           return body['data'];
        }
      }
      return null;
    } catch (e) {
      print("DataService: Error fetching AI history: $e");
      return null;
    }
  }

  // 19. Clear AI History
  Future<bool> clearAiHistory() async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.backendUrl}/ai/history'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("DataService: Error clearing AI history: $e");
      return false;
    }
  }

  // 20. Request Document
  Future<String?> requestDocument(String type) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.documentsSend),
        headers: await _getHeaders(),
        body: json.encode({'type': type}),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true) {
           return body['message'];
        } else {
           return body['message']; // Return error message from server
        }
      }
      return null;
    } catch (e) {
      print("DataService: Error requesting document: $e");
      return null;
    }
  }
  // 21. Summarize Content (Konspekt)
  Future<String?> summarizeContent({String? text, String? filePath}) async {
    try {
      final token = await _authService.getToken();
      
      // Use MultipartRequest for optional file upload
      var request = http.MultipartRequest('POST', Uri.parse('${ApiConstants.backendUrl}/ai/summarize'));
      request.headers['Authorization'] = 'Bearer $token';

      if (text != null && text.isNotEmpty) {
        request.fields['text'] = text;
      }

      if (filePath != null) {
        request.files.add(await http.MultipartFile.fromPath('file', filePath));
      }

      var response = await request.send();
      
      if (response.statusCode == 200) {
         final respStr = await response.stream.bytesToString();
         final body = json.decode(respStr);
         if (body['success'] == true) {
            return body['data'];
         } else {
            return "Xatolik: ${body['message']}";
         }
      } else {
         return "Server xatosi: ${response.statusCode}";
      }
    } catch (e) {
      print("DataService: Error summarizing content: $e");
      return "Tarmoq xatosi yoki fayl muammosi.";
    }
  }
  // 22. Upload Profile Image
  Future<String?> uploadProfileImage(String filePath) async {
    try {
      final token = await _authService.getToken();
      
      var request = http.MultipartRequest('POST', Uri.parse('${ApiConstants.backendUrl}/student/image'));
      request.headers['Authorization'] = 'Bearer $token';
      
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      
      final response = await request.send();
      
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final body = json.decode(respStr);
        if (body['success'] == true) {
          return body['data']['image_url'];
        }
      }
      return null;
    } catch (e) {
      print("Error uploading profile image: $e");
      return null;
    }
  }
}

