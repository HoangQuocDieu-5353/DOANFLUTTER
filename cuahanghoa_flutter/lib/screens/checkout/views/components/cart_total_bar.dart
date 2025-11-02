import 'package:flutter/material.dart';

class CartTotalBar extends StatelessWidget {
  final double total;
  final VoidCallback onCheckout;

  const CartTotalBar({
    super.key,
    required this.total,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, -2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Tổng: ${total.toStringAsFixed(0)} ₫',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: onCheckout,
            child: const Text('Thanh toán'),
          ),
        ],
      ),
    );
  }
}
