import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/auth_service.dart';

class AuthController with ChangeNotifier {
  final _service = AuthService();
  final _db = FirebaseDatabase.instance.ref();

  String? _displayNameFromDB;
  String? get displayNameFromDB => _displayNameFromDB;

  User? get user => _service.currentUser;

  AuthController() {
    _service.userStream.listen((u) async {
      if (u != null) {
        await _loadDisplayName(u.uid); // lấy tên từ Realtime DB
      } else {
        _displayNameFromDB = null;
      }
      notifyListeners();
    });
  }

  // Đăng nhập với email và mật khẩu
  Future<String?> login(String email, String password) =>
      _service.signIn(email, password);

  // Đăng ký với email, mật khẩu và tên người dùng
  Future<String?> register(String email, String password, String name) async {
    final result = await _service.register(email, password, name);
    if (result == null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _saveUserToDatabase(user, method: 'email', name: name);
        await _loadDisplayName(user.uid);
        notifyListeners();
      }
    }
    return result;
  }

  // Đăng nhập với Google
  Future<String?> loginWithGoogle() async {
    final result = await _service.signInWithGoogle();
    if (result == null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _saveUserToDatabase(user, method: 'google');
        await _loadDisplayName(user.uid);
        notifyListeners();
      }
    }
    return result;
  }

  /// Lưu thông tin người dùng vào Realtime Database nếu chưa có
  Future<void> _saveUserToDatabase(User user,
      {required String method, String? name}) async {
    final ref = FirebaseDatabase.instance.ref('users/${user.uid}');
    final snapshot = await ref.get();

    if (!snapshot.exists) {
      await ref.set({
        'uid': user.uid,
        'email': user.email,
        'name': name ?? user.displayName ?? '',
        'registeredAt': DateTime.now().millisecondsSinceEpoch,
        'loginMethod': method,
      });
    }
  }

  /// Lấy tên người dùng từ Realtime Database
  Future<void> _loadDisplayName(String uid) async {
    final snapshot = await _db.child('users/$uid/name').get();
    if (snapshot.exists) {
      _displayNameFromDB = snapshot.value.toString();
    } else {
      _displayNameFromDB = null;
    }
  }
  Future<void> logout() async {
    await _service.signOut();
    // sau khi sign-out, notifyListeners() đã gọi trong stream
  }
}
