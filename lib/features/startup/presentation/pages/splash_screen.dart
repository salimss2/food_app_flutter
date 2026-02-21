import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_background.dart'; // استيراد الخلفية
import 'onboarding_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // استخدام الودجت المخصص كجسم للشاشة
      body: CustomBackground(
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              const Text(
                'Food Station',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(flex: 2),
              const Text(
                'Get Started with Food Station',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              _buildContinueButton(context),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
  
  
  // دالة لبناء الزر بإطار لامع وبارز على كل الحواف
  Widget _buildContinueButton(BuildContext context) {
  // 1. الحاوية الخارجية: هذه هي التي تصنع "الإطار اللامع"
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 40.0),
    height: 58, // زدنا الارتفاع قليلاً لتعويض سماكة الإطار
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12), // زاوية خارجية أكبر قليلاً
      // هذا التدرج هو سر اللمعان البارز
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color.fromARGB(255, 92, 56, 255).withOpacity(0.8), // لون أبيض ساطع جداً في الأعلى واليسار
          const Color.fromARGB(255, 106, 100, 129).withOpacity(0.8), // لون أبيض أقل سطوعاً قليلاً في الأسفل واليمين ليعطي عمقاً
        ],
      ),
      boxShadow: [
          // إضافة ظل خفيف جداً ومشع لزيادة البروز (اختياري)
          BoxShadow(
            color: Colors.white.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
    ),
    // 2. حشوة (Padding) بمقدار سماكة الإطار المطلوبة (مثلاً 1.5 بكسل ليكون بارزاً)
    child: Padding(
      padding: const EdgeInsets.all(1.5), 
      
      // 3. الحاوية الداخلية: جسم الزر الأصلي
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10), // الزاوية الداخلية المطلوبة
          // تدرج التعبئة الداخلي (Fill) طبقاً لتصميم Figma
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.75],
            colors: [
              Color.fromARGB(153, 78, 59, 155), // شفاف تماماً في الأعلى
              Color.fromARGB(173, 17, 54, 135), // أزرق معتم في الأسفل
            ],
          ),
        ),
        child: ElevatedButton(
          onPressed: () {
            // ضع هنا كود الانتقال للشاشة التالية
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const OnboardingScreen()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Continue',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600, // جعل الخط أسمك قليلاً ليناسب الإطار البارز
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}

