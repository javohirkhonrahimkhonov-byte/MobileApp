import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'auth_service.dart';

class DataService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // 1. Get Profile
  Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse(ApiConstants.profile),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load profile');
  }

  // 2. Get Dashboard Stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await http.get(
      Uri.parse(ApiConstants.dashboard),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load dashboard');
  }

  // 3. Get Activities
  Future<List<dynamic>> getActivities() async {
    final response = await http.get(
      Uri.parse(ApiConstants.activities),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load activities');
  }

  // 4. Get Clubs
  Future<List<dynamic>> getMyClubs() async {
    final response = await http.get(
      Uri.parse(ApiConstants.clubsMy),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load clubs');
  }
}
