import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart'; // استيراد الحزمة الجديدة
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/custom_background.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/shiny_button.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

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
  late TextEditingController _addressController; // متحكم العنوان
  late TextEditingController _locationController; // متحكم الموقع

  File? _imageFile;

  @override
  void initState() {
    super.initState();

    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _locationController = TextEditingController();

    final authState = context.read<AuthBloc>().state;

    if (authState is Authenticated) {
      final user = authState.user;
      _nameController = TextEditingController(text: user.name);
      _emailController = TextEditingController(text: user.email);
    } else {
      _nameController = TextEditingController();
      _emailController = TextEditingController();
    }

    // استدعاء دالة تحميل البيانات المحفوظة محلياً
    _loadSavedData();
  }

  // --- دالة لتحميل البيانات من SharedPreferences ---
  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _phoneController.text = prefs.getString('saved_phone') ?? "";
      _addressController.text = prefs.getString('saved_address') ?? "";
      _locationController.text = prefs.getString('saved_location') ?? "";

      String? imagePath = prefs.getString('saved_image_path');
      if (imagePath != null && imagePath.isNotEmpty) {
        _imageFile = File(imagePath);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("خطأ في اختيار الصورة: $e");
    }
  }

  // --- محاكاة لاختيار الموقع من الخريطة ---
  Future<void> _pickLocation() async {
    // هنا تضع كود الانتقال لصفحة الخريطة (Google Maps) وارجاع الإحداثيات
    // للتجربة، سنضع تأخير بسيط ونعين إحداثيات افتراضية
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('جاري فتح الخريطة لتحديد الموقع...')),
    );

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _locationController.text =
          "15.3694° N, 44.1910° E"; // إحداثيات افتراضية للتجربة
    });
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) return 'يرجى إدخال الاسم';
    if (value.length < 3) return 'الاسم يجب أن يكون 3 أحرف على الأقل';
    return null;
  }

  // --- دالة الحفظ المحدثة (تحفظ البيانات محلياً) ---
  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();

      // حفظ البيانات في ذاكرة الهاتف
      await prefs.setString('saved_phone', _phoneController.text);
      await prefs.setString('saved_address', _addressController.text);
      await prefs.setString('saved_location', _locationController.text);

      if (_imageFile != null) {
        await prefs.setString('saved_image_path', _imageFile!.path);
      }

      // ملاحظة: هنا يمكنك أيضاً استدعاء حدث لتحديث قاعدة البيانات
      // context.read<AuthBloc>().add(UpdateUserProfileEvent(...));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم حفظ جميع التغييرات بنجاح!',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF0F55E8),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 15,
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            // 1. افحص: هل هناك شاشة سابقة في المكدس؟
                            if (context.canPop()) {
                              // إذا نعم (مثلاً جاء من الإعدادات)، ارجع لها
                              context.pop();
                            } else {
                              // إذا لا (جاء من شريط التنقل)، اذهب للرئيسية مباشرة
                              context.go('/home');
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        "الملف الشخصي",
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
                      // --- صورة البروفايل ---
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF0F55E8),
                                      Color(0xFF5D12D2),
                                    ],
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 55,
                                  backgroundImage:
                                      _imageFile != null &&
                                          _imageFile!.existsSync()
                                      ? FileImage(_imageFile!) as ImageProvider
                                      : const AssetImage(
                                          'assets/images/group.jpg',
                                        ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E1A34),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF0F55E8),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // --- حاوية النموذج ---
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1A34).withOpacity(0.60),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                          ),
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
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 20),

                              CustomTextField(
                                label: "رقم الهاتف",
                                hint: "05X XXX XXXX",
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 20),

                              // --- حقل العنوان الجديد ---
                              CustomTextField(
                                label: "العنوان",
                                hint: "المدينة، الحي، الشارع",
                                controller: _addressController,
                                keyboardType: TextInputType.streetAddress,
                              ),
                              const SizedBox(height: 20),

                              // --- حقل الموقع على الخريطة ---
                              Text(
                                "الموقع الجغرافي",
                                style: GoogleFonts.cairo(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: _pickLocation,
                                borderRadius: BorderRadius.circular(12),
                                child: IgnorePointer(
                                  // لمنع الكتابة اليدوية وجعل المستخدم يضغط لفتح الخريطة
                                  child: CustomTextField(
                                    label: "",
                                    hint: "اضغط لتحديد الموقع على الخريطة",
                                    controller: _locationController,
                                    // هنا يمكنك تمرير أيقونة الخريطة إذا كان CustomTextField يدعم suffixIcon
                                    // أو تركها هكذا فالضغط عليها سيفعل الدالة
                                  ),
                                ),
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
