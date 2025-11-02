import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pay/pay.dart';
import 'package:cuahanghoa_flutter/config/payment_config.dart';

class PayScreen extends StatefulWidget {
  final double totalPrice;
  final Function(Map<String, dynamic> result) onPaymentSuccess;

  const PayScreen({
    super.key,
    required this.totalPrice,
    required this.onPaymentSuccess,
  });

  @override
  State<PayScreen> createState() => _PayScreenState();
}

class _PayScreenState extends State<PayScreen> {
  late final List<PaymentItem> _paymentItems;

  @override
  void initState() {
    super.initState();
    _paymentItems = [
      PaymentItem(
        label: 'Tổng thanh toán',
        // Google Pay yêu cầu giá trị kiểu String có dạng số (không có dấu . hoặc ,)
        amount: widget.totalPrice.toStringAsFixed(0),
        status: PaymentItemStatus.final_price,
      ),
    ];
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return "${formatter.format(amount)} VNĐ";
  }

  @override
  Widget build(BuildContext context) {
    final formattedTotal = _formatCurrency(widget.totalPrice);

    final payButton = Platform.isIOS
        ? ApplePayButton(
            paymentConfiguration:
                PaymentConfiguration.fromJsonString(defaultApplePay),
            paymentItems: _paymentItems,
            style: ApplePayButtonStyle.black,
            type: ApplePayButtonType.buy,
            width: double.infinity,
            height: 50,
            margin: const EdgeInsets.only(top: 10),
            onPaymentResult: (result) {
              debugPrint('✅ Apple Pay success: $result');
              widget.onPaymentSuccess(result);
            },
            loadingIndicator: const Center(child: CircularProgressIndicator()),
          )
        : Container(
            margin: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: GooglePayButton(
              paymentConfiguration:
                  PaymentConfiguration.fromJsonString(defaultGooglePayVND),
              paymentItems: _paymentItems,
              type: GooglePayButtonType.pay,
              width: double.infinity,
              height: 55,
              margin: EdgeInsets.zero,
              onPaymentResult: (result) {
                debugPrint('✅ Google Pay success: $result');
                widget.onPaymentSuccess(result);
              },
              loadingIndicator:
                  const Center(child: CircularProgressIndicator()),
            ),
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Thanh toán đơn hàng"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Phương thức thanh toán: Google Pay / Apple Pay",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              "Tổng tiền cần thanh toán:",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              formattedTotal,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 24),
            payButton,
          ],
        ),
      ),
    );
  }
}
