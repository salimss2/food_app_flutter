import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/custom_background.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15),
                  child: Row(
                    children: [
                      // زر الرجوع
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        "سياسة الخصوصية",
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

              // --- 2. المحتوى النصي (Text Content) ---
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1A34).withOpacity(0.60), // خلفية زجاجية داكنة
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "آخر تحديث: 20 فبراير 2026",
                          style: GoogleFonts.cairo(
                            color: const Color(0xFF0F55E8),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildSection(
                          title: "1. مقدمة",
                          content:
                              "مرحباً بك في تطبيقنا. نحن نولي أهمية كبرى لخصوصيتك ونلتزم بحماية بياناتك الشخصية. توضح سياسة الخصوصية هذه كيفية جمع واستخدام ومشاركة معلوماتك عند استخدامك لخدماتنا.",
                        ),
                        
                        _buildSection(
                          title: "2. المعلومات التي نجمعها",
                          content:
                              "عند التسجيل في التطبيق، نقوم بجمع معلومات مثل اسمك، عنوان بريدك الإلكتروني، ورقم هاتفك. كما نجمع بيانات حول موقعك الجغرافي (بموافقتك) لتقديم خدمة توصيل أفضل.",
                        ),
                        
                        _buildSection(
                          title: "3. كيف نستخدم معلوماتك؟",
                          content:
                              "نستخدم المعلومات التي نجمعها لـ:\n"
                              "• معالجة طلباتك وتوصيلها بدقة.\n"
                              "• تحسين تجربة المستخدم داخل التطبيق.\n"
                              "• إرسال تحديثات وعروض ترويجية تهمك.\n"
                              "• الرد على استفساراتك ودعم العملاء.",
                        ),
                        
                        _buildSection(
                          title: "4. مشاركة المعلومات",
                          content:
                              "نحن لا نقوم ببيع أو تأجير معلوماتك الشخصية لأطراف ثالثة. قد نشارك بعض البيانات الضرورية فقط مع شركائنا (مثل المطاعم وعمال التوصيل) لإتمام طلبك بنجاح.",
                        ),
                        
                        _buildSection(
                          title: "5. أمان البيانات",
                          content:
                              "نتخذ إجراءات أمنية تقنية وتنظيمية صارمة لحماية بياناتك من الوصول غير المصرح به أو التعديل أو الإفصاح. نستخدم أحدث تقنيات التشفير لضمان سرية معلوماتك.",
                        ),

                        _buildSection(
                          title: "6. حقوقك",
                          content:
                              "يحق لك في أي وقت الوصول إلى بياناتك الشخصية وتعديلها أو طلب حذفها من أنظمتنا بالكامل من خلال إعدادات حسابك أو بالتواصل مع فريق الدعم.",
                        ),

                        const SizedBox(height: 10),
                        Divider(color: Colors.white.withOpacity(0.1), thickness: 1),
                        const SizedBox(height: 20),

                        Center(
                          child: Text(
                            "إذا كان لديك أي أسئلة حول سياسة الخصوصية،\nيرجى التواصل معنا عبر مركز المساعدة.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              color: Colors.white54,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة مساعدة لبناء الأقسام النصية لتنظيف الكود
  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.cairo(
              color: Colors.white70,
              fontSize: 13,
              height: 1.6, // تباعد الأسطر لسهولة القراءة
            ),
          ),
        ],
      ),
    );
  }
}