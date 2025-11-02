import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:google_fonts/google_fonts.dart'; 
import 'package:intl/intl.dart'; 
import 'package:cuahanghoa_flutter/models/order_model.dart';
import 'package:cuahanghoa_flutter/services/order_service.dart';
import 'package:cuahanghoa_flutter/screens/order/views/order_detail_screen.dart'; 

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final OrderService _orderService = OrderService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Helper format tiền
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Đơn hàng của tôi",
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // 1. Kiểm tra đăng nhập
    if (currentUser == null) {
      return const Center(child: Text("Vui lòng đăng nhập để xem đơn hàng."));
    }

    // 2. Dùng StreamBuilder để lắng nghe đơn hàng
    return StreamBuilder<List<OrderModel>>(
      stream: _orderService.getOrdersByUser(currentUser!.uid),
      builder: (context, snapshot) {
        // 3. Xử lý các trạng thái
        if (snapshot.hasError) {
          return Center(child: Text("Lỗi: ${snapshot.error}"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data;

        // 4. Xử lý khi không có đơn hàng
        if (orders == null || orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  "Bạn chưa có đơn hàng nào",
                  style: GoogleFonts.inter(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        // 5. Sắp xếp đơn hàng (mới nhất lên đầu)
        orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // 6. Hiển thị danh sách đơn hàng
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _buildOrderItemCard(order);
          },
        );
      },
    );
  }

  /// Widget hiển thị 1 thẻ (Card) tóm tắt đơn hàng
  Widget _buildOrderItemCard(OrderModel order) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        
        //  2. SỬA LẠI HÀM ONTAP
        onTap: () {
          // Bỏ SnackBar, dùng Navigator.push
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(order: order),
            ),
          );
        },
        //  HẾT PHẦN SỬA

        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Mã đơn: ${order.id.substring(0, 8)}...", // Rút gọn mã đơn
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  // Hiển thị trạng thái
                  _buildStatusChip(order.status),
                ],
              ),
              const Divider(height: 20),
              // Thông tin tóm tắt
              _buildInfoRow(
                Icons.calendar_today,
                "Ngày đặt",
                DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt),
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.shopping_bag_outlined,
                "Số lượng",
                "${order.items.length} sản phẩm",
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.payment,
                "Thanh toán",
                order.paymentMethod,
              ),
              const SizedBox(height: 12),
              // Tổng tiền
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "Tổng tiền: ${currencyFormatter.format(order.totalPrice)}",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget hiển thị 1 dòng thông tin (Icon - Label - Value)
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Text("$label: ", style: GoogleFonts.inter(color: Colors.grey[700])),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  /// Widget hiển thị trạng thái (Chip)
  Widget _buildStatusChip(String status) {
    String label;
    Color color;

    switch (status) {
      case 'pending':
        label = "Chờ xử lý";
        color = Colors.orange;
        break;
      case 'paid':
        label = "Đã thanh toán";
        color = Colors.blue;
        break;
      case 'shipping':
        label = "Đang giao";
        color = Colors.teal;
        break;
      case 'completed':
        label = "Hoàn thành";
        color = Colors.green;
        break;
      case 'cancelled':
        label = "Đã hủy";
        color = Colors.red;
        break;
      case 'return_requested':
        label = "Trả hàng";
        color = Colors.red;
        break;
      default:
        label = "Không rõ";
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        label,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}