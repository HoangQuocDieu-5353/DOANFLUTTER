class ReviewModel {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final String comment;
  final double rating;
  final DateTime createdAt;
  final String? userAvatarUrl; 
  final bool isApproved; 

  ReviewModel({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.comment,
    required this.rating,
    required this.createdAt,
    this.userAvatarUrl,
    this.isApproved = true, 
  });

  factory ReviewModel.fromMap(Map<dynamic, dynamic> map) {
    return ReviewModel(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Người dùng',
      comment: map['comment'] ?? '',
      rating: (map['rating'] is int)
          ? (map['rating'] as int).toDouble()
          : (map['rating'] ?? 0.0),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      userAvatarUrl: map['userAvatarUrl'],
      isApproved: map['isApproved'] ?? false, 
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'comment': comment,
      'rating': rating,
      'createdAt': createdAt.toIso8601String(),
      'userAvatarUrl': userAvatarUrl,
      'isApproved': isApproved, 
    };
  }

  ReviewModel copyWith({
    String? id,
    String? productId,
    String? userId,
    String? userName,
    String? comment,
    double? rating,
    DateTime? createdAt,
    String? userAvatarUrl,
    bool? isApproved,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      comment: comment ?? this.comment,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      isApproved: isApproved ?? this.isApproved,
    );
  }
}
