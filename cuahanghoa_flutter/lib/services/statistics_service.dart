import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class StatisticsService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  ///  Tổng doanh thu theo ngày (7 ngày gần nhất)
  Future<Map<String, double>> getDailyRevenue({int days = 7}) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days - 1));
    final snapshot = await _db.child('orders').get();

    Map<String, double> dailyRevenue = {};

    for (var userSnap in snapshot.children) {
      for (var orderSnap in userSnap.children) {
        final orderVal = orderSnap.value;
        if (orderVal is! Map) continue;
        final order = Map<String, dynamic>.from(orderVal);

        if (order['status'] == 'completed' && order['createdAt'] != null) {
          final createdAt = DateTime.tryParse(order['createdAt'].toString());
          if (createdAt != null && createdAt.isAfter(startDate)) {
            final dateKey = DateFormat('dd/MM').format(createdAt);
            final total = (order['totalPrice'] as num?)?.toDouble() ?? 0;
            dailyRevenue[dateKey] = (dailyRevenue[dateKey] ?? 0) + total;
          }
        }
      }
    }

    return dailyRevenue;
  }

  ///  Tổng doanh thu theo tháng (6 tháng gần nhất)
  Future<Map<String, double>> getMonthlyRevenue({int months = 6}) async {
    final snapshot = await _db.child('orders').get();
    Map<String, double> monthlyRevenue = {};

    for (var userSnap in snapshot.children) {
      for (var orderSnap in userSnap.children) {
        final orderVal = orderSnap.value;
        if (orderVal is! Map) continue;
        final order = Map<String, dynamic>.from(orderVal);

        if (order['status'] == 'completed' && order['createdAt'] != null) {
          final createdAt = DateTime.tryParse(order['createdAt'].toString());
          if (createdAt != null) {
            final key = DateFormat('MM/yyyy').format(createdAt);
            final total = (order['totalPrice'] as num?)?.toDouble() ?? 0;
            monthlyRevenue[key] = (monthlyRevenue[key] ?? 0) + total;
          }
        }
      }
    }

    // sắp xếp theo thứ tự thời gian
    final sorted = monthlyRevenue.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final startIndex = sorted.length > months ? sorted.length - months : 0;
    final filtered = sorted.sublist(startIndex);

    return Map.fromEntries(filtered);
  }

  /// Lấy top sản phẩm bán chạy nhất (LẤY TÊN TỪ items — cách A)
  Future<List<Map<String, dynamic>>> getBestSellingProducts({int limit = 5}) async {
    final orderSnap = await _db.child('orders').get();
    Map<String, int> productCount = {};

    for (var userSnap in orderSnap.children) {
      for (var orderSnap2 in userSnap.children) {
        final orderVal = orderSnap2.value;
        if (orderVal is! Map) continue;
        final order = Map<String, dynamic>.from(orderVal);

        if (order['status'] != 'completed') continue;
        if (order['items'] == null) continue;

        final itemsVal = order['items'];

        if (itemsVal is Map) {
          final items = Map<dynamic, dynamic>.from(itemsVal);
          for (var itemVal in items.values) {
            if (itemVal is! Map) continue;
            final item = Map<String, dynamic>.from(itemVal);
            final name = item['name']?.toString() ?? 'Unknown';
            final quantity = (item['quantity'] ?? 1) as int;
            productCount[name] = (productCount[name] ?? 0) + quantity;
          }
        } else if (itemsVal is List) {
          for (var itemVal in itemsVal) {
            if (itemVal is! Map) continue;
            final item = Map<String, dynamic>.from(itemVal);
            final name = item['name']?.toString() ?? 'Unknown';
            final quantity = (item['quantity'] ?? 1) as int;
            productCount[name] = (productCount[name] ?? 0) + quantity;
          }
        }
      }
    }

    // sắp xếp giảm dần theo số lượng bán
    final sorted = productCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = sorted.take(limit).toList();

    List<Map<String, dynamic>> result = [];
    for (var p in top) {
      result.add({
        'name': p.key,
        'count': p.value,
      });
    }

    return result;
  }

  /// Đếm số đơn hàng hoàn thành trong ngày hôm nay
  Future<int> getTodayOrderCount() async {
    final snapshot = await _db.child('orders').get();
    int count = 0;
    final today = DateTime.now();

    for (var userSnap in snapshot.children) {
      for (var orderSnap in userSnap.children) {
        final orderVal = orderSnap.value;
        if (orderVal is! Map) continue;
        final order = Map<String, dynamic>.from(orderVal);

        if (order['status'] == 'completed' && order['createdAt'] != null) {
          final createdAt = DateTime.tryParse(order['createdAt'].toString());
          if (createdAt != null &&
              createdAt.year == today.year &&
              createdAt.month == today.month &&
              createdAt.day == today.day) {
            count++;
          }
        }
      }
    }
    return count;
  }
}
