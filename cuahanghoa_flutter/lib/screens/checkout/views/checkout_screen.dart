import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pay/pay.dart';
import 'package:cuahanghoa_flutter/models/cart_item.dart';
import 'package:cuahanghoa_flutter/models/order_model.dart';
import 'package:cuahanghoa_flutter/services/order_service.dart';
import 'package:cuahanghoa_flutter/services/cart_service.dart';
import 'package:cuahanghoa_flutter/screens/order/views/order_success_screen.dart';
import 'package:cuahanghoa_flutter/config/payment_config.dart';

// . IMPORT COUPON SERVICE VÀ MODEL
import 'package:cuahanghoa_flutter/services/coupon_service.dart';
import 'package:cuahanghoa_flutter/models/coupon_model.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final int totalPrice; 

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.totalPrice,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _addressController = TextEditingController();
  String _paymentMethod = "cash";
  bool _isProcessing = false; 

  final OrderService _orderService = OrderService();
  final CartService _cartService = CartService();

  final TextEditingController _couponController = TextEditingController();
  final CouponService _couponService = CouponService();
  CouponModel? _appliedCoupon; // Lưu mã đã áp dụng
  int _discountAmount = 0; // Số tiền đã giảm
  String? _couponError; // Lỗi (mã sai, hết hạn...)
  bool _isCheckingCoupon = false; // Loading cho nút "Áp dụng"

  @override
  void initState() {
    super.initState();
    // (Bỏ _paymentItems khỏi đây)
  }

  @override
  void dispose() {
    _addressController.dispose();
    _couponController.dispose(); 
    super.dispose();
  }

  String _formatCurrency(int amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return "${formatter.format(amount)} VNĐ";
  }

  //  HÀM XỬ LÝ ÁP DỤNG MÃ
  Future<void> _applyCoupon() async {
    final String code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _isCheckingCoupon = true;
      _couponError = null;
    });

    try {
      final coupon = await _couponService.getCouponById(code);
      
      // Kiểm tra mã
      if (coupon == null) {
        setState(() => _couponError = "Mã giảm giá không hợp lệ.");
      } else if (!coupon.isEnabled) {
        setState(() => _couponError = "Mã này đã bị vô hiệu hóa.");
      } else if (coupon.expirationDate.isBefore(DateTime.now())) {
        setState(() => _couponError = "Mã này đã hết hạn.");
      } else {
        // Áp dụng thành công
        setState(() {
          _appliedCoupon = coupon;
          // Tính số tiền được giảm
          _discountAmount = (widget.totalPrice * coupon.discountPercentage / 100).round();
          _couponController.clear(); // Xóa text khỏi ô
        });
      }
    } catch (e) {
      setState(() => _couponError = "Đã xảy ra lỗi: $e");
    } finally {
      setState(() => _isCheckingCoupon = false);
    }
  }

  // 4. HÀM XÓA MÃ
  void _removeCoupon() {
    setState(() {
      _appliedCoupon = null;
      _discountAmount = 0;
      _couponError = null;
      _couponController.clear();
    });
  }

  /// HÀM XỬ LÝ ĐẶT HÀNG
  Future<void> _handlePlaceOrder() async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Vui lòng nhập địa chỉ giao hàng!")),
      );
      return;
    }
    
    // Tính toán giá cuối cùng
    final int finalPrice = widget.totalPrice - _discountAmount;

    if (_paymentMethod == "googlepay") {
      _startGooglePay(finalPrice); // Truyền giá cuối cùng
    } else {
      await _saveOrder("pending", finalPrice); // Truyền giá cuối cùng
    }
  }

  ///  HÀM START GOOGLE PAY
  void _startGooglePay(int finalPrice) { // Nhận giá cuối cùng
    // Khởi tạo paymentItems ngay lúc nhấn, với giá cuối cùng
    final List<PaymentItem> paymentItems = [
      PaymentItem(
        label: "Tổng thanh toán",
        amount: finalPrice.toStringAsFixed(0), // Dùng giá cuối cùng
        status: PaymentItemStatus.final_price,
      ),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Xác nhận thanh toán",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              "Tổng tiền: ${_formatCurrency(finalPrice)}", // Hiển thị giá cuối
              style: const TextStyle(fontSize: 16, color: Colors.deepPurple),
            ),
            const SizedBox(height: 24),
            Platform.isIOS
                ? ApplePayButton(
                    paymentConfiguration:
                        PaymentConfiguration.fromJsonString(defaultApplePay),
                    paymentItems: paymentItems, // Dùng list mới
                    style: ApplePayButtonStyle.black,
                    type: ApplePayButtonType.buy,
                    onPaymentResult: (result) async {
                      Navigator.pop(context);
                      await _saveOrder("paid", finalPrice); // Dùng giá cuối
                    },
                  )
                : GooglePayButton(
                    paymentConfiguration:
                        PaymentConfiguration.fromJsonString(defaultGooglePayVND),
                    paymentItems: paymentItems, // Dùng list mới
                    type: GooglePayButtonType.pay,
                    width: double.infinity,
                    height: 55,
                    margin: EdgeInsets.zero,
                    onPaymentResult: (result) async {
                      Navigator.pop(context);
                      await _saveOrder("paid", finalPrice); // Dùng giá cuối
                    },
                  ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  ///HÀM LƯU ĐƠN HÀNG
  Future<void> _saveOrder(String status, int finalPrice) async { // Nhận giá cuối
    setState(() => _isProcessing = true);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? "guest";

    final newOrder = OrderModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      items: widget.cartItems,
      totalPrice: finalPrice, 
      status: status,
      createdAt: DateTime.now(),
      paymentMethod: _paymentMethod,
      address: _addressController.text.trim(),
      // ⬇LƯU THÔNG TIN KHUYẾN MÃI (Yêu cầu OrderModel đã được cập nhật)
      couponCode: _appliedCoupon?.id, 
      discountAmount: _discountAmount,
    );

    try {
      await _orderService.createOrder(newOrder);
      await _cartService.clearCart();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OrderSuccessScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠ Lỗi lưu đơn hàng: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    //  TÍNH TOÁN GIÁ TRỊ HIỂN THỊ
    final int finalPrice = widget.totalPrice - _discountAmount;
    final totalFormatted = _formatCurrency(finalPrice); // Format giá cuối

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text(
          "Xác nhận đơn hàng",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            //  Địa chỉ giao hàng
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: "📍 Nhập địa chỉ giao hàng",
                  labelStyle: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            //  THÊM UI CHO MÃ GIẢM GIÁ
            _buildCouponSection(),
            const SizedBox(height: 24),

            // Phương thức thanh toán
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "💳 Chọn hình thức thanh toán",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
              ),
            ),
            const SizedBox(height: 12),

            _buildPaymentOption(
              "cash",
              "Tiền mặt khi nhận hàng (COD)",
              "assets/icons/cod.png",
            ),
            const SizedBox(height: 8),
            _buildPaymentOption(
              "googlepay",
              Platform.isIOS ? "Thanh toán qua Apple Pay" : "Thanh toán qua Google Pay",
              "assets/icons/ggpay.png",
            ),

            const Spacer(), // Đẩy phần tổng tiền xuống dưới

            // HIỂN THỊ TÓM TẮT GIÁ
            if (_discountAmount > 0) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Tạm tính:", style: TextStyle(fontSize: 15, color: Colors.grey)),
                    Text(_formatCurrency(widget.totalPrice), style: const TextStyle(fontSize: 15, color: Colors.grey)),
                  ],
                ),
              ),
               Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Giảm giá (${_appliedCoupon!.id}):", style: const TextStyle(fontSize: 15, color: Colors.green)),
                    Text("-${_formatCurrency(_discountAmount)}", style: const TextStyle(fontSize: 15, color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Divider(height: 16),
            ],

            //  NÚT THANH TOÁN (hiển thị giá cuối)
            _isProcessing
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handlePlaceOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Thanh toán $totalFormatted", // Dùng giá cuối
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  /// WIDGET MỚI ĐỂ HIỂN THỊ Ô NHẬP COUPON
  Widget _buildCouponSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nếu CHƯA áp dụng mã
          if (_appliedCoupon == null)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: "🎁 Nhập mã giảm giá",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero
                    ),
                  ),
                ),
                _isCheckingCoupon
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3)),
                      )
                    : TextButton(
                        onPressed: _applyCoupon,
                        child: const Text("Áp dụng"),
                      ),
              ],
            ),
          // Nếu ĐÃ áp dụng mã thành công
          if (_appliedCoupon != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle, color: Colors.green, size: 28),
              title: Text("Đã áp dụng mã: ${_appliedCoupon!.id}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              subtitle: Text(
                  "Bạn được giảm ${_appliedCoupon!.discountPercentage}%"),
              trailing: IconButton(
                icon: const Icon(Icons.close, color: Colors.red, size: 20),
                tooltip: "Xóa mã",
                onPressed: _removeCoupon, // Nút xóa mã
              ),
            ),
          // Hiển thị lỗi (nếu có)
          if (_couponError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _couponError!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  // (Hàm _buildPaymentOption giữ nguyên)
  Widget _buildPaymentOption(String value, String title, String iconPath) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              _paymentMethod == value ? Colors.deepPurple : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: RadioListTile(
        value: value,
        groupValue: _paymentMethod,
        onChanged: (val) => setState(() => _paymentMethod = val!),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        title: Row(
          children: [
            Image.asset(iconPath, width: 32, height: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}