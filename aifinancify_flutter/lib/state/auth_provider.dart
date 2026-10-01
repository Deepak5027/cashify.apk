import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  Map<String, dynamic>? _user;
  bool _isAuthenticated = false;
  bool _isLoading = true;

  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  AuthProvider() {
    checkSession();
  }

  Future<void> checkSession() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _apiService.verifyToken();
      if (data != null && data['user'] != null) {
        _user = data['user'];
        _isAuthenticated = true;
      }
    } catch (_) {
      _user = null;
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _apiService.login(email, password);
      if (data['token'] != null) {
        _user = data['user'];
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
    return false;
  }

  Future<bool> signup(String email, String password, String name) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.signup(email, password, name);
      // Immediately log in user
      return await login(email, password);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _authService.signInWithGoogle();
      if (data != null) {
        _user = data['user'];
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
    return false;
  }

  void updateLocalUser(Map<String, dynamic> updates) {
    if (_user != null) {
      _user = {..._user!, ...updates};
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await _authService.signOut();
    _user = null;
    _isAuthenticated = false;
    _isLoading = false;
    notifyListeners();
  }
}
