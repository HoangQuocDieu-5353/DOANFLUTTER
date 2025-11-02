import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cuahanghoa_flutter/models/coupon_model.dart';
import 'package:cuahanghoa_flutter/services/coupon_service.dart';
import 'admin_coupon_form_screen.dart'; 

class AdminCouponListScreen extends StatefulWidget {
  const AdminCouponListScreen({super.key});

  @override
  State<AdminCouponListScreen> createState() => _AdminCouponListScreenState();
}

class _AdminCouponListScreenState extends State<AdminCouponListScreen> {
  final CouponService _couponService = CouponService();

  // Hàm helper để format ngày
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Hàm helper để xử lý xóa
  Future<void> _deleteCoupon(String couponId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text("Bạn có chắc muốn xóa mã giảm giá '$couponId'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _couponService.deleteCoupon(couponId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Đã xóa mã: $couponId")),
        );
      }
    }
  }

  // Hàm helper để bật/tắt mã
  Future<void> _toggleEnabled(CouponModel coupon) async {
     // Cập nhật trạng thái isEnabled
     final updatedCoupon = CouponModel(
        id: coupon.id,
        description: coupon.description,
        discountPercentage: coupon.discountPercentage,
        expirationDate: coupon.expirationDate,
        isEnabled: !coupon.isEnabled, // Đảo ngược trạng thái
     );
     await _couponService.addOrUpdateCoupon(updatedCoupon);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Quản lý Mã giảm giá", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<List<CouponModel>>(
        stream: _couponService.getAllCoupons(), // Gọi hàm lấy tất cả coupon
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text("Chưa có mã giảm giá nào.",
                  style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600])),
            );
          }

          final coupons = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: coupons.length,
            itemBuilder: (context, index) {
              final coupon = coupons[index];
              final isExpired = coupon.expirationDate.isBefore(DateTime.now());
              final color = (coupon.isEnabled && !isExpired) ? Colors.green : Colors.red;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: color.withOpacity(0.5), width: 1), // Viền theo trạng thái
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Mã Code và %
                          Text(
                            coupon.id, // Ví dụ: "SALE20"
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          Text(
                            "${coupon.discountPercentage}% OFF", // Ví dụ: "20% OFF"
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Mô tả
                      Text(
                        coupon.description,
                        style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
                      ),
                      const Divider(height: 16),
                      // Ngày hết hạn
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: isExpired ? Colors.red : Colors.grey[700]),
                          const SizedBox(width: 8),
                          Text(
                            "Hết hạn: ${_formatDate(coupon.expirationDate)}",
                            style: GoogleFonts.inter(
                              color: isExpired ? Colors.red : Colors.grey[700],
                              fontWeight: isExpired ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Trạng thái Bật/Tắt
                      Row(
                        children: [
                          Icon(coupon.isEnabled ? Icons.check_circle : Icons.cancel, size: 16, color: coupon.isEnabled ? Colors.green : Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            coupon.isEnabled ? "Đang bật" : "Đã vô hiệu hóa",
                            style: GoogleFonts.inter(
                              color: coupon.isEnabled ? Colors.green : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      
                      const Divider(height: 16),

                      // Hàng nút điều khiển
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Nút Bật/Tắt
                          TextButton.icon(
                            icon: Icon(coupon.isEnabled ? Icons.toggle_off : Icons.toggle_on),
                            label: Text(coupon.isEnabled ? "Tắt" : "Bật"),
                            style: TextButton.styleFrom(
                              foregroundColor: coupon.isEnabled ? Colors.grey : Colors.green,
                            ),
                            onPressed: () => _toggleEnabled(coupon),
                          ),
                          // Nút Sửa
                          TextButton.icon(
                            icon: const Icon(Icons.edit, size: 20),
                            label: const Text("Sửa"),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  // Chuyển sang màn hình Form (Bước 4) với data
                                  builder: (_) => AdminCouponFormScreen(coupon: coupon),
                                ),
                              );
                            },
                          ),
                          // Nút Xóa
                          TextButton.icon(
                            icon: const Icon(Icons.delete, size: 20),
                            label: const Text("Xóa"),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            onPressed: () => _deleteCoupon(coupon.id),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      // Nút Thêm mới
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminCouponFormScreen(), // Mở form rỗng
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}