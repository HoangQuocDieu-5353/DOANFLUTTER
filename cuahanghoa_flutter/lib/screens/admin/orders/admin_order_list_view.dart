import 'package:flutter/material.dart';
import 'package:cuahanghoa_flutter/models/order_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'admin_order_detail_screen.dart'; 

class AdminOrderListView extends StatelessWidget {
  // Nhận danh sách đơn hàng đã được lọc từ màn hình cha
  final List<OrderModel> orders;
  
  const AdminOrderListView({super.key, required this.orders});

  // Helper format tiền
  String _formatCurrency(num amount) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    // 2. Hiển thị thông báo nếu list rỗng
    if (orders.isEmpty) {
      return Center(
        child: Text(
          "Không có đơn hàng nào trong mục này.",
          style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 16),
        ),
      );
    }
    
    // (Không cần sắp xếp nữa vì list cha đã sắp xếp rồi)

    // 3. Hiển thị ListView
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            title: Text(
              "Mã đơn: #${order.id.substring(0, 8)}...",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hiển thị ID của user đã đặt hàng
                Text(
                  "User: ${order.userId.substring(0, 10)}...", 
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700]),
                ),
                Text(
                  "Ngày: ${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)}",
                  style: GoogleFonts.inter(),
                ),
                Text(
                  "Tổng: ${_formatCurrency(order.totalPrice)}",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            isThreeLine: true,
            // 4. Khi nhấn vào -> Mở màn hình chi tiết (Bước 4)
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  // Truyền order object sang màn hình chi tiết
                  builder: (_) => AdminOrderDetailScreen(order: order),
                ),
              );
            },
          ),
        );
      },
    );
  }
}