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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Color> outerGradientColors = isDark
        ? [
            const Color.fromARGB(255, 92, 56, 255).withOpacity(0.8),
            const Color.fromARGB(255, 106, 100, 129).withOpacity(0.8),
          ]
        : [
            const Color(0xFF9D4EDD).withOpacity(0.8),
            const Color(0xFF48CAE4).withOpacity(0.8),
          ];

    final List<Color> innerGradientColors = isDark
        ? [
            const Color.fromARGB(153, 78, 59, 155),
            const Color.fromARGB(173, 17, 54, 135),
          ]
        : [
            const Color(0xFF7209B7).withOpacity(0.8),
            const Color(0xFF3A0CA3).withOpacity(0.9),
          ];

    final Color shadowColor = isDark 
        ? Colors.white.withOpacity(0.2) 
        : const Color(0xFF3A0CA3).withOpacity(0.2);

    return Container(
      width: width,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        // التوهج الخارجي للإطار
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: outerGradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
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
            // التدرج اللوني الداخلي
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.75],
              colors: innerGradientColors,
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
