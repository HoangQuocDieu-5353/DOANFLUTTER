import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cuahanghoa_flutter/components/product/product_card.dart';
import 'package:cuahanghoa_flutter/models/product_model.dart';
import 'package:cuahanghoa_flutter/models/cart_item.dart';
import 'package:cuahanghoa_flutter/services/product_service.dart';
import 'package:cuahanghoa_flutter/services/cart_service.dart';
import 'package:cuahanghoa_flutter/constants.dart';
import 'package:cuahanghoa_flutter/route/route_constants.dart';

class MostPopular extends StatelessWidget {
  const MostPopular({super.key});

  @override
  Widget build(BuildContext context) {
    final productService = ProductService();
    final cartService = CartService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: defaultPadding / 2),

        // Tiêu đề — hòa quyện giữa sắc tím và cảm giác premium
        Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Text(
            "🔥 Phổ biến nhất",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: Colors.deepPurple.shade700,
            ),
          ),
        ),

        //  StreamBuilder lắng nghe realtime data từ Firebase
        SizedBox(
          height: 260,
          child: StreamBuilder<List<ProductModel>>(
            stream: productService.getPopularProducts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "⚠️ Lỗi tải dữ liệu: ${snapshot.error}",
                    style: GoogleFonts.roboto(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }

              final products = snapshot.data ?? [];

              if (products.isEmpty) {
                return Center(
                  child: Text(
                    "Chưa có sản phẩm nổi bật 🥲",
                    style: GoogleFonts.roboto(
                      color: Colors.grey,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      left: defaultPadding,
                      right: index == products.length - 1 ? defaultPadding : 0,
                    ),
                    child: ProductCard(
                      image: product.imageUrl,
                      brandName: product.category,
                      title: product.name,
                      price: product.price,
                      priceAfterDiscount: product.price,
                      discountPercent: 0,
                      press: () {
                        Navigator.pushNamed(
                          context,
                          productDetailsScreenRoute,
                          arguments: product.id,
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
                              '✅ ${product.name} đã được thêm vào giỏ hàng!',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            backgroundColor: Colors.deepPurple.shade400,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
