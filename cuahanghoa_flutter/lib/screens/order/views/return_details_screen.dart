import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ReturnDetailsScreen extends StatefulWidget {
  final String orderId;

  const ReturnDetailsScreen({super.key, required this.orderId});

  @override
  State<ReturnDetailsScreen> createState() => _ReturnDetailsScreenState();
}

class _ReturnDetailsScreenState extends State<ReturnDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  String? _refundMethod;
  File? _proofImage;
  bool _isSubmitting = false;
  bool _isPickingImage = false;

  //  Cloudinary config
  final cloudinary = CloudinaryPublic(
    'dtwpzu5yb', // Cloud name của bạn
    'flutter_unsigned', // Upload preset của bạn
    cache: false,
  );

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    try {
      setState(() => _isPickingImage = true);
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (picked != null) {
        setState(() => _proofImage = File(picked.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Lỗi chọn ảnh: $e")));
    } finally {
      setState(() => _isPickingImage = false);
    }
  }

  Future<void> _submitReturnRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bạn chưa đăng nhập!")),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    String? proofUrl;
    if (_proofImage != null) {
      try {
        final response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            _proofImage!.path,
            folder: 'returns',
            publicId: widget.orderId, // Gắn theo ID đơn hàng
            resourceType: CloudinaryResourceType.Image,
          ),
        );
        proofUrl = response.secureUrl;
        debugPrint("✅ Upload Cloudinary thành công: $proofUrl");
      } on CloudinaryException catch (e) {
        debugPrint('❌ Lỗi Upload Cloudinary: ${e.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi upload ảnh: ${e.message}")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi không xác định khi upload ảnh: $e")),
        );
      }
    }

    final orderRef =
        FirebaseDatabase.instance.ref('orders/${user.uid}/${widget.orderId}');
    await orderRef.update({
      'status': 'return_requested',
      'returnReason': _reasonController.text.trim(),
      'refundMethod': _refundMethod,
      'returnProofUrl': proofUrl ?? '',
      'returnRequestedAt': DateTime.now().toIso8601String(),
    });

    if (mounted) {
      setState(() => _isSubmitting = false);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('🎉 Yêu cầu đã gửi thành công'),
          content: const Text(
            'Shop đã nhận được yêu cầu trả hàng của bạn.\n'
            'Vui lòng chờ phản hồi trong **2 ngày làm việc**.\n'
            'Cảm ơn bạn đã mua sắm cùng chúng tôi 🌸',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              child: const Text('Về trang chủ'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = GoogleFonts.inter(fontWeight: FontWeight.w500);
    final inputStyle = GoogleFonts.inter(fontSize: 15);

    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết trả hàng', style: GoogleFonts.inter()),
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _reasonController,
                      style: inputStyle,
                      decoration: InputDecoration(
                        labelText: 'Lý do trả hàng',
                        labelStyle: labelStyle,
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Vui lòng nhập lý do' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _refundMethod,
                      decoration: InputDecoration(
                        labelText: 'Hình thức hoàn tiền',
                        labelStyle: labelStyle,
                        border: const OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'cash', child: Text('Tiền mặt')),
                        DropdownMenuItem(
                            value: 'wallet', child: Text('Hoàn vào ví')),
                        DropdownMenuItem(
                            value: 'bank', child: Text('Chuyển khoản ngân hàng')),
                      ],
                      onChanged: (value) => setState(() => _refundMethod = value),
                      validator: (v) =>
                          v == null ? 'Vui lòng chọn hình thức hoàn tiền' : null,
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.image),
                      label: const Text('Tải hình ảnh bằng chứng'),
                      onPressed: _pickImage,
                    ),
                    if (_proofImage != null) ...[
                      const SizedBox(height: 10),
                      Image.file(_proofImage!, height: 160, fit: BoxFit.cover),
                    ],
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _submitReturnRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Gửi yêu cầu trả hàng',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
