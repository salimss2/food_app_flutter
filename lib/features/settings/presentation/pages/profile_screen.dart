import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // 1. استيراد البلوك
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/custom_background.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/shiny_button.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart'; // 2. مسار البلوك (تأكد من صحته)

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    
    // 3. قراءة حالة المستخدم الحالية من الـ BLoC عند فتح الصفحة
    final authState = context.read<AuthBloc>().state;
    
    if (authState is Authenticated) {
      // إذا كان المستخدم مسجل الدخول، نعرض بياناته الحقيقية
      final user = authState.user;
      _nameController = TextEditingController(text: user.name);
      _emailController = TextEditingController(text: user.email);
      // رقم الهاتف غير موجود في الـ UserModel حالياً، لذا نتركه فارغاً
      _phoneController = TextEditingController(text: ""); 
    } else {
      // حالة احتياطية لو كان هناك خطأ
      _nameController = TextEditingController(text: "");
      _emailController = TextEditingController(text: "");
      _phoneController = TextEditingController(text: "");
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) return 'يرجى إدخال الاسم';
    if (value.length < 3) return 'الاسم يجب أن يكون 3 أحرف على الأقل';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'يرجى إدخال البريد الإلكتروني';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'بريد إلكتروني غير صالح';
    return null;
  }

  String? _validatePhone(String? value) {
    // جعلناه اختيارياً الآن لأننا لم نضفه للنموذج بعد
    if (value != null && value.isNotEmpty && value.length < 9) {
      return 'رقم هاتف غير صالح';
    }
    return null; 
  }

  void _saveProfile() {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      // ملاحظة: لتحديث البيانات فعلياً في التطبيق تحتاج لإنشاء حدث (Event) 
      // جديد في AuthBloc اسمه UpdateProfile(user)
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم حفظ التغييرات بنجاح!',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF0F55E8),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, 
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomBackground(
          child: Column(
            children: [
              // --- 1. الرأس (Header) ---
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        "تعديل الملف الشخصي",
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- 2. المحتوى ---
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // --- صورة البروفايل مع زر التعديل ---
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Color(0xFF0F55E8), Color(0xFF5D12D2)],
                                ),
                              ),
                              child: const CircleAvatar(
                                radius: 55,
                                backgroundImage: AssetImage('assets/images/group.jpg'),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0, 
                              child: GestureDetector(
                                onTap: () {
                                  // كود تغيير الصورة
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E1A34),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF0F55E8), width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // --- حاوية النموذج (Form Container) ---
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1A34).withOpacity(0.60),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomTextField(
                                label: "الاسم الكامل",
                                hint: "أدخل اسمك الكامل",
                                controller: _nameController,
                                validator: _validateName,
                              ),
                              
                              const SizedBox(height: 20),
                              
                              CustomTextField(
                                label: "البريد الإلكتروني",
                                hint: "example@mail.com",
                                controller: _emailController,
                                validator: _validateEmail,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              
                              const SizedBox(height: 20),
                              
                              CustomTextField(
                                label: "رقم الهاتف",
                                hint: "05X XXX XXXX",
                                controller: _phoneController,
                                validator: _validatePhone,
                                keyboardType: TextInputType.phone,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // --- زر الحفظ ---
                      ShinyButton(
                        text: "حفظ التغييرات",
                        onPressed: _saveProfile,
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}