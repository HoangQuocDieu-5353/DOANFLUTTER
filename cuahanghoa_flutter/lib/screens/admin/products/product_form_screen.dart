import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'package:image_picker/image_picker.dart'; 
import 'package:cloudinary_public/cloudinary_public.dart'; 
import 'package:cuahanghoa_flutter/models/product_model.dart';
import 'package:cuahanghoa_flutter/models/category_model.dart';
import 'package:cuahanghoa_flutter/services/product_service.dart';
import 'package:cuahanghoa_flutter/services/category_service.dart';
import 'package:cuahanghoa_flutter/constants.dart';
import 'package:uuid/uuid.dart';

class ProductFormScreen extends StatefulWidget {
  final ProductModel? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productService = ProductService();
  final _categoryService = CategoryService();

  // Khởi tạo công cụ chọn ảnh và Cloudinary để lưu ảnh
  final _picker = ImagePicker();
  final _cloudinary = CloudinaryPublic(
    'dtwpzu5yb', 
    'flutter_unsigned',
    cache: false,
  );

  // Các controller cho từng trường nhập liệu
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;

  // Biến trạng thái
  File? _imageFile;
  bool _isBestSeller = false;
  bool _isNew = false;
  bool _isPopular = false;
  bool _isLoadingCategories = true;
  bool _isUploading = false;

  // Danh mục sản phẩm
  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;

  @override
  void initState() {
    super.initState();
    final p = widget.product;

    // Gán dữ liệu ban đầu nếu là chỉnh sửa, hoặc để trống nếu thêm mới
    _nameController = TextEditingController(text: p?.name ?? '');
    _descController = TextEditingController(text: p?.description ?? '');
    _priceController = TextEditingController(text: p?.price.toString() ?? '');
    _stockController = TextEditingController(text: p?.stock.toString() ?? '');
    _isBestSeller = p?.isBestSeller ?? false;
    _isNew = p?.isNew ?? false;
    _isPopular = p?.isPopular ?? false;

    _loadCategories();
  }

  // Lấy danh sách danh mục từ cơ sở dữ liệu
  void _loadCategories() {
    _categoryService.getAllCategories().listen((list) {
      if (!mounted) return;
      setState(() {
        _categories = list;
        _isLoadingCategories = false;

        // Tự động chọn danh mục cũ khi chỉnh sửa sản phẩm
        if (widget.product != null && list.isNotEmpty) {
          try {
            _selectedCategory = list.firstWhere(
              (cat) => cat.name == widget.product!.category,
            );
          } catch (e) {
            print("Warning: Category '${widget.product!.category}' not found.");
            _selectedCategory = null;
          }
        }
      });
    });
  }
  
  // Mở thư viện ảnh để người dùng chọn ảnh mới
  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi chọn ảnh: $e")),
        );
      }
    }
  }

  // Lưu hoặc cập nhật thông tin sản phẩm
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn danh mục')),
      );
      return;
    }

    // Kiểm tra nếu sản phẩm mới mà chưa có ảnh
    if (widget.product == null && _imageFile == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thêm ảnh cho sản phẩm mới')),
      );
      return;
    }

    setState(() => _isUploading = true);

    String imageUrlToSave = widget.product?.imageUrl ?? '';
    final productId = widget.product?.id ?? const Uuid().v4();

    // Upload ảnh lên Cloudinary (nếu có chọn ảnh mới)
    if (_imageFile != null) {
      try {
        final response = await _cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            _imageFile!.path,
            folder: 'products',
            publicId: productId,
            resourceType: CloudinaryResourceType.Image,
          ),
        );
        imageUrlToSave = response.secureUrl;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Lỗi upload ảnh: $e")),
          );
        }
        setState(() => _isUploading = false);
        return;
      }
    }

    // Tạo đối tượng ProductModel mới để lưu vào database
    final newProduct = ProductModel(
      id: productId,
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      price: double.tryParse(_priceController.text) ?? 0.0,
      imageUrl: imageUrlToSave,
      stock: int.tryParse(_stockController.text) ?? 0,
      category: _selectedCategory!.name,
      isBestSeller: _isBestSeller,
      isNew: _isNew,
      isPopular: _isPopular,
    );

    await _productService.addOrUpdateProduct(newProduct);

    if (mounted) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.product == null
              ? 'Thêm sản phẩm thành công'
              : 'Cập nhật sản phẩm thành công'),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Thêm sản phẩm' : 'Sửa sản phẩm'),
        backgroundColor: primaryColor,
      ),

      // Hiển thị trạng thái loading khi đang tải danh mục hoặc đang lưu
      body: _isLoadingCategories || _isUploading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _isUploading ? "Đang lưu sản phẩm..." : "Đang tải danh mục...",
                    style: GoogleFonts.inter(fontSize: 16),
                  ),
                ],
              ),
            )

          // Giao diện chính của form nhập sản phẩm
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Khu vực hiển thị hoặc chọn ảnh sản phẩm
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Hiển thị ảnh mới chọn, ảnh cũ hoặc placeholder
                            if (_imageFile != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _imageFile!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            else if (widget.product?.imageUrl != null && widget.product!.imageUrl.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  widget.product!.imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            else
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, size: 50, color: Colors.grey[600]),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Chọn ảnh sản phẩm",
                                    style: GoogleFonts.inter(color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                            
                            // Hiển thị biểu tượng chỉnh sửa nếu đã có ảnh
                            if (_imageFile != null || (widget.product?.imageUrl != null && widget.product!.imageUrl.isNotEmpty))
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit, color: Colors.white, size: 20),
                                ),
                              )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Các trường nhập dữ liệu sản phẩm
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Tên sản phẩm'),
                      validator: (v) => v!.isEmpty ? 'Nhập tên sản phẩm' : null,
                    ),
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(labelText: 'Mô tả'),
                      maxLines: 3,
                    ),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Giá bán (VNĐ)'),
                      validator: (v) => (double.tryParse(v!) ?? 0) <= 0 ? 'Giá phải lớn hơn 0' : null,
                    ),
                    TextFormField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Số lượng tồn'),
                      validator: (v) => (int.tryParse(v!) ?? 0) < 0 ? 'Số lượng không hợp lệ' : null,
                    ),
                    
                    const SizedBox(height: 16),

                    // Dropdown chọn danh mục sản phẩm
                    DropdownButtonFormField<CategoryModel>(
                      initialValue: _selectedCategory,
                      hint: const Text('Chọn danh mục'),
                      items: _categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Vui lòng chọn danh mục' : null,
                    ),

                    const SizedBox(height: 12),

                    // Các tùy chọn trạng thái của sản phẩm
                    CheckboxListTile(
                      title: const Text('Sản phẩm bán chạy'),
                      value: _isBestSeller,
                      onChanged: (v) => setState(() => _isBestSeller = v ?? false),
                    ),
                    CheckboxListTile(
                      title: const Text('Sản phẩm mới'),
                      value: _isNew,
                      onChanged: (v) => setState(() => _isNew = v ?? false),
                    ),
                    CheckboxListTile(
                      title: const Text('Phổ biến'),
                      value: _isPopular,
                      onChanged: (v) => setState(() => _isPopular = v ?? false),
                    ),

                    const SizedBox(height: 20),

                    // Nút lưu sản phẩm
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: Text(
                        'Lưu sản phẩm', 
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)
                      ),
                      onPressed: _saveProduct,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
