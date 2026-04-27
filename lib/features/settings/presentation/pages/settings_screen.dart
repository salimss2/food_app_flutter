import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart'; // <-- استيراد حزمة التوجيه

import '../../../../core/widgets/custom_background.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart'; // استيراد الـ BLoC
import '../../../../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // متغيرات لحفظ حالة المفاتيح (Switch)
  bool _isNotificationEnabled = true;

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color versionTextColor = isDarkMode
        ? Colors.white30
        : Colors.black54;
    final Color backBtnBgColor = isDarkMode
        ? Colors.white.withOpacity(0.1)
        : Colors.white.withOpacity(0.5);
    final Color borderColor = isDarkMode
        ? Colors.white.withOpacity(0.2)
        : Colors.black.withOpacity(0.1);

    final Widget bodyContent = Column(
      children: [
        // --- 1. الرأس (Header) ---
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15),
            child: Row(
              children: [
                // زر الرجوع
                Container(
                  decoration: BoxDecoration(
                    color: backBtnBgColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: textColor),
                    onPressed: () => context.pop(), // الرجوع باستخدام go_router
                  ),
                ),
                const SizedBox(width: 15),
                Text(
                  "الإعدادات",
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
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
                _buildSettingsTile(context: context,
                  icon: Icons.person_outline,
                  title: "تعديل الملف الشخصي",
                  onTap: () {
                    // الانتقال باستخدام go_router
                    context.push('/profile');
                  },
                ),
                _buildSettingsTile(context: context,
                  icon: Icons.lock_outline,
                  title: "تغيير كلمة المرور",
                  onTap: () {},
                ),
                _buildSettingsTile(context: context,
                  icon: Icons.location_on_outlined,
                  title: "العناوين المحفوظة",
                  onTap: () {},
                ),
                _buildSettingsTile(context: context,
                  icon: Icons.payment_outlined,
                  title: "طرق الدفع",
                  onTap: () {},
                ),

                const SizedBox(height: 25),

                // قسم إعدادات التطبيق
                _buildSectionHeader("عام"),
                _buildSettingsTile(context: context,
                  icon: Icons.notifications_none,
                  title: "الإشعارات",
                  isSwitch: true,
                  switchValue: _isNotificationEnabled,
                  onChanged: (val) {
                    setState(() => _isNotificationEnabled = val);
                  },
                ),
                _buildSettingsTile(context: context,
                  icon: Icons.language,
                  title: "لغة التطبيق",
                  trailingText: "العربية", // عرض اللغة المختارة
                  onTap: () {},
                ),
                _buildSettingsTile(context: context,
                  icon: Icons.dark_mode_outlined,
                  title: "الوضع الليلي",
                  isSwitch: true,
                  switchValue: isDarkMode,
                  onChanged: (val) {
                    context.read<ThemeProvider>().toggleTheme(val);
                  },
                ),

                const SizedBox(height: 25),

                // قسم الدعم
                _buildSectionHeader("الدعم"),
                _buildSettingsTile(context: context,
                  icon: Icons.chat_outlined,
                  title: "إرسال شكوى أو استفسار",
                  onTap: () {
                    context.push('/complaint-inquiry');
                  },
                ),
                _buildSettingsTile(context: context,
                  icon: Icons.help_outline,
                  title: "مركز المساعدة",
                  onTap: () {},
                ),
                _buildSettingsTile(context: context,
                  icon: Icons.privacy_tip_outlined,
                  title: "سياسة الخصوصية",
                  onTap: () {
                    // الانتقال باستخدام go_router
                    context.push('/privacy-policy');
                  },
                ),
                _buildSettingsTile(context: context,
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
                      color: versionTextColor,
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
    );

    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl, // توجيه الصفحة للعربية
        child: isDarkMode
            ? CustomBackground(child: bodyContent)
            : Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/lightmood.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: bodyContent,
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
    required BuildContext context,
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    bool isSwitch = false,
    bool switchValue = false,
    ValueChanged<bool>? onChanged,
    String? trailingText,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color tileBgColor = isDarkMode
        ? const Color(0xFF1E1A34).withOpacity(0.60)
        : Colors.white.withOpacity(0.6);
    final Color borderColor = isDarkMode
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.05);
    final Color iconColor = isDarkMode ? Colors.white : Colors.black87;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color subTextColor = isDarkMode
        ? Colors.white54
        : Colors.black54;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: tileBgColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor),
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
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 15),

                // العنوان
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.cairo(
                      color: textColor,
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
                    inactiveTrackColor: isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                  )
                else if (trailingText != null)
                  Row(
                    children: [
                      Text(
                        trailingText,
                        style: GoogleFonts.cairo(
                          color: subTextColor,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.3)
                            : Colors.black.withOpacity(0.3),
                        size: 14,
                      ),
                    ],
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.3)
                        : Colors.black.withOpacity(0.3),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color redIconColor = isDarkMode
        ? const Color(0xFFFF5555)
        : const Color(0xFFD32F2F);
    final List<Color> gradientColors = isDarkMode
        ? [
            const Color(0xFFE80F0F).withOpacity(0.2),
            const Color(0xFFE80F0F).withOpacity(0.05),
          ]
        : [
            const Color(0xFFE80F0F).withOpacity(0.15),
            const Color(0xFFE80F0F).withOpacity(0.05),
          ];
    final Color borderColor = isDarkMode
        ? const Color(0xFFE80F0F).withOpacity(0.3)
        : const Color(0xFFE80F0F).withOpacity(0.2);
    final Color btnBgColor = isDarkMode
        ? Colors.transparent
        : Colors.white.withOpacity(0.4);

    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        color: btnBgColor,
        borderRadius: BorderRadius.circular(15),
        // تدرج لوني أحمر خفيف للإشارة للخطر/الخروج
        gradient: LinearGradient(colors: gradientColors),
        border: Border.all(color: borderColor),
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
            Icon(Icons.logout, color: redIconColor),
            const SizedBox(width: 10),
            Text(
              "تسجيل الخروج",
              style: GoogleFonts.cairo(
                color: redIconColor,
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
