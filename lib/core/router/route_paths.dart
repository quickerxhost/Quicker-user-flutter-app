/// Central registry of route paths (used by [AppRouter] and `context.go(...)`
/// calls throughout the app) so no screen hardcodes a path string.
abstract final class RoutePaths {
  static const splash = '/splash';

  // Onboarding
  static const onboarding = '/onboarding';

  // Notifications
  static const notificationPermission = '/notifications/permission';

  // Auth
  static const login = '/auth/login';
  static const otpVerification = '/auth/otp';
  static const registration = '/auth/register';

  // Home shell + tabs
  static const home = '/home';
  static const search = '/search';
  static const voiceSearch = '/voice-search';
  static const barcodeScanner = '/barcode-scanner';
  static const orders = '/orders';
  static const profile = '/profile';

  // Categories / Product listing
  static const categories = '/categories';
  static const productListing = '/products';

  // Phase 2 — Shopping Experience
  static const productDetails = '/product';
  static const wishlist = '/wishlist';
  static const cart = '/cart';
  static const saveForLater = '/save-for-later';
  static const coupons = '/coupons';
  static const checkout = '/checkout';
  static const addressList = '/addresses';
  static const addAddress = '/addresses/add';
  static const editAddress = '/addresses/edit';
  static const paymentMethod = '/payment-method';
  static const orderSuccess = '/order-success';

  // Phase 3 — Restaurant Ordering Module
  static const restaurantHome = '/restaurants';
  static const restaurantDetails = '/restaurant';
  static const foodDetails = '/food';
  static const restaurantCart = '/restaurant-cart';
  static const restaurantCheckout = '/restaurant-checkout';
  static const restaurantPayment = '/restaurant-payment';
  static const restaurantOrderSuccess = '/restaurant-order-success';
  static const restaurantTracking = '/restaurant-tracking';
  static const restaurantOrders = '/restaurant-orders';
  static const restaurantSearch = '/restaurant-search';
  static const restaurantReviews = '/restaurant-reviews';
}
