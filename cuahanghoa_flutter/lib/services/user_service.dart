import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';

class UserService {
  final DatabaseReference _userRef = FirebaseDatabase.instance.ref('users');

  /// Thêm hoặc cập nhật toàn bộ thông tin user
  Future<void> saveUser(UserModel user) async {
    await _userRef.child(user.id).set(user.toMap());
  }

  /// Lấy thông tin user theo id
  Future<UserModel?> getUser(String userId) async {
    final snapshot = await _userRef.child(userId).get();
    if (snapshot.exists) {
      return UserModel.fromMap(
        snapshot.value as Map<dynamic, dynamic>,
        snapshot.key!,
      );
    }
    return null;
  }

  /// Cập nhật một vài trường riêng lẻ
  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    await _userRef.child(userId).update(updates);
  }

  /// Xóa user
  Future<void> deleteUser(String userId) async {
    await _userRef.child(userId).remove();
  }

  /// Lắng nghe thay đổi realtime (Profile / Admin panel)
  Stream<UserModel?> listenToUser(String userId) {
    return _userRef.child(userId).onValue.map((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        return UserModel.fromMap(data, event.snapshot.key!);
      }
      return null;
    });
  }

  /// Tạo user mới nếu chưa tồn tại (sau khi đăng ký)
  Future<void> createUserIfNotExists(UserModel user) async {
    final snapshot = await _userRef.child(user.id).get();
    if (!snapshot.exists) {
      await _userRef.child(user.id).set({
        ...user.toMap(),
        'createdAt': DateTime.now().toIso8601String(),
        'role': user.role,
        'isLocked': false,
      });
    }
  }

  /// Khóa tài khoản user (user không thể đăng nhập)
  Future<void> lockUser(String userId) async {
    await _userRef.child(userId).update({'isLocked': true});
  }

  /// Mở khóa tài khoản user
  Future<void> unlockUser(String userId) async {
    await _userRef.child(userId).update({'isLocked': false});
  }

  /// Lấy toàn bộ danh sách user
  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _userRef.get();
    if (snapshot.exists) {
      final users = <UserModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        if (value is Map) {
          users.add(UserModel.fromMap(value, key));
        }
      });
      return users;
    }
    return [];
  }

  // Thêm hàm bật/tắt thông báo
  Future<void> toggleNotificationSetting(String userId, bool enable) async {
    await _userRef.child(userId).update({'notificationsEnabled': enable});
  }
}
