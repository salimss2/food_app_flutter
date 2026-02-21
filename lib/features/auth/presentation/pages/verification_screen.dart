import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/custom_background.dart';
import '../../../../core/widgets/shiny_button.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  // إنشاء 4 وحدات تحكم للنصوص و 4 عقد تركيز (FocusNodes)
  final List<TextEditingController> _controllers = List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());

  @override
  void dispose() {
    // تنظيف الموارد عند إغلاق الشاشة
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onVerifyPressed() {
    // تجميع الكود من الحقول الأربعة
    String code = _controllers.map((c) => c.text).join();
    
    if (code.length == 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verifying code: $code'), backgroundColor: const Color(0xFF0F55E8)),
      );
      // هنا تضع منطق التحقق (API)
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the full 4-digit code'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: CustomBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // --- زر الرجوع ---
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: CircleAvatar(
                              backgroundColor: Colors.white.withOpacity(0.1),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                      
                      Text(
                        "Verification",
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(height: 10),
                      
                      Text(
                        "We have sent a code to your email",
                        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        "example@gmail.com",
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      
                      const Spacer(flex: 1),
                      const SizedBox(height: 20),

                      // --- الحاوية الزجاجية ---
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1A34).withOpacity(0.60),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(35),
                            topRight: Radius.circular(35),
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, -5),
                            )
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // --- صف المربعات (OTP Row) ---
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(4, (index) => _buildOTPField(context, index)),
                            ),
                            
                            const SizedBox(height: 30),
                            
                            // نص إعادة الإرسال
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Didn't receive code? ",
                                  style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    // منطق إعادة الإرسال
                                  },
                                  child: Text(
                                    "Resend",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white, 
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 30),
                            
                            // زر التحقق
                            ShinyButton(
                              text: "VERIFY",
                              onPressed: _onVerifyPressed,
                            ),

                            // مسافة أمان للكيبورد
                            SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 20 : 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- دالة لبناء مربع واحد قابل للكتابة ---
  Widget _buildOTPField(BuildContext context, int index) {
    return Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        color: const Color(0xFF1D103A), // لون خلفية المربع الداكن
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5D12D2).withOpacity(0.1), // توهج خفيف جداً
            blurRadius: 10,
          ),
        ],
      ),
      child: Center(
        child: TextFormField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1, // يسمح برقم واحد فقط
          style: GoogleFonts.poppins(
            fontSize: 24, 
            fontWeight: FontWeight.bold, 
            color: Colors.white
          ),
          decoration: const InputDecoration(
            counterText: "", // لإخفاء عداد الحروف الصغير (0/1)
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              // إذا كتب المستخدم رقماً، انتقل للمربع التالي
              if (index < 3) {
                FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
              } else {
                // إذا كان آخر مربع، أخفِ لوحة المفاتيح
                FocusScope.of(context).unfocus();
              }
            } else if (value.isEmpty) {
              // إذا مسح المستخدم الرقم، عد للمربع السابق
              if (index > 0) {
                FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
              }
            }
          },
        ),
      ),
    );
  }
}