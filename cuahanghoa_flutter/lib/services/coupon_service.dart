import 'package:firebase_database/firebase_database.dart';
import '../models/coupon_model.dart'; // Đảm bảo đường dẫn đúng

class CouponService {
  // 1. Trỏ đến node "coupons" trong Firebase RTDB
  final DatabaseReference _ref = FirebaseDatabase.instance.ref('coupons');

  ///  Thêm hoặc Cập nhật một mã giảm giá
  /// (Dùng mã code làm ID)
  Future<void> addOrUpdateCoupon(CouponModel coupon) async {
    // Dùng coupon.id (là mã code, ví dụ "SALE20") làm key
    // Chuyển ID về chữ hoa để đảm bảo tính duy nhất
    await _ref.child(coupon.id.toUpperCase()).set(coupon.toMap());
  }

  ///  Xóa một mã giảm giá
  Future<void> deleteCoupon(String couponId) async {
    await _ref.child(couponId.toUpperCase()).remove();
  }

  ///  Lấy (stream) TẤT CẢ các mã giảm giá (cho Admin)
  Stream<List<CouponModel>> getAllCoupons() {
    return _ref.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return []; // Không có mã nào

      final map = data as Map<dynamic, dynamic>;
      return map.entries.map((entry) {
        // entry.key chính là ID (mã code)
        return CouponModel.fromMap(entry.value, entry.key);
      }).toList()
      ..sort((a, b) => b.expirationDate.compareTo(a.expirationDate)); // Sắp xếp (mới hết hạn lên đầu)
    });
  }

  ///  Lấy (Future) 1 mã giảm giá CỤ THỂ (cho User khi nhập mã)
  Future<CouponModel?> getCouponById(String couponId) async {
    // Chuyển couponId về chữ hoa để khớp (ví dụ: user gõ "sale20")
    final snapshot = await _ref.child(couponId.toUpperCase()).get();

    if (!snapshot.exists || snapshot.value == null) {
      return null; // Không tìm thấy mã
    }

    final data = snapshot.value as Map<dynamic, dynamic>;
    return CouponModel.fromMap(data, snapshot.key!);
  }
}