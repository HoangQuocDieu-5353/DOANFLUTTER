import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cuahanghoa_flutter/models/order_model.dart';
import 'package:cuahanghoa_flutter/services/order_service.dart';
import 'package:cuahanghoa_flutter/route/route_constants.dart'; // để dùng returnDetailsScreenRoute
import 'package:cuahanghoa_flutter/screens/order/views/order_detail_screen.dart';

class ReturnScreen extends StatefulWidget {
  const ReturnScreen({super.key});

  @override
  State<ReturnScreen> createState() => _ReturnScreenState();
}

class _ReturnScreenState extends State<ReturnScreen> {
  final OrderService _orderService = OrderService();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String? _processingOrderId;

  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Yêu cầu Trả hàng",
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (currentUser == null) {
      return const Center(child: Text("Vui lòng đăng nhập."));
    }

    return StreamBuilder<List<OrderModel>>(
      stream: _orderService.getOrdersByUser(currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Lỗi: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allOrders = snapshot.data ?? [];

        // Lọc đơn hàng đã hoàn thành
        final completedOrders =
            allOrders.where((order) => order.status == 'completed').toList();

        completedOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (completedOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inventory_2_outlined,
                    size: 80, color: Colors.grey),
                const SizedBox(height: 12),
                Text("Chưa có đơn hàng hoàn thành nào.",
                    style: GoogleFonts.inter(
                        fontSize: 16, color: Colors.grey[600])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: completedOrders.length,
          itemBuilder: (context, index) {
            final order = completedOrders[index];
            final bool isProcessing = _processingOrderId == order.id;

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Mã đơn: #${order.id.substring(0, 8)}...",
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.visibility, color: Colors.grey[600]),
                          tooltip: "Xem chi tiết",
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    OrderDetailScreen(order: order),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    _buildInfoRow(Icons.calendar_today, "Ngày hoàn thành:",
                        DateFormat('dd/MM/yyyy').format(order.createdAt)),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.shopping_bag_outlined, "Sản phẩm:",
                        "${order.items.length} mục"),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.attach_money, "Tổng tiền:",
                        currencyFormatter.format(order.totalPrice)),
                    const SizedBox(height: 16),

                    // Nút Yêu cầu trả
                    Align(
                      alignment: Alignment.centerRight,
                      child: isProcessing
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            )
                          : ElevatedButton.icon(
                              icon: const Icon(Icons.undo, size: 18),
                              label: const Text("Yêu cầu trả"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                textStyle: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600),
                              ),
                              onPressed: () {
                                //  Điều hướng sang màn chi tiết trả hàng
                                Navigator.pushNamed(
                                  context,
                                  returnDetailsScreenRoute,
                                  arguments: order.id,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 18),
        const SizedBox(width: 8),
        Text(label,
            style: GoogleFonts.inter(
                color: Colors.black54, fontWeight: FontWeight.w500)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
