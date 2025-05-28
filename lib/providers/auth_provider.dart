import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;

  AuthProvider() {
    _authService.userStream.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  // Getter để lấy thông tin user hiện tại
  User? get user => _user;

  bool get isLoggedIn => _user != null;

  // Gọi các hàm từ AuthService
  Future<bool> login(String email, String password) async {
    final result = await _authService.loginWithEmail(email, password);
    return result != null;
  }

  Future<bool> register(String email, String password) async {
    final result = await _authService.registerWithEmail(email, password);
    return result != null;
  }

  Future<void> logout() async {
    await _authService.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _authService.resetPassword(email);
  }
}
