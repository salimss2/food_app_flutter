// import 'package:dio/dio.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class DioClient {
//   late Dio dio;

//   DioClient() {
//     dio = Dio(
//       BaseOptions(
//         receiveDataWhenStatusError: true,
//         connectTimeout: const Duration(seconds: 15),
//         receiveTimeout: const Duration(seconds: 15),
//         headers: {
//           'ngrok-skip-browser-warning':
//               'true', // هذا أهم سطر لتجاوز صفحة Cloudflare
//           'Bypass-Tunnel-Reminder': 'true',
//           'User-Agent': 'Flutter-App', // يفضل تغييره من Postman لتمويه المتصفح
//           'Accept': 'application/json',
//           'Content-Type': 'application/json',
//           'X-Requested-With': 'XMLHttpRequest',
//         },
//       ),
//     );

//     // إضافة مراقب (Interceptor) لطباعة ما يحدث في الكونسول
//     dio.interceptors.add(
//       LogInterceptor(requestBody: true, responseBody: true, error: true),
//     );

//     // إضافة التوكن (Token) تلقائياً للطلبات
//     dio.interceptors.add(
//       InterceptorsWrapper(
//         onRequest: (options, handler) async {
//           final prefs = await SharedPreferences.getInstance();
//           final token = prefs.getString('auth_token');
//           if (token != null) {
//             options.headers['Authorization'] = 'Bearer $token';
//           }
//           return handler.next(options);
//         },
//       ),
//     );
//   }
// }
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DioClient {
  late Dio dio;

  DioClient() {
    dio = Dio(
      BaseOptions(
        receiveDataWhenStatusError: true,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
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
