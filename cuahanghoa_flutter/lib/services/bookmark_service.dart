import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cuahanghoa_flutter/models/product_model.dart';
import 'package:cuahanghoa_flutter/models/bookmark_model.dart';

class BookmarkService {
  final _db = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;

  ///  Lấy danh sách bookmark (toàn bộ sản phẩm user đã lưu)
  Future<List<ProductModel>> fetchBookmarks() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final bookmarkRef = _db.child('bookmarks/${user.uid}');
    final productsRef = _db.child('products');

    final snapshot = await bookmarkRef.get();
    if (!snapshot.exists) return [];

    final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
    final ids = data.keys.toList();

    final List<ProductModel> products = [];

    for (var pid in ids) {
      final pSnap = await productsRef.child(pid).get();
      if (pSnap.exists) {
        final pData = Map<dynamic, dynamic>.from(pSnap.value as Map);
        products.add(ProductModel.fromMap(pData, pid));
      }
    }

    return products;
  }

  ///  Thêm sản phẩm vào bookmark
  Future<void> addBookmark(String productId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.child('bookmarks/${user.uid}/$productId').set(true);
  }

  ///  Xóa sản phẩm khỏi bookmark
  Future<void> removeBookmark(String productId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.child('bookmarks/${user.uid}/$productId').remove();
  }

  ///  Kiểm tra sản phẩm có đang được bookmark hay không
  Future<bool> isBookmarked(String productId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final snapshot =
        await _db.child('bookmarks/${user.uid}/$productId').get();
    return snapshot.exists;
  }

  ///  Lấy BookmarkModel thô (nếu bạn cần dùng model)
  Future<BookmarkModel?> fetchBookmarkModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final bookmarkRef = _db.child('bookmarks/${user.uid}');
    final snapshot = await bookmarkRef.get();

    if (!snapshot.exists) return BookmarkModel(userId: user.uid, productIds: []);

    final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
    return BookmarkModel.fromMap(data, user.uid);
  }
}
