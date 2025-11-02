import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/cart_item.dart';

class CartService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  DatabaseReference get _cartRef => _db.child('carts/$_userId');

  //  Lấy dữ liệu realtime (cả items và status)
  Stream<DatabaseEvent> getCartStream() {
    return _cartRef.onValue;
  }

  //  Thêm sản phẩm mới vào giỏ hàng
  Future<void> addToCart(CartItem item) async {
    if (_userId == null || item.id.isEmpty) return;

    final itemRef = _cartRef.child('items').child(item.id);

    // Nếu chưa có trạng thái thì gán mặc định "pending"
    final statusSnap = await _cartRef.child('status').get();
    if (!statusSnap.exists) {
      await _cartRef.child('status').set('pending');
    }

    await itemRef.set(item.toJson());
  }

  //  Xóa sản phẩm khỏi giỏ hàng
  Future<void> removeFromCart(String id) async {
    if (_userId == null || id.isEmpty) return;
    await _cartRef.child('items').child(id).remove();
  }

  // 🔹 Tăng số lượng
  Future<void> increaseQuantity(String id, int currentQuantity) async {
    if (_userId == null || id.isEmpty) return;
    await _cartRef.child('items').child(id).update({
      'quantity': currentQuantity + 1,
    });
  }

  //  Giảm số lượng
  Future<void> decreaseQuantity(String id, int currentQuantity) async {
    if (_userId == null || id.isEmpty) return;

    if (currentQuantity > 1) {
      await _cartRef.child('items').child(id).update({
        'quantity': currentQuantity - 1,
      });
    } else {
      await _cartRef.child('items').child(id).remove();
    }
  }

  //  Xóa toàn bộ giỏ hàng
  Future<void> clearCart() async {
    if (_userId == null) return;
    await _cartRef.remove();
  }

  //  Cập nhật trạng thái giỏ hàng (ví dụ: "pending", "paid", "canceled")
  Future<void> updateStatus(String status) async {
    if (_userId == null) return;
    await _cartRef.child('status').set(status);
  }

  //  Lấy trạng thái hiện tại của giỏ hàng
  Future<String?> getStatus() async {
    if (_userId == null) return null;
    final snapshot = await _cartRef.child('status').get();
    return snapshot.value?.toString();
  }
}
