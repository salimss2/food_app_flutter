import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import '../../../../core/widgets/custom_background.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/api/endpoints.dart';

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  String _description =
      "تطبيق FastGrab هو وجهتك الأولى لطلب الطعام أونلاين. نحن نهدف إلى توفير تجربة طلب سلسة وسريعة تربطك بأفضل المطاعم المحلية في مدينتك.\n\nسواء كنت تشتهي البيتزا الإيطالية، أو البرجر الكلاسيكي، أو حتى الحلويات، فإن تطبيقنا يوفر لك خيارات واسعة مع واجهة مستخدم سهلة، وطرق دفع آمنة، وخدمة توصيل سريعة وموثوقة.";
  String _version = "1.0.0";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAboutData();
  }

  Future<void> _fetchAboutData() async {
    try {
      final dio = DioClient().dio;
      final response = await dio.get(Endpoints.aboutApp);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map) {
          setState(() {
            _description = (data['data']?['description'] ??
                    data['description'] ??
                    data['content'] ??
                    _description)
                .toString();
            _version = (data['data']?['version'] ??
                    data['version'] ??
                    _version)
                .toString();
            _isLoading = false;
          });
        } else {
          setState(() {
            _description = data.toString();
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl, // توجيه الصفحة للعربية
        child: CustomBackground(
          child: Column(
            children: [
              // --- 1. الرأس (Header) ---
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 15,
                  ),
                  child: Row(
                    children: [
                      // زر الرجوع
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        "about_app".tr(), // محول ديناميكي
                        style: GoogleFonts.cairo(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- 2. المحتوى (Content) ---
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),

                            // --- شعار واسم التطبيق ---
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0F55E8),
                                    Color(0xFF5D12D2)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0F55E8)
                                        .withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.delivery_dining, // أيقونة مؤقتة تعبر عن التوصيل
                                size: 50,
                                color: Colors.white,
                              ),
                            ),

                            const SizedBox(height: 20),

                            Text(
                              "FastGrab", // اسم التطبيق كما في شاشة البداية
                              style: GoogleFonts.poppins(
                                // استخدام Poppins للاسم الإنجليزي
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              "${'version_label'.tr()} $_version", // محول ديناميكي
                              style: GoogleFonts.cairo(
                                color: const Color(0xFF0F55E8),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 40),

                            // --- حاوية النبذة التعريفية (Glass Container) ---
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF1E1A34).withOpacity(0.60),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.05),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "welcome_to_fastgrab".tr(), // محول ديناميكي
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  Text(
                                    _description, // البيانات من الـ API
                                    style: GoogleFonts.cairo(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      height: 1.8,
                                    ),
                                  ),
                                  const SizedBox(height: 25),

                                  // مميزات التطبيق بشكل مبسط
                                  _buildFeatureItem(
                                    Icons.rocket_launch,
                                    "fast_and_reliable_delivery".tr(),
                                  ),
                                  _buildFeatureItem(
                                    Icons.restaurant_menu,
                                    "wide_variety_of_restaurants".tr(),
                                  ),
                                  _buildFeatureItem(
                                    Icons.payment,
                                    "safe_multiple_payment_methods".tr(),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 40),

                            // --- روابط التواصل ---
                            Text(
                              "follow_us_on_social_media".tr(), // محول ديناميكي
                              style: GoogleFonts.cairo(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildSocialIcon(Icons.facebook),
                                const SizedBox(width: 15),
                                _buildSocialIcon(
                                    Icons.alternate_email), // تويتر/X
                                const SizedBox(width: 15),
                                _buildSocialIcon(
                                  Icons.camera_alt_outlined,
                                ), // انستجرام
                              ],
                            ),

                            const SizedBox(height: 30),

                            // حقوق النشر
                            Text(
                              "all_rights_reserved".tr(), // محول ديناميكي
                              style: GoogleFonts.cairo(
                                color: Colors.white30,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // أداة مساعدة لبناء مميزات التطبيق
  Widget _buildFeatureItem(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF0F55E8), size: 18),
          ),
          const SizedBox(width: 15),
          Text(
            title,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // أداة مساعدة لبناء أيقونات التواصل الاجتماعي
  Widget _buildSocialIcon(IconData icon) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: const Color(0xFF2F284A),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: () {},
      ),
    );
  }
}

