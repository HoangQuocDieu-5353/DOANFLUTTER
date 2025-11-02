import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  ///  Đăng ký tài khoản mới
  Future<UserModel?> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Tạo tài khoản Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Lấy UID user
      final user = result.user;
      if (user == null) return null;

      // Tạo model user và lưu vào Realtime Database
      final userModel = UserModel(
        id: user.uid,
        name: name,
        email: email,
        createdAt: DateTime.now(),
      );

      await _userService.saveUser(userModel);

      return userModel;
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException: ${e.message}");
      rethrow;
    }
  }

  ///  Đăng nhập
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = result.user;
      if (user == null) return null;

      // Lấy thông tin user từ Realtime Database
      return await _userService.getUser(user.uid);
    } on FirebaseAuthException catch (e) {
      print("Login failed: ${e.message}");
      rethrow;
    }
  }

  ///  Đăng xuất
  Future<void> logout() async {
    await _auth.signOut();
  }

  ///  Quên mật khẩu
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  ///  Kiểm tra user hiện tại
  User? get currentUser => _auth.currentUser;

  ///  Stream lắng nghe trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
