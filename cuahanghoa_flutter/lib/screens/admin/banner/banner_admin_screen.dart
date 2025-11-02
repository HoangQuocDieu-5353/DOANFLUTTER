import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:uuid/uuid.dart';
import 'package:cuahanghoa_flutter/services/banner_service.dart';
import 'package:cuahanghoa_flutter/models/banner_model.dart';

class BannerAdminScreen extends StatefulWidget {
  const BannerAdminScreen({super.key});

  @override
  State<BannerAdminScreen> createState() => _BannerAdminScreenState();
}

class _BannerAdminScreenState extends State<BannerAdminScreen> {
  final BannerService _bannerService = BannerService();
  final TextEditingController _linkController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final CloudinaryPublic _cloudinary =
      CloudinaryPublic('dtwpzu5yb', 'flutter_unsigned', cache: false);

  File? _imageFile;
  bool _isUploading = false;

  /// Chọn ảnh từ thư viện
  Future<void> _pickImage() async {
    final picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  /// Upload ảnh và thêm banner
  Future<void> _uploadBanner() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Chọn ảnh trước")));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final bannerId = const Uuid().v4();

      // Upload lên Cloudinary
      final uploadResult = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          _imageFile!.path,
          folder: 'banners',
          publicId: bannerId,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      final newBanner = BannerModel(
        id: bannerId,
        imageUrl: uploadResult.secureUrl,
        link: _linkController.text.trim().isNotEmpty
            ? _linkController.text.trim()
            : null,
        isActive: true,
      );

      await _bannerService.addBanner(newBanner);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Thêm banner thành công")),
      );

      setState(() {
        _imageFile = null;
        _linkController.clear();
        _isUploading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Lỗi upload: $e")),
      );
    }
  }

  /// Xóa banner có xác nhận
  Future<void> _confirmDelete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa banner?"),
        content: const Text("Hành động này không thể hoàn tác."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) await _bannerService.deleteBanner(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quản lý Banner")),
      body: StreamBuilder<List<BannerModel>>(
        stream: _bannerService.streamBanners(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final banners = snapshot.data!;
          banners.sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // thêm banner mới
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: _imageFile != null
                              ? Image.file(_imageFile!, height: 150, fit: BoxFit.cover)
                              : Container(
                                  height: 150,
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Icon(Icons.add_a_photo, size: 40),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _linkController,
                          decoration: const InputDecoration(
                            labelText: "Link (tùy chọn)",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _isUploading ? null : _uploadBanner,
                          icon: _isUploading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.cloud_upload),
                          label: Text(_isUploading ? "Đang tải..." : "Thêm banner mới"),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                //  Danh sách banner
                const Text(
                  "Danh sách banner",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),

                for (final b in banners)
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: GestureDetector(
                        onTap: () => showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            child: InteractiveViewer(
                              child: Image.network(b.imageUrl),
                            ),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            b.imageUrl,
                            width: 80,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade300,
                              width: 80,
                              height: 60,
                              child: const Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                      ),
                      title: Text(b.link ?? "(Không có link)"),
                      subtitle: Text(
                        b.isActive ? "Đang hiển thị" : "Đang ẩn",
                        style: TextStyle(
                          color: b.isActive ? Colors.green : Colors.redAccent,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              b.isActive ? Icons.visibility_off : Icons.visibility,
                              color: Colors.blue,
                            ),
                            tooltip: b.isActive ? "Ẩn banner" : "Hiển thị banner",
                            onPressed: () => _bannerService.toggleBannerStatus(b.id, !b.isActive),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: "Xóa banner",
                            onPressed: () => _confirmDelete(b.id),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
