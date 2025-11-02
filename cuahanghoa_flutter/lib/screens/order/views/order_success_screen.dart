import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:cuahanghoa_flutter/entry_point.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/lottie/success.json',
                  repeat: false,
                  width: 200,
                ),
                const SizedBox(height: 30),

                //  Tiêu đề chính
                Text(
                  "Thanh toán thành công",
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade700,
                    fontFamily: 'Roboto', 
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                //  Mô tả phụ
                Text(
                  "🎉 Cảm ơn bạn đã mua hàng!\nĐơn hàng đang được xử lý và sẽ sớm được giao đến bạn.",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade700,
                    fontSize: 16,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),

                //  Nút quay lại trang chủ
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const EntryPoint(),
                          transitionsBuilder: (_, anim, __, child) =>
                              FadeTransition(opacity: anim, child: child),
                        ),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.home_rounded, size: 22),
                    label: const Text(
                      "Quay về Trang chủ",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                      shadowColor: Colors.deepPurpleAccent.withOpacity(0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
