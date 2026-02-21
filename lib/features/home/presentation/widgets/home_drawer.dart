import 'package:customer_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:customer_app/features/settings/presentation/pages/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // استيراد البلوك
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

import '../../../settings/presentation/pages/settings_screen.dart';
// تأكد من مسار استيراد ملف AuthBloc الصحيح لديك

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent, // الخلفية الأساسية شفافة
      elevation: 0, // إزالة الظل الافتراضي
      width: MediaQuery.of(context).size.width * 0.80,
      child: Stack(
        children: [
          // 1. طبقة التمويه (Blur) واللون الشفاف
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                bottomLeft: Radius.circular(30),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF2F284A).withOpacity(0.70),
                        const Color(0xFF1E1A34).withOpacity(0.40),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      bottomLeft: Radius.circular(30),
                    ),
                    border: Border(
                      left: BorderSide(
                        color: Colors.white.withOpacity(0.15),
                        width: 1,
                      ),
                      top: BorderSide(
                        color: Colors.white.withOpacity(0.05),
                        width: 1,
                      ),
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(0.05),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 2. المحتوى
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // زر الإغلاق
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1), 
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(context), 
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // صورة البروفايل والاسم
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF0F55E8), Color(0xFF5D12D2)],
                              ),
                            ),
                            child: const CircleAvatar(
                              radius: 40,
                              backgroundImage: AssetImage(
                                'assets/images/group.jpg',
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          
                          // ==========================================
                          // التعديل هنا: جلب الاسم من بيانات الـ BLoC
                          // ==========================================
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              String userName = "زائر"; // اسم افتراضي
                              
                              // إذا كان مسجل الدخول، اسحب اسمه من المودل
                              if (state is Authenticated) {
                                userName = state.user.name;
                              }

                              return Text(
                                userName,
                                style: GoogleFonts.cairo(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                          // ==========================================
                          
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // --- القائمة ---
                    Text(
                      "القائمة",
                      style: GoogleFonts.cairo(
                        color: Colors.white54,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildDrawerItem(
                      Icons.person_outline,
                      "الملف الشخصي",
                      isSelected: true,
                      onTap: () {
                        Navigator.pop(context); 
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(Icons.history, "السجل", onTap: () {}),
                    _buildDrawerItem(
                      Icons.account_balance_wallet_outlined,
                      "المحفظة",
                      onTap: () {},
                    ),
                    _buildDrawerItem(
                      Icons.notifications_outlined,
                      "الإشعارات",
                      onTap: () {},
                    ),
                    _buildDrawerItem(
                      Icons.favorite_border,
                      "المفضلة",
                      onTap: () {},
                    ),
                    _buildDrawerItem(
                      Icons.card_giftcard,
                      "دعوة صديق",
                      onTap: () {},
                    ),
                    _buildDrawerItem(Icons.search, "بحث", onTap: () {}),

                    const SizedBox(height: 30),

                    Text(
                      "الإعدادات والدعم",
                      style: GoogleFonts.cairo(
                        color: Colors.white54,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildDrawerItem(
                      Icons.settings_outlined,
                      "الإعدادات والخصوصية",
                      onTap: () {
                        Navigator.pop(context); 
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),

                    _buildDrawerItem(
                      Icons.help_outline,
                      "مركز المساعدة",
                      onTap: () {},
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title, {
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: isSelected
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0F55E8).withOpacity(0.5),
                  const Color(0xFF0F55E8).withOpacity(0.0), 
                ],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            )
          : null,
      child: ListTile(
        leading: Icon(icon, color: Colors.white, size: 22),
        title: Text(
          title,
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        dense: true,
        horizontalTitleGap: 0,
        onTap: onTap,
      ),
    );
  }
}