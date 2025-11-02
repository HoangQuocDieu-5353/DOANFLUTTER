import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cuahanghoa_flutter/models/coupon_model.dart';
import 'package:cuahanghoa_flutter/services/coupon_service.dart';

class AdminCouponFormScreen extends StatefulWidget {
  // 1. Nhận vào coupon (nếu là 'sửa') hoặc null (nếu là 'thêm mới')
  final CouponModel? coupon;

  const AdminCouponFormScreen({super.key, this.coupon});

  @override
  State<AdminCouponFormScreen> createState() => _AdminCouponFormScreenState();
}

class _AdminCouponFormScreenState extends State<AdminCouponFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _couponService = CouponService();
  bool _isLoading = false;

  // Controllers cho các trường
  late TextEditingController _idController; // Mã code
  late TextEditingController _descriptionController;
  late TextEditingController _percentageController;
  late TextEditingController _dateController; // Hiển thị ngày

  // Biến state
  DateTime _selectedDate = DateTime.now();
  bool _isEnabled = true;
  bool _isEditing = false; // Cờ kiểm tra xem đang sửa hay thêm mới

  @override
  void initState() {
    super.initState();
    _isEditing = widget.coupon != null;
    final c = widget.coupon;

    // Khởi tạo giá trị
    _idController = TextEditingController(text: c?.id ?? '');
    _descriptionController = TextEditingController(text: c?.description ?? '');
    _percentageController =
        TextEditingController(text: c?.discountPercentage.toString() ?? '');
    _selectedDate = c?.expirationDate ?? DateTime.now().add(const Duration(days: 30));
    _isEnabled = c?.isEnabled ?? true;

    // Hiển thị ngày đã chọn
    _dateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(_selectedDate),
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    _descriptionController.dispose();
    _percentageController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  /// 2. Hàm chọn ngày
  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(), // Không cho chọn ngày quá khứ
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)), // 2 năm
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
      });
    }
  }

  /// 3. Hàm Lưu
  Future<void> _saveCoupon() async {
    if (!_formKey.currentState!.validate()) {
      return; // Nếu form không hợp lệ -> dừng
    }

    setState(() => _isLoading = true);

    // Lấy giá trị từ controllers
    final String id = _idController.text.trim().toUpperCase(); // VIẾT HOA mã
    final String description = _descriptionController.text.trim();
    final int percentage = int.tryParse(_percentageController.text) ?? 0;

    // Tạo model
    final coupon = CouponModel(
      id: id,
      description: description,
      discountPercentage: percentage,
      expirationDate: _selectedDate,
      isEnabled: _isEnabled,
    );

    try {
      await _couponService.addOrUpdateCoupon(coupon);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_isEditing
                  ? 'Cập nhật thành công!'
                  : 'Thêm mã thành công!')),
        );
        Navigator.pop(context); // Quay lại màn hình danh sách
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa Mã giảm giá' : 'Thêm Mã giảm giá'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mã Code (ID)
                    TextFormField(
                      controller: _idController,
                      // Không cho sửa ID (mã code) nếu đang edit
                      readOnly: _isEditing,
                      decoration: InputDecoration(
                        labelText: "Mã giảm giá (ví dụ: SALE20)",
                        labelStyle: GoogleFonts.inter(),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.confirmation_num),
                        filled: _isEditing,
                        fillColor: _isEditing ? Colors.grey[200] : null,
                      ),
                      // Chuyển chữ hoa
                      textCapitalization: TextCapitalization.characters,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mã';
                        }
                        if (value.contains(" ")) {
                          return 'Mã không được chứa dấu cách';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Mô tả
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: "Mô tả (ví dụ: Giảm giá 20/11)",
                        labelStyle: GoogleFonts.inter(),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.description),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mô tả';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Phần trăm (%)
                    TextFormField(
                      controller: _percentageController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Giảm bao nhiêu %",
                        labelStyle: GoogleFonts.inter(),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.percent),
                      ),
                      validator: (value) {
                        final p = int.tryParse(value ?? '');
                        if (p == null || p <= 0 || p > 100) {
                          return 'Phần trăm phải từ 1 đến 100';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Ngày hết hạn
                    TextFormField(
                      controller: _dateController,
                      readOnly: true, // Không cho gõ
                      decoration: InputDecoration(
                        labelText: "Ngày hết hạn",
                        labelStyle: GoogleFonts.inter(),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                      onTap: _pickDate, // Nhấn vào để mở lịch
                    ),
                    const SizedBox(height: 12),
                    // Nút Bật/Tắt
                    SwitchListTile(
                      title: Text(
                        _isEnabled ? "Đang bật (Có hiệu lực)" : "Đang tắt (Vô hiệu hóa)",
                        style: GoogleFonts.inter(
                          color: _isEnabled ? Colors.green : Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text("Cho phép người dùng sử dụng mã này"),
                      value: _isEnabled,
                      onChanged: (value) {
                        setState(() => _isEnabled = value);
                      },
                    ),
                    const SizedBox(height: 24),
                    // Nút Lưu
                    ElevatedButton.icon(
                      onPressed: _saveCoupon,
                      icon: const Icon(Icons.save),
                      label: Text(
                        _isEditing ? "Lưu thay đổi" : "Thêm mã mới",
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}