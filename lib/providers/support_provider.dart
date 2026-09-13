import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../core/api/dio_client.dart';
import '../core/api/endpoints.dart';

class SupportProvider extends ChangeNotifier {
  final Dio _dio = DioClient().dio;

  Future<(bool success, String message)> submitTicket({
    required String type,
    required String subject,
    required String message,
  }) async {
    try {
      final response = await _dio.post(
        Endpoints.sendSupportMessage,
        data: {
          'type': type,
          'subject': subject,
          'message': message,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return (true, 'تم إرسال رسالتك بنجاح');
      }
      return (false, 'حدث خطأ غير متوقع');
    } on DioException catch (e) {
      debugPrint('DioException in submitTicket: ${e.response?.data}');
      final serverMsg = e.response?.data?['message']?.toString();
      final errorMsg = serverMsg ?? 'تعذّر الاتصال بالخادم، يرجى المحاولة لاحقاً';
      return (false, errorMsg);
    } catch (e) {
      debugPrint('Error in submitTicket: $e');
      return (false, 'حدث خطأ غير متوقع');
    }
  }
}
