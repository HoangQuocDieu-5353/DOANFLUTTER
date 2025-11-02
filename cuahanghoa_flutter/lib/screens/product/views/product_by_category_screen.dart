import 'package:flutter/material.dart';
import 'package:cuahanghoa_flutter/models/product_model.dart';
import 'package:cuahanghoa_flutter/services/product_service.dart';
import 'package:cuahanghoa_flutter/components/product/product_card.dart';
import 'package:cuahanghoa_flutter/constants.dart';
import 'package:cuahanghoa_flutter/route/route_constants.dart';

class ProductByCategoryScreen extends StatelessWidget {
  final String categoryName;

  const ProductByCategoryScreen({
    super.key,
    required this.categoryName,
  });

  void _handleAddToCart(BuildContext context, ProductModel product) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🛒 Đã thêm "${product.name}" vào giỏ hàng'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productService = ProductService();

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
        backgroundColor: primaryColor,
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: productService.getProductsByCategory(categoryName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Lỗi tải sản phẩm: ${snapshot.error}"));
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return const Center(child: Text("Không có sản phẩm nào trong danh mục này."));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(defaultPadding),
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
                  Navigator.pushNamed(
                    context,
                    productDetailsScreenRoute,
                    arguments: product.id,
                  );
                },
                onAddToCart: () => _handleAddToCart(context, product),
              );
            },
          );
        },
      ),
    );
  }
}
