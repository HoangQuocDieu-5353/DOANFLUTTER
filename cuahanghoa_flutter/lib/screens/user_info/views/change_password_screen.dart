import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  // State cho ẩn/hiện mật khẩu
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    // 0. Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      setState(() => _errorMessage = "Không tìm thấy thông tin người dùng.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Re-authenticate (Xác thực lại bằng mật khẩu cũ)
      final cred = EmailAuthProvider.credential(
        email: user.email!, // Email của người dùng hiện tại
        password: _currentPasswordController.text,
      );
      await user.reauthenticateWithCredential(cred);

      // 2. Nếu xác thực thành công -> Cập nhật mật khẩu mới
      await user.updatePassword(_newPasswordController.text);

      // 3. Thông báo thành công và quay lại
      if (mounted) {
        Navigator.pop(context); // Quay lại màn hình UserInfo
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Đổi mật khẩu thành công!")),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Xử lý lỗi
      setState(() {
        if (e.code == 'wrong-password') {
          _errorMessage = "Mật khẩu hiện tại không đúng.";
        } else if (e.code == 'weak-password') {
          // Rõ hơn
          _errorMessage = "Mật khẩu mới quá yếu (cần ít nhất 6 ký tự).";
        } else if (e.code == 'requires-recent-login') {
          // Rõ hơn
           _errorMessage = "Phiên đăng nhập đã cũ. Vui lòng đăng xuất và đăng nhập lại trước khi đổi mật khẩu.";
        }
        // ⬇ VIỆT HÓA LỖI TRONG ẢNH ⬇️
        else if (e.code == 'invalid-credential' || e.message?.contains('malformed') == true || e.message?.contains('expired') == true) {
           _errorMessage = "Thông tin xác thực không hợp lệ hoặc đã hết hạn. Vui lòng thử lại.";
        }
        // ⬆ HẾT PHẦN SỬA ⬆️
        else {
          // Lỗi Firebase chung khác
          _errorMessage = "Đã xảy ra lỗi xác thực (${e.code}). Vui lòng thử lại.";
        }
        print("FirebaseAuthException: ${e.code} - ${e.message}"); // Log lỗi
      });
    } catch (e) {
       setState(() {
          // Lỗi không xác định chung
          _errorMessage = "Đã xảy ra lỗi không mong muốn.";
       });
       print("Lỗi không xác định: $e"); // Log lỗi
    } finally {
       if(mounted) {
         setState(() => _isLoading = false);
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputStyle = GoogleFonts.inter(fontWeight: FontWeight.w500);
    final labelStyle = GoogleFonts.inter();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Đổi mật khẩu",
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mật khẩu hiện tại
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrent,
                decoration: InputDecoration(
                  labelText: "Mật khẩu hiện tại",
                  labelStyle: labelStyle,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureCurrent
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Vui lòng nhập' : null,
              ),
              const SizedBox(height: 16),

              // Mật khẩu mới
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: "Mật khẩu mới",
                  labelStyle: labelStyle,
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscureNew ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập';
                  }
                  if (value.length < 6) { // Firebase yêu cầu ít nhất 6 ký tự
                    return 'Mật khẩu phải có ít nhất 6 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Xác nhận mật khẩu mới
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: "Xác nhận mật khẩu mới",
                  labelStyle: labelStyle,
                  prefixIcon: const Icon(Icons.lock_clock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Mật khẩu xác nhận không khớp';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Hiển thị lỗi (nếu có)
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.inter(color: Colors.red.shade700),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Nút Lưu
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _changePassword,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        "Lưu thay đổi",
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}