class Endpoints {
  // إذا كنت تستخدم "محاكي أندرويد" (Emulator) والـ Port هو 8000:
  // static const String baseUrl =
  //     "https://pharmacy-sanyo-democrats-cube.trycloudflare.com/api";
  // static const String baseUrl = "http://10.0.0.4:8000/api";
  // static const String baseUrl = "http://192.168.8.141:8000/api";
  //https://food-app-9pfa.onrender.com/api/
  static const String baseUrl = "https://food-app-9pfa.onrender.com/api";
  // static const String baseUrl = "http://192.168.137.1:8000/api";
  // هام جداً: في الطرفية (Terminal) يجب تشغيل السيرفر بهذا الأمر:
  // php artisan serve --host=0.0.0.0
  static const String updateProfile = "$baseUrl/auth/update";
  static const String updateLocation =
      "/auth/profile/update-location"; // أو المسار الذي اخترته في لارافل
  // مسارات المصادقة
  static const String login = "$baseUrl/auth/login";
  static const String register = "$baseUrl/auth/register";
  static const String logout = "$baseUrl/auth/logout";
  static const String forgotPassword = "$baseUrl/auth/forgot-password";
  static const String verifyCode = "/auth/verify-otp";
  static const String resetPassword = "$baseUrl/auth/reset-password";

  static const String googleSignIn = "$baseUrl/auth/google-signin";
  // Restaurants
  static const String getRestaurants = "$baseUrl/v1/restaurants";
  // Notifications
  static const String getNotifications = "$baseUrl/v1/notifications";
  static const String markNotificationAsRead =
      "$baseUrl/v1/notifications"; // Append /{id}/read dynamically
  static const String updateFcmToken = "$baseUrl/user/update-fcm-token";

  // Cart Endpoints
  static const String getCart = "$baseUrl/v1/cart";
  static const String addToCart = "$baseUrl/v1/cart/add";
  static const String updateCartItem =
      "$baseUrl/v1/cart/update"; // Append /{id} dynamically
  static const String removeFromCart =
      "$baseUrl/v1/cart/remove"; // Append /{id} dynamically
  static const String clearCart = "$baseUrl/v1/cart/clear";
  static const String applyCoupon = "$baseUrl/v1/coupons/apply";

  // Orders
  static const String orders = "$baseUrl/v1/orders";

  static const String placeOrder = "$baseUrl/v1/orders";
  static String submitReview(int orderId) =>
      "$baseUrl/v1/orders/$orderId/review";

  // Favorites
  static const String getFavorites = "$baseUrl/v1/favorites";
  static const String toggleMealFav = "$baseUrl/v1/favorites/toggle-meal";
  static const String toggleRestaurantFav =
      "$baseUrl/v1/favorites/toggle-restaurant";

  // Support
  static const String sendSupportMessage = "$baseUrl/v1/support";

  static const String privacyPolicy = "$baseUrl/v1/privacy-policy";

  static const String aboutApp = "$baseUrl/v1/about-app";

  static const String categories = "$baseUrl/v1/app-categories";

  static const String search = "$baseUrl/v1/search";
}
