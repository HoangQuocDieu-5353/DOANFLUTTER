import 'package:flutter/material.dart';
import 'package:cuahanghoa_flutter/models/order_model.dart';
import 'package:cuahanghoa_flutter/services/order_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cuahanghoa_flutter/models/cart_item.dart';


class AdminOrderDetailScreen extends StatefulWidget {
  final OrderModel order;

  const AdminOrderDetailScreen({super.key, required this.order});

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  final OrderService _orderService = OrderService();
  bool _isLoading = false;

  /// Hàm định dạng tiền tệ sang kiểu VNĐ
  String _formatCurrency(num amount) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(amount);
  }

  ///  Hàm cập nhật trạng thái đơn hàng (Admin xác nhận, hủy, giao, hoàn thành...)
  Future<void> _updateStatus(String newStatus) async {
    // Xác nhận hành động trước khi thay đổi trạng thái
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận cập nhật"),
        content: Text("Bạn có chắc muốn đổi trạng thái đơn hàng thành: '$newStatus'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Xác nhận")),
        ],
      ),
    );

    // Nếu người dùng hủy, dừng lại
    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      // Gọi service cập nhật trạng thái trên Firebase
      await _orderService.updateOrderStatus(widget.order.userId, widget.order.id, newStatus);

      if (mounted) {
        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Đã cập nhật trạng thái thành: $newStatus")),
        );
        Navigator.pop(context); // Quay lại danh sách đơn
      }
    } catch (e) {
      if (mounted) {
        // Báo lỗi nếu cập nhật thất bại
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600);

    return Scaffold(
      appBar: AppBar(
        title: Text("Chi tiết Đơn #${widget.order.id.substring(0, 8)}"),
      ),

      ///  StreamBuilder: Lắng nghe thay đổi của đơn hàng theo thời gian thực
      /// Khi admin hoặc user cập nhật trạng thái, UI sẽ tự động refresh.
      body: StreamBuilder<OrderModel?>(
        stream: _orderService.listenToOrder(widget.order.userId, widget.order.id),
        initialData: widget.order,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Không tìm thấy đơn hàng."));
          }

          final order = snapshot.data!;

          return Stack(
            children: [
              //  Phần nội dung chính (chi tiết đơn hàng)
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(order),
                    const Divider(height: 30),

                    //  Danh sách sản phẩm
                    Text("Các sản phẩm đã đặt", style: titleStyle),
                    const SizedBox(height: 12),
                    _buildProductList(order),

                    const Divider(height: 30),

                    //  Thông tin giao hàng
                    Text("Thông tin giao hàng", style: titleStyle),
                    const SizedBox(height: 12),
                    _buildDetailRow("Địa chỉ:", order.address),
                    _buildDetailRow("User ID:", order.userId),

                    const Divider(height: 30),

                    //  Thông tin thanh toán
                    Text("Chi tiết thanh toán", style: titleStyle),
                    const SizedBox(height: 12),
                    _buildDetailRow("Phương thức:", order.paymentMethod),
                    _buildDetailRow("Tổng tiền:", _formatCurrency(order.totalPrice), isTotal: true),

                    //  Nếu đơn hàng có yêu cầu trả hàng, hiển thị thêm phần này
                    if (order.status == 'return_requested' ||
                        order.status == 'return_approved' ||
                        order.status == 'return_denied') ...[
                      const Divider(height: 30),
                      Text("Thông tin trả hàng", style: titleStyle),
                      const SizedBox(height: 8),
                      if (order.returnReason != null && order.returnReason!.isNotEmpty)
                        _buildDetailRow("Lý do:", order.returnReason!),
                      const SizedBox(height: 8),
                      if (order.returnImages != null && order.returnImages!.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: order.returnImages!.map((imgUrl) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                imgUrl,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
              ),

              //  Overlay loading khi đang xử lý cập nhật trạng thái
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),

      //  Thanh công cụ phía dưới cho phép Admin thay đổi trạng thái đơn
      bottomNavigationBar: _buildActionButtons(),
    );
  }

  ///  Tạo các nút hành động (Xác nhận, Hủy, Giao, Hoàn thành,...)
  Widget _buildActionButtons() {
    return StreamBuilder<OrderModel?>(
      stream: _orderService.listenToOrder(widget.order.userId, widget.order.id),
      initialData: widget.order,
      builder: (context, snapshot) {
        final status = snapshot.data?.status ?? widget.order.status;
        List<Widget> buttons = [];

        //  Tùy theo trạng thái đơn, hiển thị nút phù hợp
        switch (status) {
          case 'pending':
          case 'paid':
            buttons.add(_actionButton("Xác nhận & Giao hàng", Icons.local_shipping, Colors.blue,
                () => _updateStatus('shipping')));
            buttons.add(_actionButton("Hủy đơn", Icons.cancel, Colors.red,
                () => _updateStatus('cancelled')));
            break;
          case 'shipping':
            buttons.add(_actionButton("Đã giao (Hoàn thành)", Icons.check_circle, Colors.green,
                () => _updateStatus('completed')));
            break;
          case 'return_requested':
            buttons.add(_actionButton("Chấp nhận Trả hàng", Icons.check, Colors.green,
                () => _updateStatus('return_approved')));
            buttons.add(_actionButton("Từ chối Trả hàng", Icons.close, Colors.red,
                () => _updateStatus('return_denied')));
            break;
          default:
            return const SizedBox.shrink();
        }

        // Hiển thị các nút theo hàng
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: buttons,
            ),
          ),
        );
      },
    );
  }

  ///  Tạo từng nút hành động có biểu tượng & màu riêng
  Widget _actionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: _isLoading ? null : onPressed,
    );
  }

  /// Phần tiêu đề hiển thị mã đơn, ngày đặt và trạng thái
  Widget _buildHeader(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Mã đơn: #${order.id.substring(0, 8)}...",
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
              _buildStatusChip(order.status), // Hiển thị trạng thái bằng chip màu
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

  ///  Danh sách sản phẩm có trong đơn hàng
  Widget _buildProductList(OrderModel order) {
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

  ///  Hiển thị chi tiết từng sản phẩm trong đơn hàng
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
      title: Text(item.name, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
      subtitle: Text("SL: ${item.quantity}", style: GoogleFonts.inter(color: Colors.black54)),
      trailing: Text(
        _formatCurrency(item.price * item.quantity),
        style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 15),
      ),
    );
  }

  ///  Dòng hiển thị thông tin chi tiết (nhãn & giá trị)
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 16, color: Colors.black54)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(value, textAlign: TextAlign.right, style: valueStyle, maxLines: 3),
          ),
        ],
      ),
    );
  }

  ///  Chip màu hiển thị trạng thái đơn hàng
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
        label = "Yêu cầu trả";
        color = Colors.orange.shade800;
        break;
      case 'return_approved':
        label = "Đã trả hàng";
        color = Colors.black54;
        break;
      case 'return_denied':
        label = "Bị từ chối";
        color = Colors.red.shade900;
        break;
      default:
        label = "Không rõ";
        color = Colors.grey;
    }
    return Chip(
      label: Text(
        label,
        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
