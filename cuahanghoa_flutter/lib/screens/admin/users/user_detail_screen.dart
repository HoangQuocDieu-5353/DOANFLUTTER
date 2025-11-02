import 'package:flutter/material.dart';
import 'package:cuahanghoa_flutter/models/user_model.dart';
import 'package:cuahanghoa_flutter/services/user_service.dart';

class UserDetailScreen extends StatefulWidget {
  final UserModel user; // Chỉ nhận user ban đầu
  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final UserService _userService = UserService();
  bool _isLoading = false;
  //  KHÔNG CẦN state _user và _isLocked riêng
  // late UserModel _user;
  // bool _isLocked = false;

  //  Hàm _toggleLock giờ sẽ nhận user TỪ STREAM
  Future<void> _toggleLock(UserModel currentUser) async {
    setState(() => _isLoading = true);
    final userId = currentUser.id;

    try {
      //  Đọc trạng thái trực tiếp từ user.isLocked
      if (currentUser.isLocked) {
        await _userService.unlockUser(userId);
      } else {
        await _userService.lockUser(userId);
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Lỗi: $e")),
         );
      }
    } finally {
       if (mounted) {
         setState(() => _isLoading = false);
       }
    }
    // Không cần setState cho _isLocked nữa, StreamBuilder sẽ tự cập nhật
  }

  //  Hàm _changeRole cũng nhận user TỪ STREAM
  Future<void> _changeRole(UserModel currentUser, String newRole) async {
    setState(() => _isLoading = true);
    try {
      await _userService.updateUser(currentUser.id, {'role': newRole});
    } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Lỗi: $e")),
         );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
     // Không cần setState cho _user nữa, StreamBuilder sẽ tự cập nhật
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chi tiết người dùng")),
      //  Dùng StreamBuilder để data luôn mới
      body: StreamBuilder<UserModel?>(
        stream: _userService.listenToUser(widget.user.id), // Lắng nghe user này
        initialData: widget.user, // Hiển thị data cũ trong khi chờ
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Không tìm thấy người dùng."));
          }

          //  Lấy user MỚI NHẤT từ stream
          final user = snapshot.data!;

          // Dùng Stack để hiển thị loading đè lên
          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                          ? NetworkImage(user.avatarUrl!)
                          : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                    ),
                    const SizedBox(height: 16),
                    Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(user.email),
                    const SizedBox(height: 20),

                    //  Role
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Role: "),
                        DropdownButton<String>(
                          value: user.role, // Lấy từ stream
                          items: const [
                            DropdownMenuItem(value: 'user', child: Text('User')),
                            DropdownMenuItem(value: 'admin', child: Text('Admin')),
                          ],
                          onChanged: (value) {
                            if (value != null) _changeRole(user, value); // Truyền user từ stream
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      //  Đọc trạng thái khóa từ user.isLocked
                      icon: Icon(user.isLocked ? Icons.lock_open : Icons.lock),
                      label: Text(user.isLocked ? "Mở khóa tài khoản" : "Khóa tài khoản"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: user.isLocked ? Colors.green : Colors.red,
                        foregroundColor: Colors.white, // Thêm màu chữ
                      ),
                      onPressed: () => _toggleLock(user), // Truyền user từ stream
                    ),
                  ],
                ),
              ),

              //  Hiển thị loading đè lên
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }
}