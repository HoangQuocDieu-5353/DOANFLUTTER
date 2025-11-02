import 'package:flutter/material.dart';
import 'package:cuahanghoa_flutter/models/product_model.dart';
import 'package:cuahanghoa_flutter/services/product_service.dart';
import 'package:cuahanghoa_flutter/screens/admin/products/product_form_screen.dart';
import 'package:cuahanghoa_flutter/constants.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductService _productService = ProductService();

  // Stream chứa danh sách sản phẩm từ Firebase (tự động cập nhật khi có thay đổi)
  late Stream<List<ProductModel>> _productStream;

  @override
  void initState() {
    super.initState();
    // Khởi tạo stream lấy tất cả sản phẩm khi màn hình được tạo
    _productStream = _productService.getAllProducts();
  }

  // Hiển thị hộp thoại xác nhận trước khi xóa sản phẩm
  Future<void> _confirmDelete(ProductModel product) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text("Bạn có chắc chắn muốn xóa sản phẩm '${product.name}' không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    // Nếu người dùng xác nhận thì gọi hàm xóa sản phẩm
    if (confirm == true) {
      await _deleteProduct(product.id);
    }
  }

  // Xóa sản phẩm theo id và hiển thị thông báo SnackBar
  Future<void> _deleteProduct(String id) async {
    await _productService.deleteProduct(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa sản phẩm thành công')),
    );
  }

  // Chuyển sang màn hình sửa sản phẩm, truyền dữ liệu hiện tại vào form
  void _editProduct(ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductFormScreen(product: product),
      ),
    );
  }

  // Chuyển sang màn hình thêm sản phẩm mới
  void _addProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProductFormScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý sản phẩm"),
        backgroundColor: primaryColor,
      ),

      // Nút thêm sản phẩm nổi (Floating Action Button)
      floatingActionButton: FloatingActionButton(
        onPressed: _addProduct,
        backgroundColor: primaryColor,
        child: const Icon(Icons.add),
      ),

      // Lắng nghe stream danh sách sản phẩm để hiển thị
      body: StreamBuilder<List<ProductModel>>(
        stream: _productStream,
        builder: (context, snapshot) {
          // Hiển thị vòng tròn loading khi đang tải dữ liệu
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Lấy danh sách sản phẩm từ snapshot
          final products = snapshot.data ?? [];

          // Nếu không có sản phẩm nào thì hiển thị thông báo trống
          if (products.isEmpty) {
            return const Center(
              child: Text("Chưa có sản phẩm nào"),
            );
          }

          // Hiển thị danh sách sản phẩm bằng ListView
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 2,
                child: ListTile(
                  // Hiển thị ảnh sản phẩm (nếu có) hoặc icon thay thế
                  leading: product.imageUrl.isNotEmpty
                      ? Image.network(
                          product.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image_not_supported),

                  // Hiển thị tên sản phẩm
                  title: Text(product.name),

                  // Hiển thị danh mục và giá sản phẩm
                  subtitle: Text(
                    "${product.category} • ${product.price.toStringAsFixed(0)}đ",
                    style: const TextStyle(color: Colors.black54),
                  ),

                  // Các nút hành động: sửa hoặc xóa
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => _editProduct(product),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(product),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
