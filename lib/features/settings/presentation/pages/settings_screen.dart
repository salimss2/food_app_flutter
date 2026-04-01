import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart'; // <-- استيراد حزمة التوجيه

import '../../../../core/widgets/custom_background.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart'; // استيراد الـ BLoC

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // متغيرات لحفظ حالة المفاتيح (Switch)
  bool _isNotificationEnabled = true;
  bool _isDarkModeEnabled = true;

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
                          onPressed: () => context.pop(), // الرجوع باستخدام go_router
                        ),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        "الإعدادات",
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

              // --- 2. قائمة الإعدادات ---
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // قسم الحساب
                      _buildSectionHeader("الحساب"),
                      _buildSettingsTile(
                        icon: Icons.person_outline,
                        title: "تعديل الملف الشخصي",
                        onTap: () {
                          // الانتقال باستخدام go_router
                          context.push('/profile');
                        },
                      ),
                      _buildSettingsTile(
                        icon: Icons.lock_outline,
                        title: "تغيير كلمة المرور",
                        onTap: () {},
                      ),
                      _buildSettingsTile(
                        icon: Icons.location_on_outlined,
                        title: "العناوين المحفوظة",
                        onTap: () {},
                      ),
                      _buildSettingsTile(
                        icon: Icons.payment_outlined,
                        title: "طرق الدفع",
                        onTap: () {},
                      ),

                      const SizedBox(height: 25),

                      // قسم إعدادات التطبيق
                      _buildSectionHeader("عام"),
                      _buildSettingsTile(
                        icon: Icons.notifications_none,
                        title: "الإشعارات",
                        isSwitch: true,
                        switchValue: _isNotificationEnabled,
                        onChanged: (val) {
                          setState(() => _isNotificationEnabled = val);
                        },
                      ),
                      _buildSettingsTile(
                        icon: Icons.language,
                        title: "لغة التطبيق",
                        trailingText: "العربية", // عرض اللغة المختارة
                        onTap: () {},
                      ),
                      _buildSettingsTile(
                        icon: Icons.dark_mode_outlined,
                        title: "الوضع الليلي",
                        isSwitch: true,
                        switchValue: _isDarkModeEnabled,
                        onChanged: (val) {
                          setState(() => _isDarkModeEnabled = val);
                        },
                      ),

                      const SizedBox(height: 25),

                      // قسم الدعم
                      _buildSectionHeader("الدعم"),
                      _buildSettingsTile(
                        icon: Icons.chat_outlined,
                        title: "إرسال شكوى أو استفسار",
                        onTap: () {
                          context.push('/complaint-inquiry');
                        },
                      ),
                      _buildSettingsTile(
                        icon: Icons.help_outline,
                        title: "مركز المساعدة",
                        onTap: () {},
                      ),
                      _buildSettingsTile(
                        icon: Icons.privacy_tip_outlined,
                        title: "سياسة الخصوصية",
                        onTap: () {
                          // الانتقال باستخدام go_router
                          context.push('/privacy-policy');
                        },
                      ),
                      _buildSettingsTile(
                        icon: Icons.info_outline,
                        title: "حول التطبيق",
                        onTap: () {
                          // الانتقال باستخدام go_router
                          context.push('/about-app');
                        },
                      ),

                      const SizedBox(height: 40),

                      // زر تسجيل الخروج
                      _buildLogoutButton(context),

                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          "الإصدار 1.0.0",
                          style: GoogleFonts.cairo(
                            color: Colors.white30,
                            fontSize: 12,
                          ),
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

  // --- أدوات المساعدة (Helper Widgets) ---

  // عنوان القسم
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 5),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          color: const Color(0xFF0F55E8), // اللون الأزرق الخاص بالبراند
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // عنصر في القائمة (Tile)
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    bool isSwitch = false,
    bool switchValue = false,
    ValueChanged<bool>? onChanged,
    String? trailingText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A34).withOpacity(0.60), // خلفية زجاجية داكنة
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isSwitch ? null : onTap, // تعطيل الضغط إذا كان Switch
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                // الأيقونة
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 15),

                // العنوان
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // الجزء الأخير (سهم، نص، أو مفتاح)
                if (isSwitch)
                  Switch(
                    value: switchValue,
                    onChanged: onChanged,
                    activeThumbColor: const Color(0xFF0F55E8),
                    activeTrackColor: const Color(0xFF0F55E8).withOpacity(0.4),
                    inactiveThumbColor: Colors.grey,
                    inactiveTrackColor: Colors.white.withOpacity(0.1),
                  )
                else if (trailingText != null)
                  Row(
                    children: [
                      Text(
                        trailingText,
                        style: GoogleFonts.cairo(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withOpacity(0.3),
                        size: 14,
                      ),
                    ],
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withOpacity(0.3),
                    size: 14,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // زر تسجيل الخروج
  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        // تدرج لوني أحمر خفيف للإشارة للخطر/الخروج
        gradient: LinearGradient(
          colors: [
            const Color(0xFFE80F0F).withOpacity(0.2),
            const Color(0xFFE80F0F).withOpacity(0.05),
          ],
        ),
        border: Border.all(color: const Color(0xFFE80F0F).withOpacity(0.3)),
      ),
      child: TextButton(
        onPressed: () {
          // 1. إرسال حدث تسجيل الخروج للـ BLoC
          context.read<AuthBloc>().add(LogoutRequested());

          // 2. العودة لشاشة الدخول ومسح ما سبق باستخدام go_router
          context.go('/login');
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, color: Color(0xFFFF5555)),
            const SizedBox(width: 10),
            Text(
              "تسجيل الخروج",
              style: GoogleFonts.cairo(
                color: const Color(0xFFFF5555),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}