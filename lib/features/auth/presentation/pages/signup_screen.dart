import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart'; // استيراد حزمة التوجيه

import '../../../../core/widgets/custom_background.dart';
import '../../../../core/widgets/shiny_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../data/user_model.dart';
import '../bloc/auth_bloc.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // ... دوال التحقق Validators ...
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your name';
    if (value.length < 3) return 'Name must be at least 3 characters';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your email';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter password';
    if (value.length < 8) return 'Must be at least 8 characters';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please re-type password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  // دالة إرسال البيانات
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final user = UserModel(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      // إرسال حدث التسجيل للـ BLoC
      context.read<AuthBloc>().add(SignUpRequested(user));
    }
  } 

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          // انتقال للرئيسية عند نجاح التسجيل
          context.go('/home');
        } else if (state is AuthError) {
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
                        // --- الجزء العلوي ---
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: CircleAvatar(
                                backgroundColor: Colors.white.withOpacity(0.1),
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                                  onPressed: () => context.pop(), // الرجوع باستخدام go_router
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 10),
                        Text("Sign Up", style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 10),
                        Text("Please sign up to get started", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
                        
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
                            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, -5))
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CustomTextField(label: "NAME", hint: "John Doe", controller: _nameController, validator: _validateName),
                                const SizedBox(height: 20),
                                CustomTextField(label: "EMAIL", hint: "example@gmail.com", controller: _emailController, validator: _validateEmail, keyboardType: TextInputType.emailAddress),
                                const SizedBox(height: 20),
                                CustomTextField(label: "PASSWORD", hint: "••••••••", isPassword: true, controller: _passwordController, validator: _validatePassword),
                                const SizedBox(height: 20),
                                CustomTextField(label: "RE-TYPE PASSWORD", hint: "••••••••", isPassword: true, controller: _confirmPasswordController, validator: _validateConfirmPassword),
                                
                                const SizedBox(height: 30),
                                
                                // زر إنشاء الحساب
                                ShinyButton(text: "SIGN UP", onPressed: _submitForm),
                                
                                const SizedBox(height: 25),
                                
                                // --- فاصل "أو" ---
                                Text("Or", style: GoogleFonts.poppins(color: Colors.white54)),
                                const SizedBox(height: 20),
                                
                                // --- أزرار التواصل الاجتماعي ---
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

                                const SizedBox(height: 30),

                                // --- رابط تسجيل الدخول ---
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("Already have an account? ", 
                                      style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        // العودة لشاشة تسجيل الدخول باستخدام go_router
                                        context.pop(); 
                                      },
                                      child: Text("LOG IN", 
                                        style: GoogleFonts.poppins(
                                          color: Colors.white, 
                                          fontSize: 12, 
                                          fontWeight: FontWeight.bold
                                        )
                                      ),
                                    ),
                                  ],
                                ),
                                
                                // مسافة إضافية في الأسفل لحماية المحتوى عند ظهور الكيبورد
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
      ),
    ); 
  }

  // ودجت أيقونات التواصل الاجتماعي
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