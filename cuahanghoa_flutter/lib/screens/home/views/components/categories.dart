import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cuahanghoa_flutter/constants.dart';
import 'package:cuahanghoa_flutter/models/category_model.dart';
import 'package:cuahanghoa_flutter/services/category_service.dart';
import 'package:cuahanghoa_flutter/screens/product/views/product_by_category_screen.dart';

class Categories extends StatefulWidget {
  const Categories({super.key});

  @override
  State<Categories> createState() => _CategoriesState();
}

class _CategoriesState extends State<Categories> {
  final CategoryService _categoryService = CategoryService();
  List<CategoryModel> categories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    _categoryService.getAllCategories().listen((data) {
      setState(() {
        categories = data;
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(defaultPadding),
        child: Text("Không có danh mục nào."),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: defaultPadding, vertical: 8),
          child: Text(
            "Danh mục",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(
              categories.length,
              (index) {
                final category = categories[index];
                return Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? defaultPadding : defaultPadding / 2,
                    right: index == categories.length - 1 ? defaultPadding : 0,
                  ),
                  child: CategoryBtn(
                    category: category.name,
                    svgSrc: category.imageUrl,
                    isActive: false,
                    press: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductByCategoryScreen(
                            categoryName: category.name,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class CategoryBtn extends StatelessWidget {
  const CategoryBtn({
    super.key,
    required this.category,
    this.svgSrc,
    required this.isActive,
    required this.press,
  });

  final String category;
  final String? svgSrc;
  final bool isActive;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: press,
      borderRadius: const BorderRadius.all(Radius.circular(40)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFF74EBD5), Color(0xFFACB6E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isActive ? null : Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: isActive ? Colors.transparent : Colors.grey.shade300,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (svgSrc != null && svgSrc!.isNotEmpty)
              _buildIcon(svgSrc!, isActive, context),
            if (svgSrc != null && svgSrc!.isNotEmpty)
              const SizedBox(width: 6),
            Text(
              category,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(String url, bool isActive, BuildContext context) {
    final isSvg = url.endsWith(".svg");
    if (isSvg) {
      return SvgPicture.network(
        url,
        height: 22,
        width: 22,
        placeholderBuilder: (_) =>
            const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 1)),
        colorFilter: ColorFilter.mode(
          isActive ? Colors.white : Colors.black87,
          BlendMode.srcIn,
        ),
      );
    } else {
      return Image.network(
        url,
        height: 24,
        width: 24,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.category, color: isActive ? Colors.white : Colors.grey),
      );
    }
  }
}
