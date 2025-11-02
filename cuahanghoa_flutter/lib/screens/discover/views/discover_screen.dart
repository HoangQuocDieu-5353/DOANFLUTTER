import 'package:flutter/material.dart';
import 'package:cuahanghoa_flutter/constants.dart';
import 'package:cuahanghoa_flutter/models/category_model.dart';
import 'package:cuahanghoa_flutter/screens/search/views/search_screen.dart'; 
import 'package:cuahanghoa_flutter/screens/search/views/components/search_form.dart';
import 'package:cuahanghoa_flutter/services/category_service.dart';
import 'components/expansion_category.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryService = CategoryService();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //  Ô tìm kiếm (chuyển sang màn Search khi bấm)
            Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  );
                },
                child: const AbsorbPointer(
                  child: SearchForm(),
                ),
              ),
            ),

            // Tiêu đề "Categories"
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: defaultPadding,
                vertical: defaultPadding / 2,
              ),
              child: Text(
                "Categories",
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),

            //  Danh sách category (realtime từ Firebase)
            Expanded(
              child: StreamBuilder<List<CategoryModel>>(
                stream: categoryService.getAllCategories(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Lỗi tải dữ liệu: ${snapshot.error}",
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  final categories = snapshot.data ?? [];

                  if (categories.isEmpty) {
                    return const Center(child: Text("Chưa có danh mục nào"));
                  }

                  return ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return ExpansionCategory(
                        svgSrc: category.imageUrl,
                        title: category.name,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
