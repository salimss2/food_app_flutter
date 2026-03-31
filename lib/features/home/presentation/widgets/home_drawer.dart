import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; 
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:customer_app/features/auth/presentation/bloc/auth_bloc.dart';

class HomeDrawer extends StatefulWidget {
  const HomeDrawer({super.key});

  @override
  State<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> with SingleTickerProviderStateMixin {
  File? _profileImage;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    String? imagePath = prefs.getString('saved_image_path');
    
    if (imagePath != null && imagePath.isNotEmpty) {
      File savedImage = File(imagePath);
      if (await savedImage.exists()) {
        setState(() {
          _profileImage = savedImage;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent, 
      elevation: 0, 
      width: MediaQuery.of(context).size.width * 0.80,
      child: Stack(
        children: [
          // 1. الخلفية الزجاجية
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
                      left: BorderSide(color: Colors.white.withOpacity(0.15), width: 1),
                      top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
                      bottom: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 2. المحتوى
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
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
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 20),
                          onPressed: () => context.pop(), 
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // قسم البروفايل مع الأنيميشن الدائري
                    Center(
                      child: Column(
                        children: [
                          AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              final value1 = _animationController.value;
                              final value2 = (value1 + 0.5) % 1.0;

                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  Transform.scale(
                                    scale: 1.0 + (value2 * 0.8),
                                    child: Opacity(
                                      opacity: (1.0 - value2) * 0.5,
                                      child: _buildAnimatedRing(),
                                    ),
                                  ),
                                  Transform.scale(
                                    scale: 1.0 + (value1 * 0.8),
                                    child: Opacity(
                                      opacity: (1.0 - value1) * 0.5, 
                                      child: _buildAnimatedRing(),
                                    ),
                                  ),
                                  child!,
                                ],
                              );
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  )
                                ]
                              ),
                              child: CircleAvatar(
                                radius: 40,
                                backgroundImage: _profileImage != null
                                    ? FileImage(_profileImage!) as ImageProvider
                                    : const AssetImage('assets/images/group.jpg'),
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),
                          
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              String userName = "زائر"; 
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
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // القائمة
                    Text(
                      "القائمة",
                      style: GoogleFonts.cairo(color: Colors.white54, fontSize: 12, letterSpacing: 1),
                    ),
                    const SizedBox(height: 10),

                    // --- التعديل هنا: تم إزالة isSelected: true ليصبح زراً عادياً ---
                    _buildDrawerItem(
                      Icons.person_outline,
                      "الملف الشخصي",
                      onTap: () {
                        context.pop(); 
                        context.push('/profile'); 
                      },
                    ),
                    _buildDrawerItem(Icons.list_alt, "طلباتي", onTap: () {
                      context.push('/orders'); 
                    }),
                    _buildDrawerItem(Icons.account_balance_wallet_outlined, "المحفظة", onTap: () {}),
                    _buildDrawerItem(Icons.notifications_outlined, "الإشعارات", onTap: () {}),
                    _buildDrawerItem(Icons.favorite_border, "المفضلة", onTap: () {}),
                    _buildDrawerItem(Icons.card_giftcard, "دعوة صديق", onTap: () {}),
                    _buildDrawerItem(Icons.search, "بحث", onTap: () {}),

                    const SizedBox(height: 30),

                    Text(
                      "الإعدادات والدعم",
                      style: GoogleFonts.cairo(color: Colors.white54, fontSize: 12, letterSpacing: 1),
                    ),
                    const SizedBox(height: 10),

                    _buildDrawerItem(
                      Icons.settings_outlined,
                      "الإعدادات والخصوصية",
                      onTap: () {
                        context.pop(); 
                        context.push('/settings'); 
                      },
                    ),
                    _buildDrawerItem(Icons.help_outline, "مركز المساعدة", onTap: () {}),

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

  Widget _buildAnimatedRing() {
    return Container(
      width: 80, 
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, {bool isSelected = false, VoidCallback? onTap}) {
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