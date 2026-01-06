import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/student.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  Student? _currentUser;
  bool _isLoading = true;

  Student? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    _currentUser = await _authService.getSavedUser();
    _isLoading = false;
    notifyListeners();
  }

  Future<String?> login(String login, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final student = await _authService.login(login, password);
      if (student != null) {
        _currentUser = student;
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
