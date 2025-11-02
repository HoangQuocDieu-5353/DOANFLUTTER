import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cuahanghoa_flutter/services/user_service.dart';
import 'package:cuahanghoa_flutter/models/user_model.dart';
import 'package:cuahanghoa_flutter/services/review_service.dart';
import 'package:cuahanghoa_flutter/models/review_model.dart';

class ProductReviewsScreen extends StatefulWidget {
  final String productId;

  const ProductReviewsScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductReviewsScreen> createState() => _ProductReviewsScreenState();
}

class _ProductReviewsScreenState extends State<ProductReviewsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  double _rating = 0;
  final ReviewService _reviewService = ReviewService();

  final UserService _userService = UserService();
  final _auth = FirebaseAuth.instance;
  UserModel? _currentUserModel;
  bool _isLoadingUser = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final userModel = await _userService.getUser(user.uid);
        if (mounted) {
          setState(() {
            _currentUserModel = userModel;
            _isLoadingUser = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoadingUser = false);
      }
    } else {
      if (mounted) setState(() => _isLoadingUser = false);
    }
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate() || _rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn số sao và nhập nội dung")),
      );
      return;
    }

    if (_currentUserModel == null || _auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không tìm thấy thông tin người dùng.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final reviewId = "${widget.productId}_${_auth.currentUser!.uid}";

    final review = ReviewModel(
      id: reviewId,
      productId: widget.productId,
      userId: _auth.currentUser!.uid,
      rating: _rating,
      comment: _commentController.text.trim(),
      userName: _currentUserModel!.name,
      userAvatarUrl: _currentUserModel!.avatarUrl ?? '',
      createdAt: DateTime.now(),
      isApproved: true,
    );

    try {
      await _reviewService.addReview(review);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gửi đánh giá thành công!"),
          ),
        );
        _commentController.clear();
        setState(() => _rating = 0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi khi gửi: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Đánh giá sản phẩm",
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoadingUser
          ? const Center(child: CircularProgressIndicator())
          : _buildReviewPage(),
    );
  }

  Widget _buildReviewPage() {
    if (_currentUserModel == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Vui lòng đăng nhập để gửi đánh giá.",
            style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            "Đánh giá của bạn:",
            style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
                onPressed: () => setState(() => _rating = index + 1.0),
              );
            }),
          ),
          const SizedBox(height: 12),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Viết đánh giá của bạn...",
                labelStyle: GoogleFonts.inter(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? "Vui lòng nhập nội dung" : null,
            ),
          ),
          const SizedBox(height: 20),
          _isSubmitting
              ? const CircularProgressIndicator()
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF31B0D8),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Gửi đánh giá",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
          const SizedBox(height: 30),
          const Divider(),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<List<ReviewModel>>(
              stream: _reviewService.streamReviews(widget.productId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      "Chưa có đánh giá nào.",
                      style: GoogleFonts.inter(color: Colors.grey[700]),
                    ),
                  );
                }

                final reviews = snapshot.data!;

                return ListView.separated(
                  itemCount: reviews.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final r = reviews[index];
                    final hasAvatar =
                        r.userAvatarUrl != null && r.userAvatarUrl!.isNotEmpty;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF31B0D8),
                        backgroundImage:
                            hasAvatar ? NetworkImage(r.userAvatarUrl!) : null,
                        child: !hasAvatar
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      title: Text(
                        r.userName,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.black,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(5, (i) {
                              return Icon(
                                i < r.rating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 18,
                              );
                            }),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            r.comment,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      trailing: Text(
                        "${r.createdAt.day}/${r.createdAt.month}/${r.createdAt.year}",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
