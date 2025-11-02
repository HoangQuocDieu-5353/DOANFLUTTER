import 'package:flutter/material.dart';
import 'package:cuahanghoa_flutter/models/user_model.dart';
import 'package:cuahanghoa_flutter/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cuahanghoa_flutter/screens/user_info/views/edit_profile_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cuahanghoa_flutter/screens/user_info/views/change_password_screen.dart';


class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final UserService _userService = UserService();
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Bạn chưa đăng nhập")),
      );
    }

    return StreamBuilder<UserModel?>(
      stream: _userService.listenToUser(currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return const Scaffold(
            body: Center(child: Text("Không tìm thấy thông tin người dùng")),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              "Hồ sơ cá nhân",
              style: GoogleFonts.inter(),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.black,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfileScreen(user: user),
                    ),
                  );
                },
                child: Text(
                  "Sửa",
                  style: GoogleFonts.inter(
                    color: Colors.purple,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: user.avatarUrl != null &&
                          user.avatarUrl!.isNotEmpty
                      ? NetworkImage(user.avatarUrl!)
                      : const AssetImage('assets/icons/man.png')
                          as ImageProvider,
                ),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: GoogleFonts.inter(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 30),

                // Danh sách thông tin
                _buildInfoRow("Tên", user.name),
                _buildInfoRow(
                  "Ngày sinh",
                  user.dateOfBirth != null
                      ? "${user.dateOfBirth!.day}/${user.dateOfBirth!.month}/${user.dateOfBirth!.year}"
                      : "Chưa cập nhật",
                ),
                _buildInfoRow(
                    "Số điện thoại", user.phone ?? "Chưa cập nhật"),
                _buildInfoRow(
                    "Giới tính", user.gender ?? "Chưa cập nhật"),
                _buildInfoRow("Email", user.email),
                _buildInfoRow(
                  "Mật khẩu",
                  "Đổi mật khẩu",
                  isAction: true,
                  onTap: () {
                    // Điều hướng đến màn hình đổi mật khẩu mới
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ChangePasswordScreen()),
                    );
                  },
                ),

                const SizedBox(height: 40),

                ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: Text(
                    "Đăng xuất",
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[50],
                    foregroundColor: Colors.redAccent,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) Navigator.pop(context); 
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value,
      {VoidCallback? onTap, bool isAction = false}) {
    final textStyle = GoogleFonts.inter(fontSize: 16);

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18.0),
            child: Row(
              children: [
                Text(
                  label,
                  style: textStyle.copyWith(color: Colors.black54),
                ),
                const Spacer(),
                Text(
                  value,
                  style: textStyle.copyWith(
                    color: isAction ? Colors.purple : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
      ],
    );
  }
}