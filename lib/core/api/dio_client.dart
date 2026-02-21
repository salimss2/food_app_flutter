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
          'Content-Type': 'application/json',
          'Accept': 'application/json', // ضروري جداً لكي يرد Laravel بـ JSON دائماً
        },
      ),
    );

    // إضافة مراقب (Interceptor) لطباعة ما يحدث في الكونسول
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));

    // إضافة التوكن (Token) تلقائياً للطلبات
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }
}