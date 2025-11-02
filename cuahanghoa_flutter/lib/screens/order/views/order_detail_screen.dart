import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cuahanghoa_flutter/models/order_model.dart';
import 'package:cuahanghoa_flutter/models/cart_item.dart';
import 'package:cuahanghoa_flutter/services/order_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late OrderModel order;

  @override
  void initState() {
    super.initState();
    order = widget.order;

    //  In ra để kiểm tra
    print('🟢 Trạng thái đơn hàng: "${order.status}"');
  }

  String _formatCurrency(num amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return formatter.format(amount);
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận hủy đơn"),
        content: const Text("Bạn có chắc chắn muốn hủy đơn hàng này không?"),
        actions: [
          TextButton(
            child: const Text("Không"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Hủy đơn"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    //  Cập nhật trong Firebase (có userId)
    await OrderService().updateOrderStatus(order.userId, order.id, 'cancelled');

    setState(() {
      order = order.copyWith(status: 'cancelled');
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đơn hàng đã được hủy")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
    );

    //  Ép status về dạng chuẩn (tránh sai do null hoặc chữ hoa/thường)
    final normalizedStatus = (order.status ?? '').trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Chi tiết đơn hàng",
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Divider(height: 30),
            Text("Các sản phẩm đã đặt", style: titleStyle),
            const SizedBox(height: 12),
            _buildProductList(),
            const Divider(height: 30),
            Text("Thông tin giao hàng", style: titleStyle),
            const SizedBox(height: 12),
            _buildDetailRow("Địa chỉ:", order.address),
            const Divider(height: 30),
            Text("Chi tiết thanh toán", style: titleStyle),
            const SizedBox(height: 12),
            _buildDetailRow("Phương thức:", order.paymentMethod),
            _buildDetailRow(
              "Tổng tiền:",
              _formatCurrency(order.totalPrice),
              isTotal: true,
            ),
          ],
        ),
      ),

      //  Nút chỉ hiện nếu trạng thái thật sự là "pending"
      bottomNavigationBar: normalizedStatus == 'pending'
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _cancelOrder,
                  icon: const Icon(Icons.cancel, color: Colors.white),
                  label: const Text(
                    "Hủy đơn hàng",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Mã đơn: #${order.id.substring(0, 8)}...",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildStatusChip(order.status ?? ''),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            "Ngày đặt:",
            DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: order.items.map((item) {
          return Column(
            children: [
              _buildProductItem(item),
              if (item != order.items.last)
                const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductItem(CartItem item) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.network(
          item.imageUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.image_not_supported, color: Colors.grey),
        ),
      ),
      title: Text(item.name,
          style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
      subtitle: Text("SL: ${item.quantity}",
          style: GoogleFonts.inter(color: Colors.black54)),
      trailing: Text(
        _formatCurrency(item.price * item.quantity),
        style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 15),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    final valueStyle = GoogleFonts.inter(
      fontSize: isTotal ? 18 : 16,
      fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
      color: isTotal ? Colors.deepPurpleAccent : Colors.black87,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(fontSize: 16, color: Colors.black54)),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right, style: valueStyle, maxLines: 2),
          ),
        ],
      ),
    );
  }

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
