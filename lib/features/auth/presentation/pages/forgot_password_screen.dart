import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/custom_background.dart';
import '../../../../core/widgets/shiny_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import 'verification_screen.dart'; // سنقوم بإنشائها لاحقاً أو تأكد من وجودها

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  // التحقق من صحة الإيميل
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // محاكاة إرسال الرمز
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sending verification code...'),
          backgroundColor: Color(0xFF0F55E8),
        ),
      );

      // الانتقال لصفحة التحقق بعد وقت قصير
      Future.delayed(const Duration(seconds: 1), () {
        // تأكد من أن VerificationScreen موجودة أو قم بإنشائها
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VerificationScreen()),
        );
      });
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
                      
                      // العنوان
                      Text(
                        "Forgot Password",
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(height: 10),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          "Please sign in to your existing account",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                        ),
                      ),
                      
                      const Spacer(flex: 1), // يدفع المحتوى للأسفل
                      const SizedBox(height: 20),

                      // --- الحاوية الزجاجية ---
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 40, 24, 40), // زيادة الحشوة السفلية
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 10),
                              
                              // حقل الإيميل
                              CustomTextField(
                                label: "EMAIL",
                                hint: "example@gmail.com",
                                controller: _emailController,
                                validator: _validateEmail,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              
                              const SizedBox(height: 40),
                              
                              // زر إرسال الرمز
                              ShinyButton(
                                text: "SEND CODE",
                                onPressed: _submitForm,
                              ),
                              
                              // مسافة أمان للكيبورد
                              SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 20 : 10),
                            ],
                          ),
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
}