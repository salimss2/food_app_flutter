import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:customer_app/features/auth/data/user_model.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/api/endpoints.dart';

class ProfileRepository {
  final DioClient dioClient;
  final SharedPreferences prefs;

  ProfileRepository(this.dioClient, this.prefs);

  Future<UserModel> updateProfile(FormData formData) async {
    try {
      final response = await dioClient.dio.post(
        Endpoints.updateProfile,
        data: formData,
        options: Options(
          responseType: ResponseType.plain,
          headers: {'Accept': 'application/json'},
        ),
      );

      // تنظيف الرد من أي HTML أو نصوص يضيفها Cloudflare
      String responseString = response.data.toString();
      int startIndex = responseString.indexOf('{');
      int endIndex = responseString.lastIndexOf('}');
      
      if (startIndex == -1 || endIndex == -1) {
        throw Exception('صيغة الرد غير صالحة من السيرفر');
      }

      String cleanJson = responseString.substring(startIndex, endIndex + 1);
      final jsonData = jsonDecode(cleanJson);

      if (jsonData['status'] == true) {
        final userData = jsonData['user'];
        // تحديث البيانات محلياً
        await prefs.setString('user_data', jsonEncode(userData));
        return UserModel.fromJson(userData);
      } else {
        throw Exception(jsonData['message'] ?? 'فشل التحديث');
      }
    } on DioException catch (e) {
      throw Exception('خطأ في السيرفر: ${e.response?.statusCode}');
    }
  }
}