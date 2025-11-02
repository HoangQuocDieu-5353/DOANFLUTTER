import 'package:flutter/material.dart';
import 'package:cuahanghoa_flutter/screens/admin/admin_dashboard_screen.dart';
import '../../../entry_point.dart';
import 'package:cuahanghoa_flutter/screens/product/views/product_by_category_screen.dart';
import 'screen_export.dart';
import 'package:cuahanghoa_flutter/screens/order/views/return_details_screen.dart';
import 'package:cuahanghoa_flutter/screens/notifications/views/notifications_screen.dart';
import 'package:cuahanghoa_flutter/screens/admin/orders/admin_all_orders_screen.dart';
import 'package:cuahanghoa_flutter/screens/admin/reviews/review_management_screen.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case adminOrdersScreenRoute:
      return MaterialPageRoute(
        builder: (_) => const AdminAllOrdersScreen(),
      );
    case logInScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      );
    case signUpScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const SignUpScreen(),
      );
    case reviewManagementScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const ReviewManagementScreen(),
      );
    case passwordRecoveryScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const PasswordRecoveryScreen(),
      );
  case productDetailsScreenRoute:
  return MaterialPageRoute(
    builder: (context) {
      final String productId = settings.arguments as String;
      return ProductDetailScreen(productId: productId);
    },
  );
  case productByCategoryScreenRoute:
  final categoryName = settings.arguments as String;
  return MaterialPageRoute(
    builder: (_) => ProductByCategoryScreen(categoryName: categoryName),
  );
    case productReviewsScreenRoute:
    final String productId = settings.arguments as String;
    return MaterialPageRoute(
      builder: (context) => ProductReviewsScreen(
        productId: productId,
      ),
    );
    case homeScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      );
    case discoverScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const DiscoverScreen(),
      );
    
    
    case searchScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const SearchScreen(),
      );
    case bookmarkScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const BookmarkScreen(),
      );
    case entryPointScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const EntryPoint(),
      );
    case profileScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const ProfileScreen(),
      );
    case userInfoScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const UserInfoScreen(),
      );
    case ordersScreenRoute1: 
      return MaterialPageRoute(
        builder: (context) => const OrderScreen(), 
      );
    case ordersScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const OrderSuccessScreen(),
      );
    case returnOrderScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const ReturnScreen(),
      );
    case returnDetailsScreenRoute:
      final orderId = settings.arguments as String;
      return MaterialPageRoute(
        builder: (_) => ReturnDetailsScreen(orderId: orderId),
      );
    case cartScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const CartScreen(),
      );
      case adminDashboardScreenRoute:
      return MaterialPageRoute(
        builder: (_) => const AdminDashboardScreen(),
      );
      case notificationsScreenRoute:
  return MaterialPageRoute(
    builder: (context) => const NotificationsScreen(),
  );
    default:
      return MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      );
  }
}
