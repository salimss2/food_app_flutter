import 'package:flutter/material.dart';

class CustomBackground extends StatelessWidget {
  final Widget child;

  const CustomBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          // تأكد من إضافة الصورة في ملف pubspec.yaml تحت قسم assets
          image: AssetImage(
            isDark
                ? 'assets/images/group.jpg'
                : 'assets/images/lightmoodbb.jpg',
          ), // مسار صورة الخلفية
          fit: BoxFit.cover, // لتغطية الشاشة بالكامل
        ),
      ),
      child: child,
    );
  }
}
