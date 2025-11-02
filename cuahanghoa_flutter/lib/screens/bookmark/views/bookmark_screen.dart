import 'package:flutter/material.dart';
import 'package:cuahanghoa_flutter/components/product/product_card.dart';
import 'package:cuahanghoa_flutter/models/product_model.dart';
import 'package:cuahanghoa_flutter/route/route_constants.dart';
import 'package:cuahanghoa_flutter/constants.dart';
import 'package:cuahanghoa_flutter/services/bookmark_service.dart';
import 'package:cuahanghoa_flutter/services/cart_service.dart';
import 'package:cuahanghoa_flutter/models/cart_item.dart'; 
class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  final _bookmarkService = BookmarkService();
  final _cartService = CartService();

  List<ProductModel> _bookmarkedProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    try {
      final products = await _bookmarkService.fetchBookmarks();
      setState(() {
        _bookmarkedProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Lỗi khi tải bookmark: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAddToCart(ProductModel product) async {
    try {
      final cartItem = CartItem(
        id: product.id,
        name: product.name,
        price: product.price,
        imageUrl: product.imageUrl,
        quantity: 1,
      );

      await _cartService.addToCart(cartItem);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Đã thêm "${product.name}" vào giỏ hàng')),
      );
    } catch (e) {
      debugPrint('❌ Lỗi khi thêm vào giỏ: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi khi thêm vào giỏ hàng')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sản phẩm yêu thích'),
        backgroundColor: primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookmarkedProducts.isEmpty
              ? const Center(child: Text('Chưa có sản phẩm yêu thích'))
              : CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: defaultPadding,
                        vertical: defaultPadding,
                      ),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200.0,
                          mainAxisSpacing: defaultPadding,
                          crossAxisSpacing: defaultPadding,
                          childAspectRatio: 0.66,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (BuildContext context, int index) {
                            final product = _bookmarkedProducts[index];
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
                              onAddToCart: () => _handleAddToCart(product),
                            );
                          },
                          childCount: _bookmarkedProducts.length,
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
