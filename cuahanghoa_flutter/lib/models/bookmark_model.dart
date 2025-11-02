class BookmarkModel {
  final String userId;
  final List<String> productIds;

  BookmarkModel({
    required this.userId,
    required this.productIds,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    for (var id in productIds) {
      map[id] = true; 
    }
    return map;
  }

  factory BookmarkModel.fromMap(Map<dynamic, dynamic> map, String userId) {
    return BookmarkModel(
      userId: userId,
      productIds: map.keys.map((key) => key.toString()).toList(),
    );
  }
}
