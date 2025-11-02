import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// Các màn hình quản trị
import 'package:cuahanghoa_flutter/screens/admin/banner/banner_admin_screen.dart';
import 'package:cuahanghoa_flutter/screens/admin/category/category_list_screen.dart';
import 'package:cuahanghoa_flutter/screens/admin/products/product_list_screen.dart';
import 'package:cuahanghoa_flutter/screens/admin/users/user_list_screen.dart';
import 'package:cuahanghoa_flutter/screens/auth/views/login_screen.dart';
import 'package:cuahanghoa_flutter/screens/admin/orders/admin_all_orders_screen.dart';
import 'package:cuahanghoa_flutter/screens/admin/coupons/admin_coupon_list_screen.dart';
import 'package:cuahanghoa_flutter/route/route_constants.dart';
import 'package:cuahanghoa_flutter/screens/admin/statistics/statistics_screen.dart';

// Dịch vụ lấy dữ liệu
import 'package:cuahanghoa_flutter/services/category_service.dart';
import 'package:cuahanghoa_flutter/services/statistics_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final CategoryService _categoryService = CategoryService();
  final StatisticsService _statisticsService = StatisticsService();

  // Biến lưu dữ liệu thống kê nhanh
  int _userCount = 0; // Tổng số người dùng
  int _productCount = 0; // Tổng số sản phẩm
  int _categoryCount = 0; // Tổng số danh mục
  int _pendingOrderCount = 0; // Đơn hàng đang chờ xử lý
  double _todayRevenue = 0; // Doanh thu hôm nay
  int _todayOrderCount = 0; // Số đơn hàng hôm nay
  bool _isLoading = true; // Hiển thị loading khi đang tải dữ liệu

  @override
  void initState() {
    super.initState();
    // Lắng nghe dữ liệu thời gian thực từ Firebase
    _listenToRealtimeData();
    // Tính toán doanh thu và số đơn hàng hôm nay
    _fetchTodayData();
  }

  // Theo dõi dữ liệu realtime từ Firebase Database
  void _listenToRealtimeData() {
    // Đếm tổng người dùng
    _db.child('users').onValue.listen((event) {
      if (mounted) {
        setState(() => _userCount = event.snapshot.children.length);
      }
    });

    // Đếm tổng sản phẩm
    _db.child('products').onValue.listen((event) {
      if (mounted) {
        setState(() => _productCount = event.snapshot.children.length);
      }
    });

    // Đếm tổng danh mục
    _categoryService.getAllCategories().listen((list) {
      if (mounted) {
        setState(() {
          _categoryCount = list.length;
          _isLoading = false;
        });
      }
    });

    // Đếm tổng đơn hàng đang chờ xử lý
    _db.child('orders').onValue.listen((event) {
      int count = 0;
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        data.forEach((userId, userOrders) {
          if (userOrders is Map) {
            userOrders.forEach((orderId, orderData) {
              if (orderData is Map && orderData['status'] == 'pending') {
                count++;
              }
            });
          }
        });
      }
      if (mounted) {
        setState(() => _pendingOrderCount = count);
      }
    });
  }

  // Lấy dữ liệu doanh thu và đơn hàng trong ngày
  Future<void> _fetchTodayData() async {
    final revenueData = await _statisticsService.getDailyRevenue(days: 1);
    final todayKey = DateFormat('dd/MM').format(DateTime.now());
    final todayRevenue = revenueData[todayKey] ?? 0;
    final orderCount = await _statisticsService.getTodayOrderCount();

    if (mounted) {
      setState(() {
        _todayRevenue = todayRevenue;
        _todayOrderCount = orderCount;
      });
    }
  }

  // Đăng xuất tài khoản quản trị
  Future<void> _logout() async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận"),
        content: const Text("Bạn có chắc chắn muốn đăng xuất?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Đăng xuất", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          logInScreenRoute,
          (route) => false,
        );
      }
    }
  }

  // Hiển thị ô thống kê nhỏ trên dashboard
  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Card(
      elevation: 0.5,
      color: color.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 12),
            Text(
              count,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  // Tạo từng dòng chức năng quản trị trong danh sách
  Widget _buildAdminMenuTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Thanh AppBar chứa tiêu đề và nút đăng xuất
      appBar: AppBar(
        title: Text("Admin Dashboard",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Đăng xuất",
            onPressed: _logout,
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Hiển thị thống kê nhanh trong ngày
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hôm nay",
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Hiển thị doanh thu trong ngày
                          Column(
                            children: [
                              Text(
                                NumberFormat.currency(
                                        locale: 'vi_VN', symbol: '₫')
                                    .format(_todayRevenue),
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text("Doanh thu",
                                  style: GoogleFonts.inter(fontSize: 13)),
                            ],
                          ),
                          // Hiển thị tổng số đơn hàng trong ngày
                          Column(
                            children: [
                              Text(
                                _todayOrderCount.toString(),
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text("Đơn hàng",
                                  style: GoogleFonts.inter(fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Text(
                  "Tổng quan hệ thống",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),

                // Lưới thống kê tổng quan (người dùng, sản phẩm, danh mục...)
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.3,
                  children: [
                    _buildStatCard("Đơn hàng chờ", _pendingOrderCount.toString(),
                        Icons.pending_actions_outlined, Colors.blue.shade700),
                    _buildStatCard("Người dùng", _userCount.toString(),
                        Icons.group_outlined, Colors.purple.shade700),
                    _buildStatCard("Sản phẩm", _productCount.toString(),
                        Icons.storefront_outlined, Colors.green.shade700),
                    _buildStatCard("Danh mục", _categoryCount.toString(),
                        Icons.category_outlined, Colors.orange.shade700),
                  ],
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Danh sách chức năng quản lý
                Text(
                  "Quản lý",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),

                _buildAdminMenuTile(
                  title: "Quản lý Đơn hàng",
                  subtitle: "Duyệt, xác nhận và hủy đơn hàng",
                  icon: Icons.receipt_long_outlined,
                  color: Colors.blue.shade700,
                  onTap: () {
                    Navigator.pushNamed(context, adminOrdersScreenRoute);
                  },
                ),
                _buildAdminMenuTile(
                  title: "Quản lý Sản phẩm",
                  subtitle: "Thêm, sửa, xóa sản phẩm",
                  icon: Icons.storefront_outlined,
                  color: Colors.green.shade700,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ProductListScreen()),
                    );
                  },
                ),
                _buildAdminMenuTile(
                  title: "Quản lý Danh mục",
                  subtitle: "Thêm, sửa, xóa danh mục",
                  icon: Icons.category_outlined,
                  color: Colors.orange.shade700,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CategoryListScreen()),
                    );
                  },
                ),
                _buildAdminMenuTile(
                  title: "Quản lý Người dùng",
                  subtitle: "Xem, khóa và đổi quyền người dùng",
                  icon: Icons.group_outlined,
                  color: Colors.purple.shade700,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const UserListScreen()),
                    );
                  },
                ),
                _buildAdminMenuTile(
                  title: "Quản lý Mã giảm giá",
                  subtitle: "Tạo, sửa và vô hiệu hóa mã",
                  icon: Icons.discount_outlined,
                  color: Colors.teal.shade700,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminCouponListScreen()),
                    );
                  },
                ),
                _buildAdminMenuTile(
                  title: "Quản lý Banner",
                  subtitle: "Thêm, ẩn hoặc xóa banner quảng cáo",
                  icon: Icons.image_outlined,
                  color: Colors.indigo.shade700,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const BannerAdminScreen()),
                    );
                  },
                ),
                _buildAdminMenuTile(
                  title: "Quản lý Đánh giá",
                  subtitle: "Duyệt và quản lý đánh giá của người dùng",
                  icon: Icons.reviews_outlined,
                  color: Colors.red.shade700,
                  onTap: () {
                    Navigator.pushNamed(context, reviewManagementScreenRoute);
                  },
                ),
                _buildAdminMenuTile(
                  title: "Quản lý Báo cáo & Thống kê",
                  subtitle: "Thống kê doanh thu và sản phẩm bán chạy",
                  icon: Icons.bar_chart_outlined,
                  color: Colors.deepPurple.shade700,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const StatisticsScreen()),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
