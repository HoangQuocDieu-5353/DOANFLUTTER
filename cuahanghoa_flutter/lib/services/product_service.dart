import 'package:firebase_database/firebase_database.dart';
import '../models/product_model.dart';

class ProductService {
  //  Node "products" trong Realtime Database
  final DatabaseReference _ref = FirebaseDatabase.instance.ref('products');

  ///  Thêm hoặc cập nhật sản phẩm
  Future<void> addOrUpdateProduct(ProductModel product) async {
    await _ref.child(product.id).set(product.toMap());
  }
  ///  Lấy tất cả sản phẩm (Realtime stream)
  Stream<List<ProductModel>> getAllProducts() {
    return _ref.onValue.map((DatabaseEvent event) {
      final data = event.snapshot.value;
      if (data == null) return [];

      final Map<dynamic, dynamic> map = data as Map<dynamic, dynamic>;
      return map.entries.map((e) {
        return ProductModel.fromMap(Map<String, dynamic>.from(e.value), e.key);
      }).toList();
    });
  }

  ///  Lấy danh sách sản phẩm "Best Seller"
  Stream<List<ProductModel>> getBestSellerProducts() {
    return _ref.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];

      final Map<dynamic, dynamic> map = data as Map<dynamic, dynamic>;
      return map.entries
          .map((e) => ProductModel.fromMap(Map<String, dynamic>.from(e.value), e.key))
          .where((p) => p.isBestSeller)
          .toList();
    });
  }

  ///  Lấy danh sách sản phẩm "Most Popular"
  Stream<List<ProductModel>> getPopularProducts() {
    return _ref.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];

      final Map<dynamic, dynamic> map = data as Map<dynamic, dynamic>;
      return map.entries
          .map((e) => ProductModel.fromMap(Map<String, dynamic>.from(e.value), e.key))
          .where((p) => p.isPopular)
          .toList();
    });
  }

  ///  Lấy danh sách sản phẩm mới
  Stream<List<ProductModel>> getNewProducts() {
    return _ref.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];

      final Map<dynamic, dynamic> map = data as Map<dynamic, dynamic>;
      return map.entries
          .map((e) => ProductModel.fromMap(Map<String, dynamic>.from(e.value), e.key))
          .where((p) => p.isNew)
          .toList();
    });
  }

  ///  Lấy thông tin 1 sản phẩm
  Future<ProductModel?> getProductById(String id) async {
    final snapshot = await _ref.child(id).get();
    if (!snapshot.exists) return null;

    final data = snapshot.value as Map<dynamic, dynamic>;
    return ProductModel.fromMap(Map<String, dynamic>.from(data), id);
  }

  ///  Xóa sản phẩm
  Future<void> deleteProduct(String id) async {
    await _ref.child(id).remove();
  }

  ///  Tìm kiếm 
  Future<List<ProductModel>> searchProducts(String query) async {
    final snapshot = await _ref.get();
    if (!snapshot.exists) return [];

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final allProducts = data.entries
        .map((e) => ProductModel.fromMap(Map<String, dynamic>.from(e.value), e.key))
        .toList();

    return allProducts
        .where((p) =>
            p.name.toLowerCase().contains(query.toLowerCase()) ||
            p.category.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  ///  Gợi ý tìm kiếm 
  Stream<List<ProductModel>> searchSuggestions(String query) {
    if (query.isEmpty) {
      // Trả về danh sách trống khi chưa nhập gì
      return Stream.value([]);
    }

    final endQuery = '$query\uf8ff';
    final queryRef = _ref.orderByChild('name').startAt(query).endAt(endQuery);

    return queryRef.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];

      final Map<dynamic, dynamic> map = data as Map<dynamic, dynamic>;
      return map.entries
          .map((e) => ProductModel.fromMap(Map<String, dynamic>.from(e.value), e.key))
          .toList();
    });
  }
    ///  Lấy danh sách sản phẩm theo danh mục (Realtime)
  Stream<List<ProductModel>> getProductsByCategory(String categoryName) {
    return _ref.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];

      final Map<dynamic, dynamic> map = data as Map<dynamic, dynamic>;
      return map.entries
          .map((e) => ProductModel.fromMap(Map<String, dynamic>.from(e.value), e.key))
          .where((p) => p.category.toLowerCase() == categoryName.toLowerCase())
          .toList();
    });
  }
  /// Sắp xếp danh sách sản phẩm 
  List<ProductModel> sortProducts(List<ProductModel> products, String sortType) {
    final sorted = List<ProductModel>.from(products);

    switch (sortType) {
      case 'price_low_to_high':
        sorted.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high_to_low':
        sorted.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'name_a_z':
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'name_z_a':
        sorted.sort((a, b) => b.name.compareTo(a.name));
        break;
      default:
        break;
    }

    return sorted;
  }
}
