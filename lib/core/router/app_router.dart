import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/search_and_nav_widgets.dart';
import '../../features/authentication/presentation/login_screen.dart';
import '../../features/authentication/presentation/otp_verification_screen.dart';
import '../../features/authentication/presentation/registration_screen.dart';
import '../../features/address/domain/models/address_model.dart';
import '../../features/address/presentation/add_edit_address_screen.dart';
import '../../features/address/presentation/address_list_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/cart/presentation/save_for_later_screen.dart';
import '../../features/categories/presentation/category_screen.dart';
import '../../features/checkout/domain/models/order_model.dart';
import '../../features/checkout/presentation/checkout_screen.dart';
import '../../features/coupons/presentation/coupon_screen.dart';
import '../../features/food_details/presentation/food_details_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/notifications/presentation/notification_permission_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/orders/presentation/order_success_screen.dart';
import '../../features/orders/presentation/orders_placeholder_screen.dart';
import '../../features/payment/presentation/payment_method_screen.dart';
import '../../features/product_details/presentation/product_details_screen.dart';
import '../../features/home/domain/models/product_model.dart';
import '../../features/product_listing/presentation/product_listing_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/restaurant_cart/presentation/restaurant_cart_screen.dart';
import '../../features/restaurant_checkout/presentation/restaurant_checkout_screen.dart';
import '../../features/restaurant_menu/presentation/restaurant_details_screen.dart';
import '../../features/restaurant_orders/domain/models/restaurant_order_model.dart';
import '../../features/restaurant_orders/presentation/restaurant_order_success_screen.dart';
import '../../features/restaurant_orders/presentation/restaurant_orders_screen.dart';
import '../../features/restaurant_orders/presentation/restaurant_tracking_screen.dart';
import '../../features/restaurant_payment/presentation/restaurant_payment_screen.dart';
import '../../features/restaurant_reviews/presentation/restaurant_reviews_screen.dart';
import '../../features/restaurant_search/presentation/restaurant_search_screen.dart';
import '../../features/restaurants/presentation/restaurant_home_screen.dart';
import '../../features/search/presentation/barcode_scanner_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/search/presentation/voice_search_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/wishlist/presentation/wishlist_screen.dart';
import 'route_paths.dart';

/// App-wide router. Auth/onboarding/location flows are plain top-level
/// routes; Home/Search/Orders/Profile live inside a [StatefulShellRoute] so
/// the bottom nav bar + each tab's own Navigator stack persist correctly.
abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ---- Notification permission ----
      GoRoute(
        path: RoutePaths.notificationPermission,
        builder: (context, state) => const NotificationPermissionScreen(),
      ),

      // ---- Auth flow ----
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.otpVerification,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return OtpVerificationScreen(
            phoneNumber: extra?['phoneNumber'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: RoutePaths.registration,
        builder: (context, state) => const RegistrationScreen(),
      ),

      // ---- Categories / Product listing (pushed from Home) ----
      GoRoute(
        path: RoutePaths.categories,
        builder: (context, state) => const CategoryScreen(),
      ),
      GoRoute(
        path: RoutePaths.productListing,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ProductListingScreen(
            categoryId: extra?['categoryId'] as String?,
            categoryName: extra?['categoryName'] as String? ?? 'Products',
          );
        },
      ),

      // ---- Voice search / Barcode scanner (modal-style pushes) ----
      GoRoute(
        path: RoutePaths.voiceSearch,
        builder: (context, state) => const VoiceSearchScreen(),
      ),
      GoRoute(
        path: RoutePaths.barcodeScanner,
        builder: (context, state) => const BarcodeScannerScreen(),
      ),

      // ---- Phase 2: Shopping Experience ----
      GoRoute(
        path: '${RoutePaths.productDetails}/:id',
        builder: (context, state) => ProductDetailsScreen(
          productId: state.pathParameters['id']!,
          product: state.extra as ProductModel?,
        ),
      ),
      GoRoute(
        path: RoutePaths.wishlist,
        builder: (context, state) => const WishlistScreen(),
      ),
      GoRoute(
        path: RoutePaths.cart,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CartScreen(),
          transitionDuration: const Duration(milliseconds: 380),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
            return SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(curved),
              child: FadeTransition(opacity: curved, child: child),
            );
          },
        ),
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: RoutePaths.saveForLater,
        builder: (context, state) => const SaveForLaterScreen(),
      ),
      GoRoute(
        path: RoutePaths.coupons,
        builder: (context, state) => const CouponScreen(),
      ),
      GoRoute(
        path: RoutePaths.checkout,
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: RoutePaths.addressList,
        builder: (context, state) => const AddressListScreen(selectionMode: true),
      ),
      GoRoute(
        path: RoutePaths.addAddress,
        builder: (context, state) => AddEditAddressScreen(existing: state.extra as AddressModel?),
      ),
      GoRoute(
        path: RoutePaths.editAddress,
        builder: (context, state) => AddEditAddressScreen(existing: state.extra as AddressModel?),
      ),
      GoRoute(
        path: RoutePaths.paymentMethod,
        builder: (context, state) => const PaymentMethodScreen(),
      ),
      GoRoute(
        path: RoutePaths.orderSuccess,
        builder: (context, state) => OrderSuccessScreen(order: state.extra as OrderModel),
      ),

      // ---- Phase 3: Restaurant Ordering Module ----
      GoRoute(
        path: RoutePaths.restaurantHome,
        builder: (context, state) => const RestaurantHomeScreen(),
      ),
      GoRoute(
        path: '${RoutePaths.restaurantDetails}/:id',
        builder: (context, state) => RestaurantDetailsScreen(restaurantId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '${RoutePaths.foodDetails}/:id',
        builder: (context, state) => FoodDetailsScreen(foodId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RoutePaths.restaurantCart,
        builder: (context, state) => const RestaurantCartScreen(),
      ),
      GoRoute(
        path: RoutePaths.restaurantCheckout,
        builder: (context, state) => const RestaurantCheckoutScreen(),
      ),
      GoRoute(
        path: RoutePaths.restaurantPayment,
        builder: (context, state) => const RestaurantPaymentScreen(),
      ),
      GoRoute(
        path: RoutePaths.restaurantOrderSuccess,
        builder: (context, state) => RestaurantOrderSuccessScreen(order: state.extra as RestaurantOrderModel),
      ),
      GoRoute(
        path: RoutePaths.restaurantTracking,
        builder: (context, state) => RestaurantTrackingScreen(order: state.extra as RestaurantOrderModel),
      ),
      GoRoute(
        path: RoutePaths.restaurantOrders,
        builder: (context, state) => const RestaurantOrdersScreen(),
      ),
      GoRoute(
        path: RoutePaths.restaurantSearch,
        builder: (context, state) => const RestaurantSearchScreen(),
      ),
      GoRoute(
        path: RoutePaths.restaurantReviews,
        builder: (context, state) => RestaurantReviewsScreen(restaurantId: state.uri.queryParameters['restaurantId'] ?? ''),
      ),

      // ---- Bottom-nav shell: Home / Search / Orders / Profile ----
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: RoutePaths.home, builder: (context, state) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: RoutePaths.search, builder: (context, state) => const SearchScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: RoutePaths.orders, builder: (context, state) => const OrdersPlaceholderScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: RoutePaths.profile, builder: (context, state) => const ProfileScreen()),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Wraps the four bottom-nav tabs in a persistent [Scaffold] +
/// [AppBottomNavBar], preserving each tab's own navigation stack via
/// [StatefulNavigationShell].
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
