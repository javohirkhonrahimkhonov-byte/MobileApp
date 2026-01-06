import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student.dart';
import '../constants/api_constants.dart';

class AuthService {
  
  Future<Student?> login(String login, String password) async {
    // We MUST use the Backend Proxy because:
    // 1. It creates/updates the Student record in our local Postgres DB (required for other features).
    // 2. It bypasses SSL handshake issues on Android Emulators.
    final url = Uri.parse('${ApiConstants.backendUrl}/auth/hemis');
    
    try {
      print('Attempting login to: $url');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'login': login, 'password': password}),
      ).timeout(const Duration(seconds: 30));

      print('Login Response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final profile = data['profile'];

        if (token != null && profile != null) {
          await _saveToken(token);
          await _saveProfile(profile);
          return Student.fromJson(profile);
        }
      } else {
        // Parse error message
        try {
          final errorBody = jsonDecode(response.body);
          print('Login Failed: ${errorBody['detail']}');
          throw Exception(errorBody['detail'] ?? 'Login Error: ${response.statusCode}');
        } catch (_) {
          throw Exception('Login Failed: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Auth Exception: $e');
      rethrow; // Pass error up to Provider
    }
    return null;
  }

  // _fetchAndSaveProfile is removed because the Proxy returns everything in one go.

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
