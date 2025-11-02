import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cuahanghoa_flutter/screens/checkout/views/cart_screen.dart';
import 'package:cuahanghoa_flutter/services/cart_service.dart';

class ShoppingBag extends StatelessWidget {
  const ShoppingBag({
    super.key,
    this.color,
  });

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final cartService = CartService();

    return StreamBuilder<DatabaseEvent>(
      stream: user != null ? cartService.getCartStream() : const Stream.empty(),
      builder: (context, snapshot) {
        int itemCount = 0;

        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          itemCount = data.length;
        }

        return IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartScreen()),
            );
          },
          icon: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              SvgPicture.asset(
                itemCount == 0
                    ? "assets/icons/Bag.svg"
                    : "assets/icons/bag_full.svg",
                height: 24,
                width: 24,
                colorFilter: ColorFilter.mode(
                  color ?? Theme.of(context).iconTheme.color!,
                  BlendMode.srcIn,
                ),
              ),
              if (itemCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      itemCount.toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
