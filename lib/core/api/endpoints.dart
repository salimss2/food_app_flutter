class Endpoints {
  // إذا كنت تستخدم "محاكي أندرويد" (Emulator) والـ Port هو 8000:
  // static const String baseUrl =
  //     "https://pharmacy-sanyo-democrats-cube.trycloudflare.com/api";
  // static const String baseUrl = "http://10.0.0.4:8000/api";
  // static const String baseUrl = "http://192.168.0.104:8000/api";
  static const String baseUrl = "https://fundamentals-includes-aerial-revenue.trycloudflare.com/api";
  // هام جداً: في الطرفية (Terminal) يجب تشغيل السيرفر بهذا الأمر:
  // php artisan serve --host=0.0.0.0

  // مسارات المصادقة
  static const String login = "$baseUrl/auth/login";
  static const String register = "$baseUrl/auth/register";
  static const String logout = "$baseUrl/auth/logout";
  static const String forgotPassword = "$baseUrl/auth/forgot-password";
  static const String verifyCode = "$baseUrl/auth/verify-code";
  static const String resetPassword = "$baseUrl/auth/reset-password";
}
