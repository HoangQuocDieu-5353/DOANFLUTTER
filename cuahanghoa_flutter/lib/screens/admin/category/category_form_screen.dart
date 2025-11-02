import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:uuid/uuid.dart';
import '../../../models/category_model.dart';
import '../../../services/category_service.dart';
import '../../../constants.dart';

class CategoryFormScreen extends StatefulWidget {
  final CategoryModel? category;
  const CategoryFormScreen({super.key, this.category});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = CategoryService();

  late TextEditingController _nameController;
  late TextEditingController _descController;

  // Image picker + Cloudinary setup
  final _picker = ImagePicker();
  final _cloudinary = CloudinaryPublic(
    'dtwpzu5yb', // Cloud name
    'flutter_unsigned', // Upload preset
    cache: false,
  );

  File? _imageFile;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _descController = TextEditingController(text: widget.category?.description ?? '');
  }

  /// Chọn ảnh từ thư viện
  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chọn ảnh: $e')),
      );
    }
  }

  /// Lưu hoặc cập nhật danh mục
  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    // Nếu thêm mới mà chưa có ảnh
    if (widget.category == null && _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ảnh cho danh mục')),
      );
      return;
    }

    setState(() => _isSaving = true);

    String imageUrl = widget.category?.imageUrl ?? '';
    final id = widget.category?.id ?? const Uuid().v4();

    // Upload ảnh nếu có chọn mới
    if (_imageFile != null) {
      try {
        final response = await _cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            _imageFile!.path,
            folder: 'categories',
            publicId: id,
            resourceType: CloudinaryResourceType.Image,
          ),
        );
        imageUrl = response.secureUrl;
      } catch (e) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi upload ảnh: $e')),
        );
        return;
      }
    }

    final newCategory = CategoryModel(
      id: id,
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      imageUrl: imageUrl,
    );

    await _service.addOrUpdateCategory(newCategory);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.category == null
              ? 'Đã thêm danh mục thành công'
              : 'Đã cập nhật danh mục thành công'),
        ),
      );
      Navigator.pop(context);
    }

    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Sửa danh mục' : 'Thêm danh mục'),
        backgroundColor: primaryColor,
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // 🖼️ Chọn ảnh
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
                            if (_imageFile != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _imageFile!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            else if (widget.category?.imageUrl != null &&
                                widget.category!.imageUrl.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  widget.category!.imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            else
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo,
                                      size: 50, color: Colors.grey[600]),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Chọn ảnh danh mục",
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                            if (_imageFile != null ||
                                (widget.category?.imageUrl != null &&
                                    widget.category!.imageUrl.isNotEmpty))
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit,
                                      color: Colors.white, size: 20),
                                ),
                              )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _nameController,
                      decoration:
                          const InputDecoration(labelText: 'Tên danh mục'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Nhập tên danh mục' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descController,
                      decoration:
                          const InputDecoration(labelText: 'Mô tả danh mục'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _saveCategory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: Text(
                        isEditing ? 'Cập nhật' : 'Thêm mới',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
