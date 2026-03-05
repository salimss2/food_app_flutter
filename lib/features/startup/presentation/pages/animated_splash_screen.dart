import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart'; // <-- استيراد حزمة التوجيه

import '../../../../core/widgets/custom_background.dart';

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

// استخدمنا SingleTickerProviderStateMixin لتشغيل الأنيميشن
class _AnimatedSplashScreenState extends State<AnimatedSplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    // 1. إعداد متحكم الأنيميشن (مدته ثانيتين)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // 2. أنيميشن التكبير (يبدأ من نصف الحجم إلى الحجم الطبيعي مع ارتداد بسيط)
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    // 3. أنيميشن الظهور (من الشفافية التامة إلى الظهور الكامل)
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // 4. تشغيل الأنيميشن
    _animationController.forward();

    // 5. الانتقال للشاشة التالية بعد 3.5 ثوانٍ
    Timer(const Duration(milliseconds: 3500), () {
      // التأكد من أن الشاشة لا تزال معروضة قبل الانتقال لتجنب الأخطاء
      if (mounted) {
        // الانتقال للشاشة التالية (قم بتغيير '/location-access' للمسار الذي تريده مثل '/login' أو '/onboarding')
        context.go('/location-access'); 
      }
    });
  }

  @override
  void dispose() {
    // تنظيف الأنيميشن من الذاكرة لتجنب التسريب
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- بناء الأنيميشن المزدوج (التكبير والظهور) ---
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _opacityAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  children: [
                    // الشعار
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F55E8), Color(0xFF5D12D2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F55E8).withOpacity(0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.delivery_dining, // استبدلها بصورة الشعار إذا أردت Image.asset
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // اسم التطبيق
                    Text(
                      "FastGrab",
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 80), // مسافة بين الشعار ومؤشر التحميل
              
              // --- مؤشر التحميل الدائري ---
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F55E8)),
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}