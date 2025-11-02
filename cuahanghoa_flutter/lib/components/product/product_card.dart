import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants.dart';
import '../network_image_with_loader.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.image,
    required this.brandName,
    required this.title,
    required this.price,
    this.priceAfterDiscount,
    this.discountPercent,
    required this.press,
    required this.onAddToCart,
  });

  final String image, brandName, title;
  final double price;
  final double? priceAfterDiscount;
  final int? discountPercent;
  final VoidCallback press;
  final VoidCallback onAddToCart;

  String formatCurrency(double value) {
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return format.format(value);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 300,
      child: OutlinedButton(
        onPressed: press,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(defaultBorderRadious),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼 Ảnh sản phẩm
            AspectRatio(
              aspectRatio: 1.15,
              child: Stack(
                children: [
                  NetworkImageWithLoader(image, radius: defaultBorderRadious),
                  if (discountPercent != null && discountPercent! > 0)
                    Positioned(
                      right: defaultPadding / 2,
                      top: defaultPadding / 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: defaultPadding / 2,
                        ),
                        height: 18,
                        decoration: const BoxDecoration(
                          color: errorColor,
                          borderRadius: BorderRadius.all(
                            Radius.circular(defaultBorderRadious),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            "-$discountPercent%",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 6),
            Text(
              brandName.toUpperCase(),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(fontSize: 10, color: Colors.grey[700]),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall!
                  .copyWith(fontSize: 12),
            ),
            const Spacer(),

            // 💰 Giá + giỏ hàng
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                (priceAfterDiscount != null && priceAfterDiscount! < price)
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatCurrency(price),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          Text(
                            formatCurrency(priceAfterDiscount!),
                            style: const TextStyle(
                              color: Color(0xFF31B0D8),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        formatCurrency(price),
                        style: const TextStyle(
                          color: Color(0xFF31B0D8),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                IconButton(
                  icon: const Icon(
                    Icons.add_shopping_cart_outlined,
                    size: 18,
                    color: Color(0xFF31B0D8),
                  ),
                  onPressed: onAddToCart,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
