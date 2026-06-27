import 'dart:convert';
import 'package:customer_app/core/api/dio_client.dart';
import 'package:customer_app/core/api/endpoints.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:customer_app/features/auth/data/profile_repository.dart';

class LocationAccessDialog extends StatefulWidget {
  const LocationAccessDialog({super.key});

  @override
  State<LocationAccessDialog> createState() => _LocationAccessDialogState();
}

class _LocationAccessDialogState extends State<LocationAccessDialog> {
  bool _isLoading = false;

  Future<void> _requestLocationPermission() async {
    setState(() => _isLoading = true);
    final authBloc = context.read<AuthBloc>();
    final navigator = Navigator.of(context);
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // 1. التحقق من الـ GPS
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('يرجى تفعيل خدمة الموقع (GPS) في هاتفك');
        setState(() => _isLoading = false);
        return;
      }

      // 2. التحقق من الصلاحية
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('تم رفض صلاحية الوصول للموقع');
          setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar('تم رفض الصلاحية نهائياً. يرجى تفعيلها من الإعدادات.');
        setState(() => _isLoading = false);
        return;
      }

      // 3. جلب الموقع والتوكن
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');

      // 4. عكس الترميز الجغرافي لجلب اسم العنوان المقروء باستخدام Nominatim API
      String readableAddress = "${position.latitude.toStringAsFixed(4)}° N, ${position.longitude.toStringAsFixed(4)}° E";
      try {
        final reverseUrl = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?lat=${position.latitude}&lon=${position.longitude}&format=json',
        );
        final reverseResponse = await http.get(
          reverseUrl,
          headers: {'User-Agent': 'com.dfood.app'},
        );
        if (reverseResponse.statusCode == 200) {
          final data = json.decode(reverseResponse.body);
          if (data != null && data['display_name'] != null) {
            readableAddress = data['display_name'].toString();
          }
        }
      } catch (ge) {
        debugPrint("Reverse geocoding error: $ge");
      }

      // 5. حفظ الإحداثيات على السيرفر
      final dioClient = DioClient();
      final String fullUrl = Endpoints.baseUrl + Endpoints.updateLocation;

      await dioClient.dio.post(
        fullUrl,
        data: {'latitude': position.latitude, 'longitude': position.longitude},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      // 6. حفظ العنوان في الملف الشخصي على السيرفر
      final authState = authBloc.state;
      if (authState is Authenticated) {
        final user = authState.user;
        final profileRepo = ProfileRepository(dioClient, prefs);
        
        final formData = FormData.fromMap({
          'name': user.name,
          'email': user.email,
          'phone': user.phone ?? "",
          'address': user.address ?? "",
          'location': readableAddress,
        });

        // استدعاء السيرفر لتحديث الملف الشخصي بالكامل
        final updatedUser = await profileRepo.updateProfile(formData);

        // إرسال الحدث لـ AuthBloc لتحديث واجهة المستخدم على الفور بالبيانات الجديدة
        authBloc.add(ProfileUpdatedEvent(updatedUser));
      }

      // 7. حفظ البيانات محلياً في SharedPreferences
      await prefs.setString('saved_location', readableAddress);
      await prefs.setDouble('saved_lat', position.latitude);
      await prefs.setDouble('saved_lng', position.longitude);
      await prefs.setBool('has_set_location', true);

      // 8. عند النجاح: إظهار رسالة وإغلاق النافذة
      if (mounted) {
        _showSnackBar('تم تحديد وحفظ موقعك بنجاح', color: Colors.green);
        navigator.pop();
      }
    } catch (e) {
      debugPrint("Error updating location: $e");
      _showSnackBar('حدث خطأ أثناء جلب أو حفظ الموقع');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {Color color = Colors.redAccent}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: const Color(0xFF1E1A34), // لون خلفية النافذة
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // 🌟 مهم جداً للـ Dialog
          children: [
            // صورة الخريطة
            Container(
              width: 150,
              height: 150,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/map_illustration.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.map_rounded,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              "تحديد الموقع",
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "نحتاج لمعرفة موقعك لتوصيل طلباتك بدقة وسرعة.",
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // زر الوصول للموقع
            InkWell(
              onTap: _isLoading ? null : _requestLocationPermission,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 55,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0F55E8),
                      const Color(0xFF0F55E8).withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          "تحديد موقعي الآن",
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 12),
            // زر للإغلاق (تخطي حالياً)
            TextButton(
              onPressed: () => context.pop(),
              child: Text(
                "ليس الآن",
                style: GoogleFonts.cairo(color: Colors.white54, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
