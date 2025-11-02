import 'package:firebase_database/firebase_database.dart';
import '../models/category_model.dart';

class CategoryService {
  final DatabaseReference _ref = FirebaseDatabase.instance.ref('categories');

  ///  Thêm hoặc cập nhật danh mục
  Future<void> addOrUpdateCategory(CategoryModel category) async {
    await _ref.child(category.id).set(category.toMap());
  }

  ///  Lấy danh sách danh mục realtime
  Stream<List<CategoryModel>> getAllCategories() {
    return _ref.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];

      final Map<dynamic, dynamic> map = data as Map<dynamic, dynamic>;
      return map.entries.map((e) {
        return CategoryModel.fromMap(e.value, e.key);
      }).toList();
    });
  }

  ///  Lấy danh mục theo ID (1 lần)
  Future<CategoryModel?> getCategoryById(String id) async {
    final snapshot = await _ref.child(id).get();
    if (!snapshot.exists) return null;

    final data = snapshot.value as Map<dynamic, dynamic>;
    return CategoryModel.fromMap(data, id);
  }

  ///  Xóa danh mục
  Future<void> deleteCategory(String id) async {
    await _ref.child(id).remove();
  }
}
