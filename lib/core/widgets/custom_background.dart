import 'package:flutter/material.dart';

class CustomBackground extends StatelessWidget {
  final Widget child;

  const CustomBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          // تأكد من إضافة الصورة في ملف pubspec.yaml تحت قسم assets
          image: AssetImage('assets/images/group.jpg'), // مسار صورة الخلفية
          fit: BoxFit.cover, // لتغطية الشاشة بالكامل
        ),
      ),
      child: child,
    );
  }
}
