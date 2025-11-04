import 'package:flutter/material.dart';
import 'package:cuahanghoa_flutter/models/product_model.dart';
import 'package:cuahanghoa_flutter/models/cart_item.dart';
import 'package:cuahanghoa_flutter/services/product_service.dart';
import 'package:cuahanghoa_flutter/services/cart_service.dart';
import 'package:cuahanghoa_flutter/components/product/product_card.dart';
import 'package:cuahanghoa_flutter/constants.dart';
import 'package:cuahanghoa_flutter/screens/product/views/product_details_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class AllProductsList extends StatelessWidget {
  const AllProductsList({super.key});

  @override
  Widget build(BuildContext context) {
    final productService = ProductService();
    final cartService = CartService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: defaultPadding / 2),
        Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Text(
            "🌸 Tất cả sản phẩm",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.deepPurple.shade700,
              letterSpacing: 0.5,
            ),
          ),
        ),

        // Stream sản phẩm realtime
        StreamBuilder<List<ProductModel>>(
          stream: productService.getAllProducts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  "⚠️ Lỗi khi tải dữ liệu sản phẩm",
                  style: GoogleFonts.poppins(
                    color: Colors.redAccent,
                    fontSize: 14,
                  ),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  "Chưa có sản phẩm nào 🥲",
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              );
            }

            final products = snapshot.data!;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: defaultPadding,
                crossAxisSpacing: defaultPadding,
                childAspectRatio: 0.7,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];

                return ProductCard(
                  image: product.imageUrl,
                  brandName: product.category,
                  title: product.name,
                  price: product.price,
                  priceAfterDiscount: product.price,
                  discountPercent: 0,
                  press: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailScreen(productId: product.id),
                      ),
                    );
                  },
                  onAddToCart: () async {
                    final item = CartItem(
                      id: product.id,
                      name: product.name,
                      price: product.price,
                      quantity: 1,
                      imageUrl: product.imageUrl,
                    );

                    await cartService.addToCart(item);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "✅ ${product.name} đã được thêm vào giỏ hàng",
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}
