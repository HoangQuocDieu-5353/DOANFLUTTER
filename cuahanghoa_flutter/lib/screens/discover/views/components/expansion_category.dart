import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cuahanghoa_flutter/constants.dart';
import 'package:cuahanghoa_flutter/models/product_model.dart';
import 'package:cuahanghoa_flutter/services/product_service.dart';
import 'package:intl/intl.dart';
import 'package:cuahanghoa_flutter/route/route_constants.dart';

class ExpansionCategory extends StatefulWidget {
  const ExpansionCategory({
    super.key,
    required this.title,
    required this.svgSrc,
  });

  final String title; // tên danh mục (ví dụ: "Hoa hồng")
  final String svgSrc; // ảnh hoặc icon danh mục

  @override
  State<ExpansionCategory> createState() => _ExpansionCategoryState();
}

class _ExpansionCategoryState extends State<ExpansionCategory> {
  final ProductService _productService = ProductService();
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  bool _isExpanded = false; // trạng thái mở rộng
  late Stream<List<ProductModel>> _productStream;

  @override
  void initState() {
    super.initState();
    // chỉ khởi tạo stream khi mở rộng lần đầu
    _productStream = const Stream.empty();
  }

  void _onExpand(bool expanded) {
    setState(() {
      _isExpanded = expanded;
      if (expanded) {
        _productStream = _productService.getProductsByCategory(widget.title);
      }
    });
  }

  bool get _isSvg => widget.svgSrc.toLowerCase().endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      onExpansionChanged: _onExpand,
      leading: _isSvg
          ? SvgPicture.network(
              widget.svgSrc,
              height: 32,
              width: 32,
              colorFilter: ColorFilter.mode(
                Theme.of(context).iconTheme.color!,
                BlendMode.srcIn,
              ),
            )
          : Image.network(
              widget.svgSrc,
              height: 32,
              width: 32,
              fit: BoxFit.cover,
            ),
      title: Text(
        widget.title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      childrenPadding: const EdgeInsets.only(left: defaultPadding * 3.5),
      iconColor: Theme.of(context).textTheme.bodyLarge!.color,
      collapsedIconColor: Theme.of(context).textTheme.bodyMedium!.color,
      children: _isExpanded
          ? [
              StreamBuilder<List<ProductModel>>(
                stream: _productStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Lỗi khi tải sản phẩm",
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  final products = snapshot.data ?? [];
                  if (products.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("Không có sản phẩm trong danh mục này."),
                    );
                  }

                  return Column(
                    children: products.map((product) {
                      return ListTile(
                        contentPadding: const EdgeInsets.only(left: 8, right: 16),
                        leading: Image.network(
                          product.imageUrl,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 40,
                            height: 40,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image_not_supported),
                          ),
                        ),
                        title: Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          currencyFormatter.format(product.price),
                          style: const TextStyle(color: Colors.red),
                        ),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            productDetailsScreenRoute,
                            arguments: product.id,
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ]
          : [],
    );
  }
}
