import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import '../models/review_model.dart';

class ReviewService {
  final DatabaseReference _reviewRef =
      FirebaseDatabase.instance.ref().child('reviews');

  ///  Thêm đánh giá mới
  Future<void> addReview(ReviewModel review) async {
    final id = const Uuid().v4(); // Tạo ID ngẫu nhiên
    final newReview = review.copyWith(id: id);

    await _reviewRef.child(review.productId).child(id).set(newReview.toMap());
  }

  ///  Lấy danh sách đánh giá 1 lần (chỉ review đã duyệt)
  Future<List<ReviewModel>> getReviews(String productId,
      {bool onlyApproved = true}) async {
    final snapshot = await _reviewRef.child(productId).get();
    if (!snapshot.exists) return [];

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final reviews = data.values
        .map((e) => ReviewModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    // Lọc chỉ những review đã duyệt nếu cần
    if (onlyApproved) {
      return reviews.where((r) => r.isApproved).toList();
    }
    return reviews;
  }

  ///  Stream review theo thời gian thực
  Stream<List<ReviewModel>> streamReviews(String productId,
      {bool onlyApproved = true}) {
    return _reviewRef.child(productId).onValue.map((event) {
      if (event.snapshot.value == null) return <ReviewModel>[];

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final reviews = data.values
          .map((e) => ReviewModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();

      if (onlyApproved) {
        return reviews.where((r) => r.isApproved).toList();
      }
      return reviews;
    });
  }
  ///  Lấy tất cả review (mọi sản phẩm, mọi trạng thái)
Future<List<ReviewModel>> getAllReviews() async {
  final snapshot = await _reviewRef.get();
  if (!snapshot.exists) return [];

  List<ReviewModel> all = [];

  for (final product in snapshot.children) {
    final productReviews = Map<String, dynamic>.from(product.value as Map);
    for (final review in productReviews.values) {
      all.add(ReviewModel.fromMap(Map<String, dynamic>.from(review as Map)));
    }
  }

  return all;
}


  ///  Cập nhật trạng thái duyệt (Admin dùng)
  Future<void> setApproval({
    required String productId,
    required String reviewId,
    required bool isApproved,
  }) async {
    await _reviewRef
        .child(productId)
        .child(reviewId)
        .update({'isApproved': isApproved});
  }

  ///  Xoá review (Admin hoặc chủ review)
  Future<void> deleteReview(String productId, String reviewId) async {
    await _reviewRef.child(productId).child(reviewId).remove();
  }

  ///  Lấy tất cả review chưa duyệt (cho Admin)
  Future<List<ReviewModel>> getPendingReviews() async {
    final snapshot = await _reviewRef.get();
    if (!snapshot.exists) return [];

    List<ReviewModel> pending = [];

    for (final product in snapshot.children) {
      final productReviews = Map<String, dynamic>.from(product.value as Map);
      for (final review in productReviews.values) {
        final reviewObj =
            ReviewModel.fromMap(Map<String, dynamic>.from(review as Map));
        if (!reviewObj.isApproved) pending.add(reviewObj);
      }
    }
    return pending;
  }
}
