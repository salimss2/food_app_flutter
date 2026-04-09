import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../../../core/api/dio_client.dart';
import '../../../../core/api/endpoints.dart';
import '../../../../core/widgets/custom_background.dart';
import '../../../../core/widgets/shiny_button.dart';
import '../../../../core/widgets/custom_text_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        final dioClient = DioClient();
        final response = await dioClient.dio.post(
          Endpoints.resetPassword,
          data: {
            'email': widget.email,
            'password': _passwordController.text,
            'password_confirmation': _confirmPasswordController.text,
          },
        );

        if (response.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم تغيير كلمة المرور بنجاح!'),
                backgroundColor: Color(0xFF0F55E8),
              ),
            );
            context.go('/login');
          }
        }
      } on DioException catch (e) {
        if (mounted) {
          String errorMessage = 'حدث خطأ. يرجى المحاولة مرة أخرى.';
          if (e.response?.data != null && e.response?.data is Map) {
            errorMessage = e.response?.data['message'] ?? errorMessage;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
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
                                onPressed: () => context.pop(),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "Reset Password",
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "Create a new password for your account",
                        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomTextField(
                                label: "NEW PASSWORD",
                                hint: "Min. 8 characters",
                                controller: _passwordController,
                                isPassword: true,
                                prefixIcon: Icon(Icons.lock, color: Colors.white.withOpacity(0.6)),
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Please enter a password';
                                  }
                                  if (val.length < 8) {
                                    return 'Password must be at least 8 characters';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 20),

                              CustomTextField(
                                label: "CONFIRM PASSWORD",
                                hint: "Confirm your password",
                                controller: _confirmPasswordController,
                                isPassword: true,
                                prefixIcon: Icon(Icons.lock, color: Colors.white.withOpacity(0.6)),
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Please confirm your password';
                                  }
                                  if (val != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 40),

                              ShinyButton(
                                text: "SAVE NEW PASSWORD",
                                isLoading: isLoading,
                                onPressed: _submitForm,
                              ),

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
