// lib/core/widgets/shiny_button.dart
import 'package:flutter/material.dart';

class ShinyButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double width;
  final bool isLoading;

  const ShinyButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width = double.infinity,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        // التوهج الخارجي للإطار
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color.fromARGB(
              255,
              92,
              56,
              255,
            ).withOpacity(0.8), // لون أبيض ساطع جداً في الأعلى واليسار
            const Color.fromARGB(255, 106, 100, 129).withOpacity(
              0.8,
            ), // لون أبيض أقل سطوعاً قليلاً في الأسفل واليمين ليعطي عمقاً
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.5), // سمك الإطار
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            // التدرج اللوني الداخلي (الأزرق/البنفسجي)
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
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
