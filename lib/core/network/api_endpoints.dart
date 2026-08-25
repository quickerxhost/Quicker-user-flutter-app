/// Every endpoint path used by the app, grouped by feature.
///
/// All paths are prefixed with `/api/v1` by the backend.
/// Fill in these constants when the backend contracts are finalized.
abstract final class ApiEndpoints {
  // ---- Authentication (backend OTP flow) ----
  static const String sendOtp = '/auth/otp/request';
  static const String verifyOtp = '/auth/otp/verify';
  static const String resendOtp = '/auth/otp/request'; // same as send
  static const String register = '/auth/register'; // optional: profile completion
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String changePassword = '/auth/change-password';

  // ---- Home ----
  static const String homeFeed = '/home/feed';
  static const String banners = '/home/banners';
  static const String trending = '/home/trending';
  static const String recentlyViewed = '/home/recently-viewed';

  // ---- Categories ----
  static const String categories = '/categories';
  static const String categoryDetails = '/categories/details';

  // ---- Products ----
  static const String products = '/products';
  static const String productDetails = '/products/details';
  static const String wishlist = '/wishlist';
  static const String addToCart = '/cart/add';

  // ---- Public customer catalog (no auth) ----
  /// Products of the hub whose delivery radius contains the live location.
  /// Query params: `lat`, `lng`.
  static const String publicProducts = '/public/catalog/products';
  /// The hub serving the live location (null body when outside every radius).
  /// Query params: `lat`, `lng`.
  static const String publicHub = '/public/catalog/hub';
  /// Distinct categories of the hub's customer catalog.
  /// Query params: `lat`, `lng`.
  static const String publicCategories = '/public/catalog/categories';

  // ---- Search ----
  static const String search = '/search';
  static const String searchSuggestions = '/search/suggestions';
  static const String recentSearches = '/search/recent';
  static const String trendingSearches = '/search/trending';
  static const String barcodeSearch = '/search/barcode';

  // ---- User Preferences ----
  static const String saveInterests = '/user/interests';
  static const String updateProfile = '/user/profile';
  static const String registerDeviceToken = '/user/device-token';

  // ---- Product Details (Phase 2) ----
  static const String productDetail = '/products/detail';
  static const String relatedProducts = '/products/related';
  static const String frequentlyBoughtTogether = '/products/frequently-bought';
  static const String productReviews = '/products/reviews';

  // ---- Wishlist (Phase 2) ----
  static const String wishlistList = '/wishlist/list';
  static const String wishlistAdd = '/wishlist/add';
  static const String wishlistRemove = '/wishlist/remove';

  // ---- Cart (backend: /api/v1/customer/cart, authenticated) ----
  static const String cart = '/customer/cart'; // GET list, DELETE clear
  static const String cartAddItem = '/customer/cart/items'; // POST {productId, quantity}
  static const String cartUpdateItem = '/customer/cart/items'; // PATCH /{itemId} {quantity}
  static const String cartRemoveItem = '/customer/cart/items'; // DELETE /{itemId}

  // ---- Coupons (Phase 2) ----
  static const String coupons = '/coupons';
  static const String applyCoupon = '/coupons/apply';
  static const String removeCoupon = '/coupons/remove';

  // ---- Address (Phase 2) ----
  static const String addresses = '/addresses';
  static const String addAddress = '/addresses/add';
  static const String updateAddress = '/addresses/update';
  static const String deleteAddress = '/addresses/delete';
  static const String reverseGeocode = '/addresses/reverse-geocode';

  // ---- Checkout / Payment (Phase 2) ----
  static const String deliverySlots = '/checkout/delivery-slots';
  static const String placeOrder = '/checkout/place-order';
  static const String paymentMethods = '/checkout/payment-methods';
  static const String orderDetail = '/orders/detail';

  // ---- Restaurant Module (Phase 3) ----
  static const String restaurantList = '/restaurants';
  static const String restaurantDetail = '/restaurants/detail';
  static const String restaurantMenu = '/restaurants/menu';
  static const String foodDetail = '/restaurants/food-detail';
  static const String restaurantSearch = '/restaurants/search';
  static const String restaurantReviews = '/restaurants/reviews';
  static const String submitReview = '/restaurants/submit-review';
  static const String restaurantCart = '/restaurants/cart';
  static const String restaurantCheckout = '/restaurants/checkout';
  static const String restaurantCoupons = '/restaurants/coupons';
  static const String restaurantOrders = '/restaurants/orders';
  static const String restaurantOrderDetail = '/restaurants/order-detail';
  static const String liveTracking = '/restaurants/tracking';
  static const String repeatOrder = '/restaurants/repeat-order';
}
