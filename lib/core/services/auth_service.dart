import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student.dart';

class AuthService {
  // Android Emulator uses 10.0.2.2 to access host machine's localhost
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1'; 

  Future<Student?> login(String login, String password) async {
    final url = Uri.parse('$baseUrl/auth/hemis');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'login': login, 'password': password}),
      );

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
        print('Login failed: ${response.body}');
      }
    } catch (e) {
      print('Auth Error: $e');
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

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
