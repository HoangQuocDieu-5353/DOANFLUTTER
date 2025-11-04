import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cuahanghoa_flutter/services/category_service.dart'; 
import 'package:cuahanghoa_flutter/models/category_model.dart'; 

// Lớp để chứa các giá trị lọc
class FilterOptions {
  final double? minPrice;
  final double? maxPrice;
  final String? category;

  FilterOptions({this.minPrice, this.maxPrice, this.category});
}

class FilterBottomSheet extends StatefulWidget {
  final FilterOptions currentFilters;

  const FilterBottomSheet({super.key, required this.currentFilters});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  String? _selectedCategory;

  final CategoryService _categoryService = CategoryService();
  // (Không cần Future nữa vì chúng ta dùng Stream)

  @override
  void initState() {
    super.initState();
    _minPriceController = TextEditingController(
        text: widget.currentFilters.minPrice?.toStringAsFixed(0) ?? '');
    _maxPriceController = TextEditingController(
        text: widget.currentFilters.maxPrice?.toStringAsFixed(0) ?? '');
    _selectedCategory = widget.currentFilters.category;
    
    // (Không cần gọi Future ở đây nữa)
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final double? minPrice = double.tryParse(_minPriceController.text);
    final double? maxPrice = double.tryParse(_maxPriceController.text);
    
    final newFilters = FilterOptions(
      minPrice: minPrice,
      maxPrice: maxPrice,
      category: _selectedCategory,
    );
    
    Navigator.pop(context, newFilters);
  }

  void _clearFilters() {
     _minPriceController.clear();
     _maxPriceController.clear();
     setState(() => _selectedCategory = null);
     Navigator.pop(context, FilterOptions());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Bộ lọc",
                  style: GoogleFonts.inter(
                      fontSize: 20, fontWeight: FontWeight.w600),
                ),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text("Xóa tất cả", style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
            const Divider(height: 24),

            Text("Khoảng giá (VNĐ)",
                style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Từ",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _maxPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Đến",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text("Danh mục",
                style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            StreamBuilder<List<CategoryModel>>( // Đổi sang StreamBuilder
              stream: _categoryService.getAllCategories(), // Gọi hàm stream của bạn
              builder: (context, snapshot) {
                // Đang tải
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Bị lỗi
                if (snapshot.hasError) {
                  return Text("Lỗi tải danh mục: ${snapshot.error}", 
                          style: const TextStyle(color: Colors.red));
                }
                // Không có data
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text("Không tìm thấy danh mục nào.");
                }

                // Tải thành công
                final categories = snapshot.data!;
                
                // (Kiểm tra xem _selectedCategory có còn tồn tại trong list không)
                if (_selectedCategory != null && !categories.any((c) => c.name == _selectedCategory)) {
                   _selectedCategory = null;
                }
                
                return DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  hint: const Text("Chọn danh mục"),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  // Tạo item từ danh sách CategoryModel
                  items: categories.map((category) { 
                    return DropdownMenuItem(
                      value: category.name, // Value là tên
                      child: Text(category.name), // Hiển thị cũng là tên
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategory = value);
                  },
                );
              },
            ),            
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Áp dụng"),
            ),
          ],
        ),
      ),
    );
  }
}