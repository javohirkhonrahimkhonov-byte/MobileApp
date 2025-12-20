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
  Future<Map<String, dynamic>?> checkAuth(String uuid) async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.authCheck}/$uuid'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Check auth error: $e");
    }
    return null;
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
