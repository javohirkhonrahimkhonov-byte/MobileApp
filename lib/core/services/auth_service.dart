import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();

  // 1. Initialize Login (Get UUID and Deep Link)
  Future<Map<String, dynamic>> initAuth() async {
    final response = await http.post(Uri.parse(ApiConstants.authInit));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to init auth');
    }
  }

  // 2. Check Auth Status (Poll)
  Future<bool> checkAuthStatus(String uuid) async {
    final response = await http.get(Uri.parse('${ApiConstants.authCheck}/$uuid'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'verified') {
        await _storage.write(key: 'auth_token', value: data['token']);
        return true;
      }
    }
    return false;
  }

  Future<bool> loginWithHemis(String login, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/auth/hemis'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'login': login, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'verified' && data['token'] != null) {
        await _storage.write(key: 'auth_token', value: data['token']);
        return true;
      }
    }
    return false;
  }

  // 3. Save Token
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  // 4. Get Token
  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  // 5. Logout
  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }
}
