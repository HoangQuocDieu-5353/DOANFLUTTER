import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cuahanghoa_flutter/constants.dart';
import 'package:cuahanghoa_flutter/services/user_service.dart';
import 'package:cuahanghoa_flutter/models/user_model.dart';
import 'package:cuahanghoa_flutter/route/screen_export.dart';
import 'components/profile_card.dart';
import 'components/profile_menu_item_list_tile.dart';
import 'package:cuahanghoa_flutter/components/list_tile/divider_list_tile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userService = UserService();

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text("Bạn chưa đăng nhập", style: TextStyle(fontSize: 16)),
        ),
      );
    }

    return Scaffold(
      body: StreamBuilder<UserModel?>(
        stream: userService.listenToUser(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;

          if (user == null) {
            return const Center(child: Text("Không tìm thấy thông tin người dùng"));
          }

          return DefaultTextStyle(
            style: GoogleFonts.poppins(textStyle: const TextStyle(fontSize: 14, height: 1.3)),
            child: ListView(
              children: [
                ProfileCard(
                  name: user.name,
                  email: user.email,
                  imageSrc: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                      ? user.avatarUrl!
                      : "assets/images/man.png",
                  press: () {
                    Navigator.pushNamed(context, userInfoScreenRoute);
                  },
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                  child: Text(
                    "Tài khoản",
                    style: GoogleFonts.poppins(
                      textStyle: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ),
                const SizedBox(height: defaultPadding / 2),

                ProfileMenuListTile(
                  text: "Đơn hàng",
                  svgSrc: "assets/icons/Order.svg",
                  press: () {
                    Navigator.pushNamed(context, ordersScreenRoute1);
                  },
                ),
                ProfileMenuListTile(
                  text: "Trả hàng",
                  svgSrc: "assets/icons/Return.svg",
                  press: () {
                    Navigator.pushNamed(context, returnOrderScreenRoute);
                  },
                ),
                ProfileMenuListTile(
                  text: "Yêu thích",
                  svgSrc: "assets/icons/Wishlist.svg",
                  press: () {
                    Navigator.pushNamed(context, bookmarkScreenRoute);
                  },
                ),
                DividerListTileWithTrilingText(
                  svgSrc: "assets/icons/Notification.svg",
                  title: "Thông báo",
                  trilingText: user.notificationsEnabled ? "Bật" : "Tắt",
                  press: () async {
                    final newStatus = !user.notificationsEnabled;
                    await userService.toggleNotificationSetting(user.id, newStatus);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          newStatus
                              ? "Đã bật thông báo"
                              : "Đã tắt thông báo",
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),

              

                const SizedBox(height: defaultPadding),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: defaultPadding, vertical: defaultPadding / 2),
                  child: Text(
                    "Cài đặt",
                    style: GoogleFonts.poppins(
                      textStyle: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ),
                ProfileMenuListTile(
                  text: "Ngôn ngữ",
                  svgSrc: "assets/icons/Language.svg",
                  press: () {
                    Navigator.pushNamed(context, selectLanguageScreenRoute);
                  },
                ),
                

                const SizedBox(height: defaultPadding),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: defaultPadding, vertical: defaultPadding / 2),
                  child: Text(
                    "Hỗ trợ",
                    style: GoogleFonts.poppins(
                      textStyle: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ),
                ProfileMenuListTile(
                  text: "Trợ giúp",
                  svgSrc: "assets/icons/Help.svg",
                  press: () {
                    Navigator.pushNamed(context, getHelpScreenRoute);
                  },
                ),
                ProfileMenuListTile(
                  text: "Câu hỏi thường gặp",
                  svgSrc: "assets/icons/FAQ.svg",
                  press: () {},
                  isShowDivider: false,
                ),

                const SizedBox(height: defaultPadding),

                ListTile(
                  onTap: () async {
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Xác nhận"),
                        content: const Text("Bạn có chắc chắn muốn đăng xuất không?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Hủy"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Đăng xuất"),
                          ),
                        ],
                      ),
                    );

                    if (shouldLogout == true) {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          logInScreenRoute,
                          (route) => false,
                        );
                      }
                    }
                  },
                  minLeadingWidth: 24,
                  leading: SvgPicture.asset(
                    "assets/icons/Logout.svg",
                    height: 24,
                    width: 24,
                    colorFilter: const ColorFilter.mode(errorColor, BlendMode.srcIn),
                  ),
                  title: Text(
                    "Đăng xuất",
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(color: errorColor, fontSize: 14, height: 1),
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
