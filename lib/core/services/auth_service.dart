import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student.dart';
import '../constants/api_constants.dart';

class AuthService {
  
  // Using PROXY (Our Server) for Login now as updated in api_constants
  Future<Student?> login(String login, String password) async {
    // 0. DEMO MODE
    if (login == 'demo' && password == '123') {
       // ... (Same as before) ...
       return demoStudent;
    }

    final url = Uri.parse(ApiConstants.authLogin);
    try {
      print('Proxy Login: $url');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'login': login, 'password': password}),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'];
        
        if (data != null && data['token'] != null) {
          final token = data['token'];
          final role = data['role'] ?? 'student';
          
          await _saveToken(token);
          await _saveRole(role); // NEW: Save Role
          
          if (data['profile'] != null) {
             await _saveProfile(data['profile']);
             // Be careful: Staff profile structure might differ from Student
             // Ideally we need a User model, but for now strict casting might fail if fields missing.
             // We return a Student object for UI compatibility.
             return Student.fromJson(data['profile']);
          }
          return await _fetchAndSaveProfile(token);
        }
      }
    } catch (e) {
      print('Auth Error: $e');
    }
    return null;
  }

  // ... (Same _fetchAndSaveProfile etc) ...

  Future<void> _saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role);
  }

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role') ?? 'student';
  }

  // ============================================================
  // TELEGRAM AUTH
  // ============================================================
  Future<Map<String, String>?> initTelegramAuth() async {
    try {
      final url = Uri.parse('${ApiConstants.backendUrl}/auth/init');
      final response = await http.post(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'uuid': data['uuid'],
          'url': data['url']
        };
      }
    } catch (e) {
      print("Telegram Auth Init Error: $e");
    }
    return null;
  }

  Future<Student?> checkTelegramAuth(String uuid) async {
    try {
      final url = Uri.parse('${ApiConstants.backendUrl}/auth/check/$uuid');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'verified' && data['token'] != null) {
          final token = data['token'];
          final role = data['role'] ?? 'student'; // Get Role

          await _saveToken(token);
          await _saveRole(role);
          
          if (data['profile'] != null) {
            await _saveProfile(data['profile']);
            return Student.fromJson(data['profile']);
          }
          
          return await _fetchAndSaveProfile(token);
        }
      }
    } catch (e) {
      print("Telegram Check Error: $e");
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

  // ============================================================
  // TELEGRAM AUTH
  // ============================================================
  Future<Map<String, String>?> initTelegramAuth() async {
    try {
      final url = Uri.parse('${ApiConstants.backendUrl}/auth/init');
      final response = await http.post(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'uuid': data['uuid'],
          'url': data['url']
        };
      }
    } catch (e) {
      print("Telegram Auth Init Error: $e");
    }
    return null;
  }

  Future<Student?> checkTelegramAuth(String uuid) async {
    try {
      final url = Uri.parse('${ApiConstants.backendUrl}/auth/check/$uuid');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'verified' && data['token'] != null) {
          final token = data['token'];
          
          await _saveToken(token);
          
          // If we have profile data, save it too
          if (data['profile'] != null) {
            await _saveProfile(data['profile']);
            return Student.fromJson(data['profile']);
          }
          
          return await _fetchAndSaveProfile(token);
        }
      }
    } catch (e) {
      print("Telegram Check Error: $e");
    }
    return null;
  }
}
