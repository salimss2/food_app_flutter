import 'package:customer_app/core/api/dio_client.dart';
import 'package:customer_app/core/api/endpoints.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart'; // استيراد حزمة الموقع
import 'package:go_router/go_router.dart'; // <-- استيراد حزمة التوجيه
import 'package:shared_preferences/shared_preferences.dart'; // <-- استيراد الذاكرة لجلب التوكن
import 'package:dio/dio.dart'; // <-- استيراد Dio من أجل Options

import '../../../../core/widgets/custom_background.dart';

class LocationAccessScreen extends StatefulWidget {
  const LocationAccessScreen({super.key});

  @override
  State<LocationAccessScreen> createState() => _LocationAccessScreenState();
}

class _LocationAccessScreenState extends State<LocationAccessScreen> {
  bool _isLoading = false;

  // --- دالة طلب صلاحيات الموقع وحفظه ---
  Future<void> _requestLocationPermission() async {
    setState(() {
      _isLoading = true;
    });

    bool serviceEnabled;
    LocationPermission permission;

    try {
      // 1. التحقق مما إذا كانت خدمة الـ GPS مفعلة
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('يرجى تفعيل خدمة الموقع (GPS) في هاتفك');
        setState(() => _isLoading = false);
        return;
      }

      // 2. التحقق من حالة الصلاحية
      permission = await Geolocator.checkPermission();

      // 3. طلب الصلاحية إذا كانت مرفوضة
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('تم رفض صلاحية الوصول للموقع');
          setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar(
          'تم رفض الصلاحية نهائياً. يرجى تفعيلها من إعدادات الهاتف.',
        );
        setState(() => _isLoading = false);
        return;
      }

      // 4. جلب موقع المستخدم الحالي (خط الطول والعرض)
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 5. جلب التوكن من الذاكرة لتعريف المستخدم في لارافل
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString(
        'auth_token',
      ); // تأكد أن المفتاح يطابق مفتاح تسجيل الدخول لديك

      // 6. إرسال الإحداثيات إلى سيرفر لارافل لحفظها
      final dioClient = DioClient();
      final String fullUrl = Endpoints.baseUrl + Endpoints.updateLocation;

      final response = await dioClient.dio.post(
        fullUrl,
        data: {'latitude': position.latitude, 'longitude': position.longitude},
        // 🌟 إرسال التوكن لكي لا يظهر خطأ 500 (profile on null)
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      // 7. الانتقال للصفحة التالية بعد نجاح الحفظ
      if (response.statusCode == 200) {
        if (mounted) {
          _showSnackBar('تم تحديد موقعك وحفظه بنجاح!', color: Colors.green);
          // هنا يمكنك توجيهه لصفحة الخريطة لتأكيد الموقع الدقيق أو للصفحة الرئيسية مباشرة
          context.go('/map-picker');
        }
      }
    } catch (e) {
      _showSnackBar('حدث خطأ أثناء جلب أو حفظ الموقع');
      print("Location Error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {Color color = Colors.redAccent}) {
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
    return Scaffold(
      body: CustomBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // --- صورة الخريطة الدائرية ---
                Container(
                  width: 220,
                  height: 220,
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
                        size: 120,
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                // --- زر الوصول للموقع ---
                InkWell(
                  onTap: _isLoading ? null : _requestLocationPermission,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height:
                        60, // تثبيت الارتفاع لمنع اهتزاز الزر عند ظهور دائرة التحميل
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1E1A34).withOpacity(0.9),
                          const Color(0xFF0F55E8).withOpacity(0.5),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isLoading)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        else ...[
                          Text(
                            "ACCESS LOCATION",
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 35),

                // --- النص التوضيحي بالأسفل ---
                Text(
                  "DFOOD WILL ACCESS YOUR LOCATION\nONLY WHILE USING THE APP",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.6,
                    letterSpacing: 0.5,
                  ),
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
