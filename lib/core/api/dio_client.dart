import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DioClient {
  late Dio dio;

  DioClient() {
    dio = Dio(
      BaseOptions(
        receiveDataWhenStatusError: true,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
        },
      ),
    );

    // إضافة مراقب (Interceptor) مدمج وشامل
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 1. إضافة هيدرز تخطي حماية Cloudflare (إلزامي للهاتف والمتصفح)
          options.headers['ngrok-skip-browser-warning'] = 'true';
          options.headers['Bypass-Tunnel-Reminder'] = 'true';
          options.headers['User-Agent'] = 'Flutter-App';

          // 2. جلب التوكن وإضافته تلقائياً إذا كان موجوداً
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // الانتقال للطلب التالي
          return handler.next(options);
        },
        // يمكنك إضافة onError هنا لاحقاً إذا أردت معالجة عامة للأخطاء
      ),
    );

    // إضافة LogInterceptor لمراقبة البيانات في الكونسول
    dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true, error: true),
    );
  }
}
