import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_database/firebase_database.dart'; // 👈 Thêm dòng này để dùng Realtime DB

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance.ref(); // 👈 Khởi tạo tham chiếu DB

  // ===== STREAM & CURRENT USER =====
  Stream<User?> get userStream => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ===== EMAIL / PASSWORD =====
  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
    } catch (e) {
      return 'Lỗi không xác định: $e';
    }
  }

  Future<String?> register(String email, String password, String name) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 👇 Ghi vào Realtime Database
      await _db.child('users').child(result.user!.uid).set({
        'name': name,
        'email': email,
        'createdAt': DateTime.now().toIso8601String(),
      });

      return null;
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
    } catch (e) {
      return 'Lỗi không xác định: $e';
    }
  }

  // ===== GOOGLE SIGN-IN =====
  Future<String?> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      GoogleSignInAccount? googleUser = await googleSignIn.signInSilently();
      googleUser ??= await googleSignIn.signIn();

      if (googleUser == null) return 'Người dùng đã huỷ đăng nhập.';

      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) return 'Lỗi: Không có ID Token';

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      final user = result.user;

      // 👇 Lưu thông tin vào Realtime Database nếu chưa có
      if (user != null) {
        final userRef = _db.child('users').child(user.uid);

        final snapshot = await userRef.get();
        if (!snapshot.exists) {
          await userRef.set({
            'name': user.displayName ?? '',
            'email': user.email ?? '',
            'photoURL': user.photoURL ?? '',
            'loginType': 'google',
            'createdAt': DateTime.now().toIso8601String(),
          });
        }
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
    } catch (e) {
      return 'Lỗi Google Sign-In: $e';
    }
  }

  // ===== RESET PASSWORD =====
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
    } catch (e) {
      return 'Lỗi không xác định: $e';
    }
  }

  // ===== SIGN OUT =====
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  // ===== XỬ LÝ LỖI =====
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email này đã được sử dụng. Vui lòng đăng nhập hoặc dùng tài khoản khác.';
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này.';
      case 'wrong-password':
        return 'Sai mật khẩu. Vui lòng thử lại.';
      case 'invalid-email':
        return 'Email không hợp lệ.';
      default:
        return e.message ?? 'Đã xảy ra lỗi không xác định.';
    }
  }
}
