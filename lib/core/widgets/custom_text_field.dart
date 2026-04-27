import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String hint;
  final bool isPassword;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;
  final Widget? prefixIcon;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hint,
    this.isPassword = false,
    this.controller,
    this.validator,
    this.keyboardType,
    this.onChanged,
    this.prefixIcon,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color labelColor = isDark ? Colors.white70 : Colors.black54;
    final Color hintColor = isDark ? Colors.white30 : Colors.black38;
    final Color fillColor = isDark ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.6);
    final Color borderColor = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1);
    final Color iconColor = isDark ? Colors.white60 : Colors.black54;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان الحقل (Label)
        Text(
          widget.label.toUpperCase(),
          style: GoogleFonts.poppins(
            color: labelColor,
            fontSize: 12,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),

        // حقل الإدخال مع التنسيق الكامل بداخله
        TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword ? _obscureText : false,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          onChanged: widget.onChanged,
          style: GoogleFonts.poppins(color: textColor),

          // هنا يكمن سر التصميم وإظهار الأخطاء
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: GoogleFonts.poppins(
              color: hintColor,
            ),

            // تفعيل لون الخلفية
            filled: true,
            fillColor: fillColor,

            prefixIcon: widget.prefixIcon != null
                ? Theme(
                    data: Theme.of(context).copyWith(
                      iconTheme: IconThemeData(color: iconColor),
                    ),
                    child: widget.prefixIcon!,
                  )
                : null,

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),

            // 1. الإطار في الحالة العادية (أبيض شفاف)
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: borderColor),
            ),

            // 2. الإطار عند التركيز والكتابة (أبيض أو أزرق حسب رغبتك)
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF0F55E8),
                width: 1.5,
              ),
            ),

            // 3. الإطار عند وجود خطأ (أحمر) - هذا ما كنت تفتقده
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),

            // 4. الإطار عند التركيز ووجود خطأ (أحمر بارز)
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),

            // تنسيق نص رسالة الخطأ لتظهر باللون الأحمر أسفل الحقل
            errorStyle: GoogleFonts.poppins(
              color: Colors.redAccent,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),

            // زر إخفاء/إظهار كلمة المرور
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: iconColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
