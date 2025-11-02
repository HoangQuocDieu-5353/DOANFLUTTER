import 'package:firebase_database/firebase_database.dart';
import '../models/order_model.dart'; // Đảm bảo đường dẫn đến OrderModel đúng

class OrderService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Helper để lấy ref đến node đơn hàng của user cụ thể
  DatabaseReference _userOrderRef(String userId) =>
      _db.child('orders').child(userId);

  ///  Tạo đơn hàng theo từng user
  Future<void> createOrder(OrderModel order) async {
    await _userOrderRef(order.userId).child(order.id).set(order.toMap());
  }

  ///  Lấy danh sách đơn hàng của 1 user (Realtime)
  Stream<List<OrderModel>> getOrdersByUser(String userId) {
    return _userOrderRef(userId).onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return []; 

      final Map<dynamic, dynamic> map = data as Map<dynamic, dynamic>;
      return map.entries.map((entry) {
        final orderId = entry.key as String;
        final orderData = entry.value as Map<dynamic, dynamic>;
        return OrderModel.fromMap(orderData, orderId);
      }).toList();
    });
  }
  
  ///  Lấy tất cả đơn hàng từ tất cả user
  Stream<List<OrderModel>> getAllOrders() {
    final ref = _db.child('orders'); // Nghe toàn bộ node 'orders'
    return ref.onValue.map((event) {
      final List<OrderModel> allOrders = [];
      final data = event.snapshot.value;
      if (data == null || data is! Map) {
        return allOrders; // Trả về list rỗng
      }
      
      // data là Map<userId, Map<orderId, orderData>>
      final allUserOrders = data;
      
      // Vòng lặp 1: Lấy từng userId
      allUserOrders.forEach((userId, userOrdersData) {
        if (userOrdersData is Map<dynamic, dynamic>) {
          // Vòng lặp 2: Lấy từng orderId
          userOrdersData.forEach((orderId, orderData) {
            if (orderData is Map<dynamic, dynamic>) {
              // Thêm đơn hàng vào danh sách
              allOrders.add(OrderModel.fromMap(orderData, orderId.toString()));
            }
          });
        }
      });

      // Sắp xếp tất cả đơn hàng theo ngày tạo (mới nhất lên đầu)
      allOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return allOrders;
    });
  }
  Stream<OrderModel?> listenToOrder(String userId, String orderId) {
    return _userOrderRef(userId).child(orderId).onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) {
        return null;
      }
      return OrderModel.fromMap(data, orderId);
    });
  }


  ///  Lấy chi tiết một đơn hàng của 1 user theo ID
  Future<OrderModel?> getOrderById(String userId, String orderId) async {
    final snapshot = await _userOrderRef(userId).child(orderId).get();
    if (!snapshot.exists || snapshot.value == null) {
      return null;
    }

    final data = snapshot.value as Map<dynamic, dynamic>;
    return OrderModel.fromMap(data, orderId);
  }

  ///  Cập nhật trạng thái đơn hàng (dùng cho cả User và Admin)
  Future<void> updateOrderStatus(String userId, String orderId, String newStatus) async {
    await _userOrderRef(userId).child(orderId).update({'status': newStatus});
  }

  ///  Xóa một đơn hàng
  Future<void> deleteOrder(String userId, String orderId) async {
    await _userOrderRef(userId).child(orderId).remove();
  }

  ///  User yêu cầu trả hàng
  Future<void> requestReturn(String userId, String orderId) async {
    await _userOrderRef(userId)
        .child(orderId)
        .update({'status': 'return_requested'});
  }

}