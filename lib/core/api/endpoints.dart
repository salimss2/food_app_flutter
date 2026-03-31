class Endpoints {
  // إذا كنت تستخدم "محاكي أندرويد" (Emulator) والـ Port هو 8000:
  static const String baseUrl = "http://192.168.0.108:8000/api/v1"; 
  
  // ملاحظة: إذا كنت تختبر على هاتف حقيقي، يجب وضع الـ IP الخاص بالكمبيوتر بدلاً من 10.0.2.2
  // static const String baseUrl = "http://192.168.1.15:8000/api"; 

  // مسارات المصادقة
  static const String login = "$baseUrl/auths/login"; // (يجب أن تتأكد أن لارافل لديه هذه الدالة)
  static const String register = "$baseUrl/auths"; // مسار الـ POST لإنشاء عنصر جديد
  static const String logout = "$baseUrl/auths/logout";
}