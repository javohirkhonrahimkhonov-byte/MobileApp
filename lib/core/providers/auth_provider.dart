import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../models/student.dart';
import '../constants/universities.dart';
import '../constants/api_constants.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  Student? _currentUser;
  bool _isLoading = true;
  University _selectedUniversity = supportedUniversities[0]; // Default JDPU

  Student? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  University get selectedUniversity => _selectedUniversity;

  AuthProvider() {
    _loadUser();
  }

  void setUniversity(University university) {
    _selectedUniversity = university;
    ApiConstants.setBaseUrl(university.apiBaseUrl);
    notifyListeners();
  }

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load saved URL
      final savedUrl = prefs.getString('hemis_base_url');
      if (savedUrl != null) {
        ApiConstants.setBaseUrl(savedUrl);
        // Try to find matching university object for UI
        try {
          _selectedUniversity = supportedUniversities.firstWhere((u) => u.apiBaseUrl == savedUrl);
        } catch (_) {}
      }

      _currentUser = await _authService.getSavedUser();
    } catch (e) {
      print("Error loading user: $e");
      await _authService.logout();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> login(String login, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Ensure ApiConstants is updated (redundant but safe)
      ApiConstants.setBaseUrl(_selectedUniversity.apiBaseUrl);
      
      final student = await _authService.login(login, password);
      if (student != null) {
        _currentUser = student;
        
        // Save URL permanently
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('hemis_base_url', _selectedUniversity.apiBaseUrl);

         _isLoading = false;
        notifyListeners();
        return null; // Success
      } else {
         _isLoading = false;
        notifyListeners();
        return "Login yoki parol noto'g'ri";
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return "Xatolik yuz berdi: $e";
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }
}
