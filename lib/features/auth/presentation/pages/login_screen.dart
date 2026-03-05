import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart'; // استيراد حزمة التوجيه

import '../../../../core/widgets/custom_background.dart';
import '../../../../core/widgets/shiny_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../bloc/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // متغير لحالة "تذكرني"
  bool _rememberMe = false; 

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your email';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter password';
    if (value.length < 8) return 'Min 8 chars';
    return null;
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(LoginRequested(
        _emailController.text,
        _passwordController.text,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          // انتقال للرئيسية عند نجاح تسجيل الدخول بمسح ما سبق
          context.go('/home');
        } else if (state is AuthError) {
          // إظهار رسالة خطأ حمراء عند الفشل
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      },
      child: Scaffold(
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
                        const Spacer(flex: 1),
                        Text(
                          "Log In",
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Please sign in to your existing account",
                          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                        ),
                        const Spacer(flex: 1),
                        const SizedBox(height: 20),
                        
                        // --- الحاوية الزجاجية ---
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
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
                                CustomTextField(
                                  label: "EMAIL",
                                  hint: "example@gmail.com",
                                  controller: _emailController,
                                  validator: _validateEmail,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 20),
                                CustomTextField(
                                  label: "PASSWORD",
                                  hint: "••••••••",
                                  isPassword: true,
                                  controller: _passwordController,
                                  validator: _validatePassword,
                                ),
                                const SizedBox(height: 15),
                                
                                // Checkbox & Forgot Password
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: Checkbox(
                                            value: _rememberMe, 
                                            onChanged: (bool? newValue) {
                                              setState(() {
                                                _rememberMe = newValue!;
                                              });
                                            },
                                            side: const BorderSide(color: Colors.white54),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                            activeColor: const Color(0xFF0F55E8),
                                            checkColor: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _rememberMe = !_rememberMe;
                                            });
                                          },
                                          child: Text(
                                            "Remember me", 
                                            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)
                                          ),
                                        ),
                                      ],
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        // الانتقال لصفحة نسيان كلمة المرور
                                        context.push('/forgot-password');
                                      },
                                      child: Text("Forgot Password", style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 30),
                                
                                // زر تسجيل الدخول
                                ShinyButton(text: "LOG IN", onPressed: _submitForm),
                                
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("Don't have an account? ", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                                    GestureDetector(
                                      onTap: () {
                                        // الانتقال لصفحة إنشاء الحساب
                                        context.push('/signup');
                                      },
                                      child: Text("SIGN UP", style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 25),
                                Text("Or", style: GoogleFonts.poppins(color: Colors.white54)),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _socialButton(Icons.facebook),
                                    const SizedBox(width: 20),
                                    _socialButton(Icons.alternate_email),
                                    const SizedBox(width: 20),
                                    _socialButton(Icons.apple),
                                  ],
                                ),
                                SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 20 : 40),
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
      ),
    );
  }

  Widget _socialButton(IconData icon) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF2F284A),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, 3)),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}