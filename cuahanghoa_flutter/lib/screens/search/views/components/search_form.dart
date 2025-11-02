import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cuahanghoa_flutter/theme/input_decoration_theme.dart'; // Đảm bảo import đúng

class SearchForm extends StatelessWidget {
  const SearchForm({
    super.key,
    this.controller, // ⬅️ 1. THÊM CONTROLLER
    this.formKey,
    this.isEnabled = true,
    this.onSaved,
    this.validator,
    this.onChanged,
    this.onTabFilter,
    this.onFieldSubmitted,
    this.focusNode,
    this.autofocus = false,
  });

  final TextEditingController? controller; // ⬅️ 2. KHAI BÁO
  final GlobalKey<FormState>? formKey;
  final bool isEnabled;
  final ValueChanged<String?>? onSaved, onChanged, onFieldSubmitted;
  final FormFieldValidator<String>? validator;
  final VoidCallback? onTabFilter;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey, // ⬅️ Sửa: Gán formKey vào Form
      child: TextFormField(
        controller: controller, // ⬅️ 3. SỬ DỤNG CONTROLLER
        autofocus: autofocus,
        focusNode: focusNode,
        enabled: isEnabled,
        onChanged: onChanged,
        onSaved: onSaved,
        onFieldSubmitted: onFieldSubmitted,
        validator: validator,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: "Tìm kiếm hoa...", // ⬅️ Sửa hint text
          filled: false,
          border: secodaryOutlineInputBorder(context),
          enabledBorder: secodaryOutlineInputBorder(context),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: SvgPicture.asset(
              "assets/icons/Search.svg", // Đảm bảo có file icon
              height: 24,
              // 🎨 Sửa: Dùng colorScheme.onSurface.withOpacity(0.3)
              colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  BlendMode.srcIn),
            ),
          ),
          suffixIcon: SizedBox(
            width: 40,
            child: Row(
              children: [
                const SizedBox(
                  height: 24,
                  child: VerticalDivider(width: 1),
                ),
                Expanded(
                  child: IconButton(
                    onPressed: onTabFilter,
                    icon: SvgPicture.asset(
                      "assets/icons/Filter.svg", // Đảm bảo có file icon
                      height: 24,
                      // 🎨 Sửa: Dùng colorScheme.onSurface
                      colorFilter: ColorFilter.mode(
                          Theme.of(context).colorScheme.onSurface,
                          BlendMode.srcIn),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}