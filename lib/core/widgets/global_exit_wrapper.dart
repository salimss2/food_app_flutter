import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

Future<bool?> showExitConfirmationDialog(BuildContext context) {
  final bool isDark = Theme.of(context).brightness == Brightness.dark;
  final Color bgColor = isDark ? const Color(0xFF140C36) : Colors.white;
  final Color titleColor = isDark ? Colors.white : Colors.black87;
  final Color contentColor = isDark ? Colors.white70 : Colors.black87;
  final Color cancelColor = isDark ? Colors.white54 : Colors.black54;

  return showDialog<bool>(
    context: context,
    builder: (context) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: Row(
            children: [
              const Icon(Icons.exit_to_app, color: Colors.redAccent, size: 28),
              const SizedBox(width: 10),
              Text(
                "تأكيد الخروج",
                style: GoogleFonts.cairo(
                  color: titleColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            "هل أنت متأكد أنك تريد الخروج من التطبيق؟",
            style: GoogleFonts.cairo(color: contentColor, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                "إلغاء",
                style: GoogleFonts.cairo(
                  color: cancelColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                "خروج",
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class GlobalExitWrapper extends StatelessWidget {
  final Widget child;

  const GlobalExitWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: GoRouter.of(
        context,
      ).canPop(), // Let it pop normally if there's a previous page
      onPopInvoked: (bool didPop) async {
        if (didPop) return; // It already popped naturally

        // If it didn't pop, it means the stack is empty (root screen). Show dialog.
        final bool shouldExit =
            await showExitConfirmationDialog(context) ?? false;
        if (shouldExit) {
          SystemNavigator.pop();
        }
      },
      child: child,
    );
  }
}
