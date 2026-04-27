class Endpoints {
  // إذا كنت تستخدم "محاكي أندرويد" (Emulator) والـ Port هو 8000:
  // static const String baseUrl =
  //     "https://pharmacy-sanyo-democrats-cube.trycloudflare.com/api";
  // static const String baseUrl = "http://10.0.0.4:8000/api";
  // static const String baseUrl = "http://192.168.8.141:8000/api";
  static const String baseUrl =
      "https://lbs-naval-physician-railroad.trycloudflare.com/api";
  // static const String baseUrl = "http://192.168.137.1:8000/api";
  // هام جداً: في الطرفية (Terminal) يجب تشغيل السيرفر بهذا الأمر:
  // php artisan serve --host=0.0.0.0
  static const String updateProfile = "$baseUrl/auth/update";
  // مسارات المصادقة
  static const String login = "$baseUrl/auth/login";
  static const String register = "$baseUrl/auth/register";
  static const String logout = "$baseUrl/auth/logout";
  static const String forgotPassword = "$baseUrl/auth/forgot-password";
  static const String verifyCode = "$baseUrl/auth/verify-code";
  static const String resetPassword = "$baseUrl/auth/reset-password";
  // Restaurants
  static const String getRestaurants = "$baseUrl/v1/restaurants";
  // Notifications
  static const String getNotifications = "$baseUrl/v1/notifications";
  static const String markNotificationAsRead = "$baseUrl/v1/notifications"; // Append /{id}/read dynamically
  static const String updateFcmToken = "$baseUrl/v1/profile/fcm-token";

  // Cart Endpoints
  static const String getCart = "$baseUrl/v1/cart";
  static const String addToCart = "$baseUrl/v1/cart/add";
  static const String updateCartItem =
      "$baseUrl/v1/cart/update"; // Append /{id} dynamically
  static const String removeFromCart =
      "$baseUrl/v1/cart/remove"; // Append /{id} dynamically
  static const String clearCart = "$baseUrl/v1/cart/clear";

  // Orders
  static const String orders = "$baseUrl/v1/orders";
  static const String placeOrder = "$baseUrl/v1/orders";

  // Favorites
  static const String getFavorites = "$baseUrl/v1/favorites";
  static const String toggleMealFav = "$baseUrl/v1/favorites/toggle-meal";
  static const String toggleRestaurantFav =
      "$baseUrl/v1/favorites/toggle-restaurant";
}
