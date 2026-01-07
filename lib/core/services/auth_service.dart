import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student.dart';
import '../constants/api_constants.dart';

class AuthService {
  
  // Using DIRECT HEMIS API because Proxy Server is Geo-Blocked
  Future<Student?> login(String login, String password) async {
    // 0. DEMO MODE (Bypass Network Block)
    if (login == 'demo' && password == '123') {
      print("Logging in with DEMO user");
      const fakeToken = "student_id_99999"; 
      await _saveToken(fakeToken);
      
      final demoStudent = Student(
        id: 99999,
        fullName: "Demo Talaba",
        hemisLogin: "3902111", // Mapped from hemisId
        groupNumber: "315-21 AX",
        facultyName: "Kiberxavfsizlik",
        universityName: "Toshkent Axborot Texnologiyalari Universiteti",
        // levelName, educationForm, studentStatus, hemisToken are not in Student model
        // We just need the basics for the UI
      );
      
      await _saveProfile(demoStudent.toJson());
      return demoStudent;
    }

    final url = Uri.parse(ApiConstants.authLogin);
    try {
      print('Direct Login: $url');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        },
        body: jsonEncode({'login': login, 'password': password}),
      ).timeout(const Duration(seconds: 15));

      print('Login Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        
        // HEMIS API: {"success": true, "data": {"token": "..."}}
        String? token;
        if (body['data'] != null && body['data']['token'] != null) {
          token = body['data']['token'];
        }

        if (token != null) {
          await _saveToken(token);
          return await _fetchAndSaveProfile(token);
        }
      } else {
        throw Exception('Login Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Auth Error: $e');
      rethrow;
    }
    return null;
  }

  Future<Student?> _fetchAndSaveProfile(String token) async {
    try {
      final url = Uri.parse(ApiConstants.profile);
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final profileData = body['data'] ?? body;
        
        await _saveProfile(profileData);
        return Student.fromJson(profileData);
      }
    } catch (e) {
      print('Profile Error: $e');
    }
    return null;
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> _saveProfile(Map<String, dynamic> profile) async {
     final prefs = await SharedPreferences.getInstance();
     await prefs.setString('user_profile', jsonEncode(profile));
  }
  
  Future<Student?> getSavedUser() async {
     final prefs = await SharedPreferences.getInstance();
     final profileStr = prefs.getString('user_profile');
     if (profileStr != null) {
       return Student.fromJson(jsonDecode(profileStr));
     }
     return null;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
