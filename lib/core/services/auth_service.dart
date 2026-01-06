import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student.dart';
import '../constants/api_constants.dart';

class AuthService {
  
  Future<Student?> login(String login, String password) async {
    final url = Uri.parse(ApiConstants.authLogin);
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'login': login, 'password': password}),
      );

      print('Login Response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        
        // HEMIS API structure: {"success": true, "data": {"token": "..."}}
        String? token;
        if (body['data'] != null && body['data']['token'] != null) {
          token = body['data']['token'];
        } else if (body['token'] != null) {
          // Fallback if structure varies
          token = body['token'];
        }

        if (token != null) {
          await _saveToken(token);
          
          // Step 2: Get Profile
          return await _fetchAndSaveProfile(token);
        }
      } 
    } catch (e) {
      print('Auth Error: $e');
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
        // HEMIS /account/me usually returns: {"success": true, "data": {...}}
        final profileData = body['data'] ?? body;
        
        await _saveProfile(profileData);
        return Student.fromJson(profileData);
      }
    } catch (e) {
      print('Profile Fetch Error: $e');
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
