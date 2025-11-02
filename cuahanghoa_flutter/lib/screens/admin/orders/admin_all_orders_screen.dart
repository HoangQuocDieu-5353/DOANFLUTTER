import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'package:cuahanghoa_flutter/models/order_model.dart';
import 'package:cuahanghoa_flutter/services/order_service.dart';
import 'admin_order_list_view.dart'; 

class AdminAllOrdersScreen extends StatefulWidget {
  const AdminAllOrdersScreen({super.key});

  @override
  State<AdminAllOrdersScreen> createState() => _AdminAllOrdersScreenState();
}

// ⬇️ Thêm "with TickerProviderStateMixin" để quản lý TabController
class _AdminAllOrdersScreenState extends State<AdminAllOrdersScreen>
    with TickerProviderStateMixin {
      
  late final TabController _tabController;
  final OrderService _orderService = OrderService();


  final List<Tab> _tabs = const [
    Tab(text: "Chờ xử lý"),      // pending
    Tab(text: "Đã thanh toán"), // paid
    Tab(text: "Đang giao"),       // shipping
    Tab(text: "Hoàn thành"),    // completed
    Tab(text: "Đã hủy"),         // cancelled
    Tab(text: "Yêu cầu Trả"),    // return_requested
    
  ];

  // Các status tương ứng với từng tab 
  final List<String> _statuses = [
    'pending',
    'paid',
    'shipping',
    'completed',
    'cancelled',
    'return_requested',
  ];

  @override
  void initState() {
    super.initState();
    // Khởi tạo TabController
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Quản lý Đơn hàng", 
          style: GoogleFonts.inter(fontWeight: FontWeight.w600)
        ),
        // 3. Hiển thị TabBar ở dưới AppBar
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true, // Cho phép cuộn tab nếu quá dài
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600), // Font cho tab
          unselectedLabelStyle: GoogleFonts.inter(), // Font cho tab
          tabs: _tabs,
        ),
      ),
      // 4. Dùng StreamBuilder để lấy TẤT CẢ đơn hàng 1 LẦN
      body: StreamBuilder<List<OrderModel>>(
        stream: _orderService.getAllOrders(), // Gọi hàm mới
        builder: (context, snapshot) {
          // Xử lý các trạng thái
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi tải đơn hàng: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Không có đơn hàng nào."));
          }

          // Đã có data
          final allOrders = snapshot.data!;
          
          // 5. Tạo danh sách các widget con cho TabBarView
          final tabViews = _statuses.map((status) {
            // Lọc danh sách đơn hàng theo status của tab
            final filteredOrders = allOrders
                .where((order) => order.status == status)
                .toList();
                
            // Trả về widget AdminOrderListView 
            // Widget này sẽ chịu trách nhiệm hiển thị list đã được lọc
            return AdminOrderListView(orders: filteredOrders);
          }).toList();

          // 6. Hiển thị nội dung của các tab
          return TabBarView(
            controller: _tabController,
            children: tabViews,
          );
        },
      ),
    );
  }
}