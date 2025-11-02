import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cuahanghoa_flutter/services/statistics_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final StatisticsService _service = StatisticsService();

  // Lưu dữ liệu thống kê doanh thu và sản phẩm
  Map<String, double> dailyRevenue = {};   // Doanh thu theo ngày
  Map<String, double> monthlyRevenue = {}; // Doanh thu theo tháng
  List<Map<String, dynamic>> bestSelling = []; // Danh sách sản phẩm bán chạy

  // Biến trạng thái để hiển thị vòng tròn loading khi đang tải
  bool loading = true;

  @override
  void initState() {
    super.initState();
    // Gọi hàm tải dữ liệu khi màn hình khởi tạo
    loadData();
  }

  // Lấy dữ liệu thống kê từ service
  Future<void> loadData() async {
    final daily = await _service.getDailyRevenue(days: 7);      // Lấy doanh thu 7 ngày gần nhất
    final monthly = await _service.getMonthlyRevenue(months: 6); // Lấy doanh thu 6 tháng gần nhất
    final best = await _service.getBestSellingProducts(limit: 5); // Lấy top 5 sản phẩm bán chạy

    // Cập nhật state khi dữ liệu đã sẵn sàng
    setState(() {
      dailyRevenue = daily;
      monthlyRevenue = monthly;
      bestSelling = best;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📈 Báo cáo & Thống kê')),

      // Hiển thị loading hoặc nội dung chính
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadData, // Kéo xuống để reload dữ liệu
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Biểu đồ doanh thu 7 ngày gần nhất
                    buildSectionTitle('📅 Doanh thu 7 ngày gần nhất'),
                    buildRevenueChart(dailyRevenue),
                    const SizedBox(height: 30),

                    // Biểu đồ doanh thu 6 tháng gần nhất
                    buildSectionTitle('📆 Doanh thu 6 tháng gần nhất'),
                    buildRevenueChart(monthlyRevenue),
                    const SizedBox(height: 30),

                    // Danh sách sản phẩm bán chạy nhất
                    buildSectionTitle('🔥 Top sản phẩm bán chạy'),
                    buildBestSellingList(bestSelling),
                  ],
                ),
              ),
            ),
    );
  }

  // Hiển thị tiêu đề cho từng phần biểu đồ hoặc danh sách
  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  // Vẽ biểu đồ doanh thu theo dữ liệu truyền vào (theo ngày hoặc tháng)
  Widget buildRevenueChart(Map<String, double> data) {
    if (data.isEmpty) return const Text('Không có dữ liệu');

    final keys = data.keys.toList();
    final values = data.values.toList();
    final maxY = values.reduce((a, b) => a > b ? a : b); // Giá trị cao nhất để chia trục Y

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),

          // Dữ liệu từng cột của biểu đồ
          barGroups: List.generate(values.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: values[index],
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),

          // Cấu hình hiển thị nhãn cho trục X, Y
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= keys.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      keys[index], // Hiển thị nhãn theo ngày hoặc tháng
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                getTitlesWidget: (value, meta) {
                  // Hiển thị giá trị trục Y theo dạng "k" (nghìn đồng)
                  if (value == 0) return const Text('0');
                  if (value % (maxY / 4) == 0) {
                    return Text('${value ~/ 1000}k');
                  }
                  return const SizedBox();
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
        ),
      ),
    );
  }

  // Hiển thị danh sách các sản phẩm bán chạy nhất
  Widget buildBestSellingList(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return const Text('Không có dữ liệu');
    return Column(
      children: data.map((e) {
        return ListTile(
          leading: const Icon(Icons.shopping_bag_outlined),
          title: Text(e['name']),
          trailing: Text('${e['count']} sp'), // Số lượng sản phẩm bán được
        );
      }).toList(),
    );
  }
}
