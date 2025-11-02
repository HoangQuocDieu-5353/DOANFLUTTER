import 'package:flutter/material.dart';
import 'package:cuahanghoa_flutter/models/review_model.dart';
import 'package:cuahanghoa_flutter/services/review_service.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class ReviewManagementScreen extends StatefulWidget {
  const ReviewManagementScreen({super.key});

  @override
  State<ReviewManagementScreen> createState() => _ReviewManagementScreenState();
}

class _ReviewManagementScreenState extends State<ReviewManagementScreen>
    with SingleTickerProviderStateMixin {
  final ReviewService _reviewService = ReviewService();

  // Điều khiển chuyển đổi giữa 2 tab (Hiển thị / Đã ẩn)
  late TabController _tabController;

  // Danh sách review theo trạng thái
  List<ReviewModel> visibleReviews = [];
  List<ReviewModel> hiddenReviews = [];

  // Biến trạng thái hiển thị vòng tròn loading
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    // Khởi tạo controller cho 2 tab
    _tabController = TabController(length: 2, vsync: this);

    // Cập nhật lại UI khi người dùng đổi tab
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    // Tải dữ liệu ban đầu
    loadData();
  }

  // Lấy toàn bộ review và phân loại theo trạng thái (hiển thị / ẩn)
  Future<void> loadData() async {
    setState(() => isLoading = true);
    final all = await _reviewService.getAllReviews();

    setState(() {
      visibleReviews = all.where((r) => r.isApproved).toList();
      hiddenReviews = all.where((r) => !r.isApproved).toList();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isHiddenTab = _tabController.index == 1; // Kiểm tra tab hiện tại

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          "Quản lý đánh giá",
          style: GoogleFonts.poppins(
            fontSize: 18,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),

        // Thanh tab chuyển đổi giữa “Hiển thị” và “Đã ẩn”
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          unselectedLabelColor: Colors.grey,
          labelColor: Colors.green.shade700,
          indicatorColor: Colors.green.shade700,
          tabs: const [
            Tab(text: "Hiển thị"),
            Tab(text: "Đã ẩn"),
          ],
        ),
      ),

      // Hiển thị vòng tròn loading khi đang tải dữ liệu
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Danh sách review đang hiển thị
                _buildReviewList(visibleReviews, isHiddenTab: false),

                // Danh sách review đã bị ẩn
                _buildReviewList(hiddenReviews, isHiddenTab: true),
              ],
            ),
    );
  }

  // Xây dựng danh sách review (có thể là hiển thị hoặc đã ẩn)
  Widget _buildReviewList(List<ReviewModel> list, {required bool isHiddenTab}) {
    if (list.isEmpty) {
      // Khi danh sách rỗng
      return Center(
        child: Text(
          "Không có đánh giá nào",
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: Colors.grey.shade600,
          ),
        ),
      );
    }

    // Cho phép kéo xuống để reload dữ liệu
    return RefreshIndicator(
      onRefresh: loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final review = list[index];

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),

            // Hiển thị từng review
            child: ListTile(
              // Ảnh đại diện người dùng (nếu có)
              leading: CircleAvatar(
                radius: 25,
                backgroundImage: review.userAvatarUrl != null
                    ? NetworkImage(review.userAvatarUrl!)
                    : null,
                child: review.userAvatarUrl == null
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null,
              ),

              // Tên người dùng và số sao đánh giá
              title: Text(
                "${review.userName} ⭐ ${review.rating.toStringAsFixed(1)}",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),

              // Nội dung comment và thời gian tạo
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  "${review.comment}\n🕒 ${DateFormat('dd/MM/yyyy HH:mm').format(review.createdAt)}",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ),

              // Các hành động quản lý review (ẩn / hiện lại / xóa)
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nút chuyển đổi trạng thái hiển thị
                  IconButton(
                    icon: Icon(
                      isHiddenTab ? Icons.visibility : Icons.visibility_off,
                      color: isHiddenTab ? Colors.blue : Colors.orange,
                    ),
                    tooltip: isHiddenTab ? "Hiện lại" : "Ẩn review",
                    onPressed: () async {
                      await _reviewService.setApproval(
                        productId: review.productId,
                        reviewId: review.id,
                        isApproved: !review.isApproved,
                      );
                      await loadData();
                    },
                  ),

                  // Nút xóa review khỏi hệ thống
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: "Xóa review",
                    onPressed: () async {
                      await _reviewService.deleteReview(
                        review.productId,
                        review.id,
                      );
                      await loadData();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
