import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:cuahanghoa_flutter/models/user_model.dart';
import 'package:cuahanghoa_flutter/services/user_service.dart';
import 'package:intl/intl.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();

  //  Cloudinary config
  final cloudinary = CloudinaryPublic(
    'dtwpzu5yb', // Cloud Name
    'flutter_unsigned', // Upload preset
    cache: false,
  );

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _dobController;
  DateTime? _selectedDateOfBirth;
  String? _selectedGender;

  File? _imageFile;
  bool _isSaving = false;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _addressController = TextEditingController(text: widget.user.address ?? '');
    _selectedDateOfBirth = widget.user.dateOfBirth;

    //  Chuẩn hóa giới tính để Dropdown hiển thị đúng
    final initialGender = widget.user.gender?.trim();
    if (['Nam', 'Nữ', 'Khác'].contains(initialGender)) {
      _selectedGender = initialGender;
    } else {
      _selectedGender = null;
    }

    _dobController = TextEditingController(
      text: _formatDate(widget.user.dateOfBirth),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    try {
      setState(() => _isPickingImage = true);
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Lỗi chọn ảnh: $e")));
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<void> _pickDateOfBirth() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDateOfBirth = pickedDate;
        _dobController.text = _formatDate(pickedDate);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    String avatarUrl = widget.user.avatarUrl ?? '';

    //  Upload ảnh mới lên Cloudinary nếu có
    if (_imageFile != null) {
      try {
        CloudinaryResponse response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            _imageFile!.path,
            folder: 'avatars',
            publicId: widget.user.id,
            resourceType: CloudinaryResourceType.Image,
          ),
        );
        avatarUrl = response.secureUrl;
        print(' Upload Cloudinary thành công: $avatarUrl');
      } on CloudinaryException catch (e) {
        print(' Lỗi Upload Cloudinary: ${e.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Lỗi upload ảnh: ${e.message}")),
          );
          setState(() => _isSaving = false);
          return;
        }
      } catch (e) {
        print('❌ Lỗi Upload không xác định: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Lỗi upload ảnh: $e")),
          );
          setState(() => _isSaving = false);
          return;
        }
      }
    }

    final updates = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'avatarUrl': avatarUrl,
      'gender': _selectedGender?.trim(),
      'dateOfBirth': _selectedDateOfBirth?.toIso8601String(),
    };

    try {
      await _userService.updateUser(widget.user.id, updates);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cập nhật thành công!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Cập nhật thất bại: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = GoogleFonts.inter();
    final inputStyle = GoogleFonts.inter(fontWeight: FontWeight.w500);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Chỉnh sửa Hồ sơ",
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundImage: _imageFile != null
                                  ? FileImage(_imageFile!)
                                  : (widget.user.avatarUrl != null &&
                                          widget.user.avatarUrl!.isNotEmpty
                                      ? NetworkImage(widget.user.avatarUrl!)
                                      : const AssetImage('assets/icons/man.png'))
                                      as ImageProvider,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: Theme.of(context).primaryColor,
                                child: const Icon(Icons.camera_alt,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _nameController,
                      style: inputStyle,
                      decoration: InputDecoration(
                        labelText: "Tên",
                        labelStyle: labelStyle,
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? "Nhập tên" : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _dobController,
                      readOnly: true,
                      style: inputStyle,
                      decoration: InputDecoration(
                        labelText: "Ngày sinh",
                        labelStyle: labelStyle,
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                      onTap: _pickDateOfBirth,
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      initialValue: _selectedGender,
                      isExpanded: true,
                      style: GoogleFonts.inter(
                        fontSize: 16,             
                        color: Colors.black87,    
                        fontWeight: FontWeight.w600,
                      ),
                      hint: Text(
                        "Chọn giới tính",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                      decoration: InputDecoration(
                        labelText: "Giới tính",
                        labelStyle: GoogleFonts.inter(fontSize: 15),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      items: <String>['Nam', 'Nữ', 'Khác'].map((value) {
                        IconData icon;
                        if (value == 'Nam') {
                          icon = Icons.male;
                        } else if (value == 'Nữ') {
                          icon = Icons.female;
                        } else {
                          icon = Icons.transgender;
                        }
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Row(
                            children: [
                              Icon(icon, size: 20, color: Colors.grey[800]),
                              const SizedBox(width: 8),
                              Text(value),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) => setState(() => _selectedGender = newValue),
                      validator: (value) =>
                          value == null ? 'Vui lòng chọn giới tính' : null,
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _phoneController,
                      style: inputStyle,
                      decoration: InputDecoration(
                        labelText: "Số điện thoại",
                        labelStyle: labelStyle,
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _addressController,
                      style: inputStyle,
                      decoration: InputDecoration(
                        labelText: "Địa chỉ",
                        labelStyle: labelStyle,
                      ),
                    ),
                    const SizedBox(height: 30),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _saveProfile,
                      child: Text(
                        "Lưu thay đổi",
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    super.dispose();
  }
}
