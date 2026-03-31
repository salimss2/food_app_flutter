import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/custom_background.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  // علامة تخبرنا أن الأنيميشن انتهى
  bool _isAnimationFinished = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // مؤقت الأنيميشن فقط (لن يقوم بالتوجيه بنفسه)
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        setState(() {
          _isAnimationFinished = true; // نعلن انتهاء الأنيميشن
        });
        // نقوم بالفحص والتوجيه
        _checkAndNavigate(context.read<AuthBloc>().state);
      }
    });
  }

  // --- دالة التوجيه الذكية (لا تعمل إلا إذا انتهى الأنيميشن وعُرفت الحالة) ---
  Future<void> _checkAndNavigate(AuthState state) async {
    // إذا لم ينتهِ وقت الشعار (3.5 ثواني) لا تفعل شيئاً
    if (!_isAnimationFinished) return;

    // إذا كان التطبيق لا يزال يفحص تسجيل الدخول، انتظر
    if (state is AuthInitial) return; 

    final prefs = await SharedPreferences.getInstance();
    final bool isLocationDone = prefs.getBool('is_location_done') ?? false;

    if (state is Authenticated) {
      // مسجل دخول -> الرئيسية
      context.go('/home');
    } else if (isLocationDone) {
      // غير مسجل + حدد موقعه مسبقاً -> تسجيل الدخول
      context.go('/login');
    } else {
      // مستخدم جديد تماماً -> شاشات البداية
      context.go('/splash');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // التعديل الأهم: تغليف الشاشة بـ BlocListener لمراقبة حالة المستخدم الحقيقية
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // كلما تغيرت حالة الـ Bloc، حاول التوجيه (الدالة بداخلها شروط تحميها)
        _checkAndNavigate(state);
      },
      child: Scaffold(
        body: CustomBackground(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                          Icons.delivery_dining, 
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
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
                
                const SizedBox(height: 80), 
                
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F55E8)),
                  strokeWidth: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}