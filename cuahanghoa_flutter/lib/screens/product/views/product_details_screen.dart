import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cuahanghoa_flutter/models/product_model.dart';
import 'package:cuahanghoa_flutter/models/cart_item.dart';
import 'package:cuahanghoa_flutter/models/review_model.dart';
import 'package:cuahanghoa_flutter/services/product_service.dart';
import 'package:cuahanghoa_flutter/services/review_service.dart';
import 'package:cuahanghoa_flutter/services/cart_service.dart';
import 'package:cuahanghoa_flutter/services/bookmark_service.dart';
import 'package:cuahanghoa_flutter/screens/reviews/view/product_reviews_screen.dart';
import 'package:cuahanghoa_flutter/screens/checkout/views/checkout_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final String? userName;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.userName,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductService _productService = ProductService();
  final ReviewService _reviewService = ReviewService();
  final CartService _cartService = CartService();
  final BookmarkService _bookmarkService = BookmarkService();

  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  ProductModel? _product;
  bool _isLoading = true;
  String? _error;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _loadProduct();
    _checkBookmarkStatus();
  }

  Future<void> _checkBookmarkStatus() async {
    if (_currentUserId == null) return;
    final isSaved = await _bookmarkService.isBookmarked(widget.productId);
    if (!mounted) return;
    setState(() => _isBookmarked = isSaved);
  }

  Future<void> _toggleBookmark() async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng đăng nhập để yêu thích 💖")),
      );
      return;
    }

    setState(() => _isBookmarked = !_isBookmarked);

    if (_isBookmarked) {
      await _bookmarkService.addBookmark(widget.productId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã thêm vào danh sách yêu thích 💖")),
      );
    } else {
      await _bookmarkService.removeBookmark(widget.productId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã xóa khỏi danh sách yêu thích 💔")),
      );
    }
  }

  Future<void> _loadProduct() async {
    try {
      final product =
          await _productService.getProductById(widget.productId.trim());
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (product == null) {
          _error = 'Không tìm thấy sản phẩm.';
        } else {
          _product = product;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Lỗi khi tải sản phẩm: $e';
      });
    }
  }

  String _formatPrice(double price) {
    final formatted = price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$formatted ₫';
  }

  Widget _buildWriteReviewButton(BuildContext context, String productId) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          if (_currentUserId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Vui lòng đăng nhập để viết đánh giá 📝"),
              ),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductReviewsScreen(productId: productId),
            ),
          );
        },
        icon: const Icon(Icons.rate_review_outlined, color: Color(0xFF31B0D8)),
        label: Text(
          "Viết đánh giá",
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF31B0D8),
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: const BorderSide(color: Color(0xFF31B0D8)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.inter();

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết sản phẩm')),
        body: Center(child: Text(_error!, style: textStyle)),
      );
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết sản phẩm')),
        body: Center(
          child: Text('Không tìm thấy dữ liệu sản phẩm.', style: textStyle),
        ),
      );
    }

    final product = _product!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          product.name,
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.favorite : Icons.favorite_border,
              color: _isBookmarked ? Colors.redAccent : Colors.grey[600],
            ),
            onPressed: _toggleBookmark,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: DefaultTextStyle(
          style: textStyle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Center(
                child: Hero(
                  tag: product.id,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      product.imageUrl,
                      width: double.infinity,
                      height: 280,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: double.infinity,
                        height: 280,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image,
                            size: 100, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                product.name,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatPrice(product.price),
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF31B0D8),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 20),

              // 📖 Mô tả
              Text(
                "Mô tả",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.description.isNotEmpty
                    ? product.description
                    : "Chưa có mô tả cho sản phẩm này.",
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              const Divider(height: 20),

              //  Đánh giá realtime
              Text(
                "Đánh giá & Nhận xét",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),

              StreamBuilder<List<ReviewModel>>(
                stream: _reviewService.streamReviews(widget.productId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final allReviews = snapshot.data!;
                  final reviews =
                      allReviews.where((r) => r.isApproved == true).toList();

                  if (reviews.isEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Chưa có đánh giá nào được duyệt cho sản phẩm này.",
                          style: GoogleFonts.inter(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 12),
                        _buildWriteReviewButton(context, product.id),
                      ],
                    );
                  }

                  final totalRating =
                      reviews.fold<double>(0, (sum, r) => sum + r.rating);
                  final avg = totalRating / reviews.length;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star,
                              color: Colors.amber[700], size: 22),
                          const SizedBox(width: 4),
                          Text(
                            avg.toStringAsFixed(1),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${reviews.length} đánh giá)',
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductReviewsScreen(
                                      productId: product.id),
                                ),
                              );
                            },
                            child: Text(
                              "Xem tất cả",
                              style: GoogleFonts.inter(
                                color: const Color(0xFF31B0D8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildWriteReviewButton(context, product.id),
                    ],
                  );
                },
              ),

              const SizedBox(height: 30),

              // 🛒 Nút hành động
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (_currentUserId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text("Vui lòng đăng nhập để thêm vào giỏ 🛒")),
                          );
                          return;
                        }

                        final item = CartItem(
                          id: product.id,
                          name: product.name,
                          price: product.price,
                          quantity: 1,
                          imageUrl: product.imageUrl,
                        );

                        await _cartService.addToCart(item);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Đã thêm vào giỏ hàng 🛒"),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_shopping_cart_outlined),
                      label: const Text(
                        'Thêm vào giỏ',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF31B0D8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        if (_currentUserId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text("Vui lòng đăng nhập để mua ngay 🛍️")),
                          );
                          return;
                        }

                        final item = CartItem(
                          id: product.id,
                          name: product.name,
                          price: product.price,
                          quantity: 1,
                          imageUrl: product.imageUrl,
                        );

                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CheckoutScreen(
                              cartItems: [item],
                              totalPrice: item.price.toInt(),
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF31B0D8)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Mua ngay',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF31B0D8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
