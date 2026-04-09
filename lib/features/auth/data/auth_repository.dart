import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/api/endpoints.dart';
import 'user_model.dart';
import 'dart:convert';

class AuthRepository {
  final DioClient dioClient;
  final SharedPreferences prefs;

  AuthRepository(this.dioClient, this.prefs);

  // 1. تسجيل الدخول
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await dioClient.dio.post(
        Endpoints.login,
        data: {'email': email, 'password': password},
        options: Options(responseType: ResponseType.plain), // 🔥 مهم
      );

      debugPrint("🔢 STATUS: ${response.statusCode}");
      debugPrint("📦 RAW: ${response.data}");

      // 🔥 تنظيف الرد
      String clean = response.data
          .toString()
          .replaceAll(RegExp(r'<!--|-->'), '')
          .trim();

      final jsonData = jsonDecode(clean);

      return _handleAuthResponse(jsonData);
    } on DioException catch (e) {
      _handleDioError(e);
      throw Exception('حدث خطأ');
    }
  }

  // 2. التسجيل الجديد
  Future<UserModel> register(String name, String email, String password) async {
    try {
      final response = await dioClient.dio.post(
        Endpoints.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': password,
        },
        // أضف هذا السطر هنا لتعطيل التحويل التلقائي لـ JSON مؤقتاً
        options: Options(responseType: ResponseType.plain),
      );

      // الآن سيطبع الرقم يقيناً في الكونسول قبل أي خطأ
      debugPrint("🔢 DEBUG STATUS CODE: ${response.statusCode}");
      debugPrint("📦 DEBUG RAW BODY: ${response.data}");

      // تحويل النص إلى Map يدوياً للاستمرار
      String cleanResponse = response.data
          .toString()
          .replaceAll(RegExp(r'<!--|-->'), '')
          .trim();

      final Map<String, dynamic> jsonData = jsonDecode(cleanResponse);
      return _handleAuthResponse(jsonData);
    } on DioException catch (e) {
      _handleDioError(e);
      throw Exception('حدث خطأ');
    }
  }

  // Future<UserModel> register(String name, String email, String password) async {
  //   try {
  //     final response = await dioClient.dio.post(
  //       Endpoints.register,
  //       data: {
  //         'name': name,
  //         'email': email,
  //         'password': password,
  //         'password_confirmation': password, // حسب متطلبات Laravel
  //       },
  //     );

  //     return _handleAuthResponse(response.data);
  //   } on DioException catch (e) {
  //     _handleDioError(e);
  //     throw Exception('حدث خطأ غير متوقع');
  //   }
  // }

  // دالة لجلب بيانات المستخدم الحالي عند فتح التطبيق
  UserModel? getCurrentUser() {
    final userDataString = prefs.getString('user_data');
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    if (isLoggedIn && userDataString != null) {
      // نستخدم الدالة التي أنشأناها في مودل المستخدم
      return UserModel.fromJsonString(userDataString);
    }
    return null;
  }

  // 3. تسجيل الخروج
  Future<void> logout() async {
    try {
      await dioClient.dio.post(Endpoints.logout);
    } catch (e) {
      // نتجاهل الخطأ إذا فشل الاتصال ونكمل تسجيل الخروج محلياً
    } finally {
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
      await prefs.setBool('is_logged_in', false);
    }
  }

  // دوال مساعدة لترتيب الكود ---------------------------

  Future<UserModel> _handleAuthResponse(Map<String, dynamic> data) async {
    final userData = data['user'];
    final token = data['token'];

    // حفظ البيانات في الجهاز
    await prefs.setString('auth_token', token);
    await prefs.setString('user_data', UserModel.fromJson(userData).toJson());
    await prefs.setBool('is_logged_in', true);

    return UserModel.fromJson(userData);
  }

  // void _handleDioError(DioException e) {
  //   if (e.response != null) {
  //     // التعامل مع 404 بشكل خاص
  //     if (e.response?.statusCode == 404) {
  //       throw Exception('عذراً، مسار الـ API غير موجود في السيرفر (404 Not Found). تأكد من صحة الرابط.');
  //     }
  //     // إذا كان الخطأ 422 (Validation Error)
  //     if (e.response?.statusCode == 422) {
  //       final errors = e.response?.data['errors'];
  //       throw Exception(errors.values.first[0]); // استخراج أول رسالة خطأ
  //     }
  //     // أخطاء أخرى مثل 401 (Unauthorized)
  //     throw Exception(e.response?.data['message'] ?? 'بيانات غير صحيحة');
  //   } else {
  //     // في حالة وجود خطأ في التحليل (FormatException) مثل استلام HTML بدلاً من JSON
  //     if (e.type == DioExceptionType.unknown && e.error.toString().contains('FormatException')) {
  //       throw Exception('السيرفر أرجع استجابة غير متوقعة (غالبًا صفحة خطأ 404/500). تأكد من مسار API في السيرفر.');
  //     }
  //     throw Exception('لا يوجد اتصال بالإنترنت أو السيرفر مغلق');
  //   }
  // }
  void _handleDioError(DioException e) {
    debugPrint("========== 🔍 [START DEBUGGING] ==========");

    // 1. فحص هل المشكلة في "الاتصال" قبل الوصول للسيرفر (CORS أو Network)
    if (e.type == DioExceptionType.connectionError) {
      debugPrint("❌ CRITICAL ERROR: الطلب لم يصل للسيرفر أصلاً");
      debugPrint("❌ ERROR MESSAGE: ${e.message}");
      debugPrint(
        "💡 HINT: إذا كنت تستخدم كروم، فالمشكلة هي حماية المتصفح (CORS).",
      );
      throw Exception(
        'فشل الاتصال: تأكد من تشغيل المتصفح بدون حماية أو استخدام المحاكي',
      );
    }

    // 2. إذا وصل للسيرفر ولكن السيرفر رد بخطأ (هنا يظهر رقم الحالة)
    if (e.response != null) {
      debugPrint("✅ SERVER REACHED! (تم الوصول للسيرفر)");
      debugPrint(
        "🔢 STATUS CODE: ${e.response?.statusCode}",
      ); // هذا هو الرقم الذي تبحث عنه
      debugPrint("📦 DATA FROM SERVER: ${e.response?.data}");

      if (e.response?.statusCode == 422) {
        String clean = e.response!.data
            .toString()
            .replaceAll(RegExp(r'<!--|-->'), '')
            .trim();

        final errorJson = jsonDecode(clean);

        throw Exception(errorJson['errors'].values.first[0]);
      }
      throw Exception('خطأ من السيرفر: ${e.response?.statusCode}');
    }

    // 3. أخطاء أخرى (Timeout إلخ)
    debugPrint("⚠️ OTHER ERROR TYPE: ${e.type}");
    debugPrint("⚠️ OTHER ERROR MESSAGE: ${e.message}");
    debugPrint("========== 🔍 [END DEBUGGING] ==========");

    throw Exception('حدث خطأ غير متوقع في الاتصال');
  }
}
