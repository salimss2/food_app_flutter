import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/api/endpoints.dart';
import 'user_model.dart';

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
      );

      return _handleAuthResponse(response.data);
    } on DioException catch (e) {
      _handleDioError(e);
      throw Exception('حدث خطأ غير متوقع');
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
          'password_confirmation': password, // حسب متطلبات Laravel
        },
      );

      return _handleAuthResponse(response.data);
    } on DioException catch (e) {
      _handleDioError(e);
      throw Exception('حدث خطأ غير متوقع');
    }
  }

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

  void _handleDioError(DioException e) {
    if (e.response != null) {
      // إذا كان الخطأ 422 (Validation Error)
      if (e.response?.statusCode == 422) {
        final errors = e.response?.data['errors'];
        throw Exception(errors.values.first[0]); // استخراج أول رسالة خطأ
      }
      // أخطاء أخرى مثل 401 (Unauthorized)
      throw Exception(e.response?.data['message'] ?? 'بيانات غير صحيحة');
    } else {
      throw Exception('لا يوجد اتصال بالإنترنت أو السيرفر مغلق');
    }
  }
}