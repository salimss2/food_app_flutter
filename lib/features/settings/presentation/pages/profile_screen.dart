import 'package:customer_app/core/api/endpoints.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart'; // <-- استيراد حزمة المسارات
import 'package:path/path.dart' as path; // <-- استيراد للتعامل مع أسماء الملفات

import '../../../../core/widgets/global_exit_wrapper.dart';
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
  bool hasUnsavedChanges = false;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _locationController;
  bool isLoading = false; // أضف هذا المتغير

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
    });

    // تحميل الصورة الدائمة
    String? imagePath = prefs.getString('saved_image_path');
    if (imagePath != null && imagePath.isNotEmpty) {
      File savedImage = File(imagePath);
      // التأكد من أن الملف لا يزال موجوداً فعلياً في الذاكرة
      if (await savedImage.exists()) {
        setState(() {
          _imageFile = savedImage;
        });
      }
    }
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
          _imageFile = File(
            pickedFile.path,
          ); // هذه صورة مؤقتة سيتم تثبيتها عند الحفظ
          hasUnsavedChanges = true;
        });
      }
    } catch (e) {
      debugPrint("خطأ في اختيار الصورة: $e");
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) return 'يرجى إدخال الاسم';
    if (value.length < 3) return 'الاسم يجب أن يكون 3 أحرف على الأقل';
    return null;
  }

  // --- دالة الحفظ المحدثة (حفظ الصورة بشكل دائم) ---
  // استيراد حزمة Dio في أعلى الملف إذا لم تكن موجودة

  // --- دالة الحفظ المحدثة (حفظ في السيرفر ثم محلياً) ---
  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true; // إظهار حالة التحميل
      });

      try {
        // 1. جلب التوكن الخاص بالمستخدم من SharedPreferences أو من AuthBloc
        final prefs = await SharedPreferences.getInstance();
        final String? token = prefs.getString(
          'auth_token',
        ); // تأكد من اسم المفتاح الذي تحفظ به التوكن عند تسجيل الدخول

        // 2. تجهيز البيانات للإرسال (FormData لدعم رفع الصور)
        final formData = FormData.fromMap({
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'address': _addressController.text,
          'location': _locationController.text,
        });

        // 3. إضافة الصورة إذا تم اختيارها
        if (_imageFile != null) {
          formData.files.add(
            MapEntry(
              'image',
              await MultipartFile.fromFile(
                _imageFile!.path,
                filename: path.basename(_imageFile!.path),
              ),
            ),
          );
        }

        // 4. إرسال الطلب للسيرفر
        final dio = Dio();
final response = await dio.post(
  Endpoints.updateProfile, // <--- هنا نستخدم المتغير بدلاً من الرابط النصي
  data: formData,
  options: Options(
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    },
  ),
);

        if (response.statusCode == 200) {
          // ==========================================
          // 5. إذا نجح الحفظ في السيرفر، نحفظ البيانات محلياً
          // ==========================================

          await prefs.setString('saved_phone', _phoneController.text);
          await prefs.setString('saved_address', _addressController.text);
          await prefs.setString('saved_location', _locationController.text);

          // حفظ الصورة بشكل دائم محلياً
          if (_imageFile != null) {
            final directory = await getApplicationDocumentsDirectory();
            final String fileName = path.basename(_imageFile!.path);
            final String permanentPath = '${directory.path}/$fileName';

            if (_imageFile!.path != permanentPath) {
              final File permanentImage = await _imageFile!.copy(permanentPath);
              await prefs.setString('saved_image_path', permanentImage.path);
              _imageFile = permanentImage;
            }
          }

          if (mounted) {
            setState(() {
              hasUnsavedChanges = false;
            });
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
      } catch (e) {
        // 6. التعامل مع أخطاء السيرفر
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'حدث خطأ أثناء حفظ البيانات. يرجى المحاولة لاحقاً.',
                style: GoogleFonts.cairo(),
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
          debugPrint("Error updating profile: $e");
        }
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false; // إخفاء حالة التحميل
          });
        }
      }
    }
  }












  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;

        if (hasUnsavedChanges) {
          // SCENARIO 1: User has typing/unsaved changes
          final bool shouldDiscard = await _showUnsavedChangesDialog();
          if (shouldDiscard) {
            setState(() {
              hasUnsavedChanges = false;
            });
            // After discarding, if there's a previous page, pop to it.
            // If not (it's the bottom nav root), just clear changes. The user must press back again to exit.
            if (GoRouter.of(context).canPop()) {
              if (context.mounted) context.pop();
            }
          }
        } else {
          // SCENARIO 2: No unsaved changes. Safe to navigate.
          if (GoRouter.of(context).canPop()) {
            // Not a root screen, just go back normally.
            if (context.mounted) context.pop();
          } else {
            // Root screen (Bottom Nav) -> Show the global App Exit dialog!
            final bool shouldExit =
                await showExitConfirmationDialog(context) ?? false;
            if (shouldExit) {
              SystemNavigator.pop();
            }
          }
        }
      },
      child: Scaffold(
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
                            onPressed: () async {
                              if (hasUnsavedChanges) {
                                final shouldPop =
                                    await _showUnsavedChangesDialog();
                                if (shouldPop && context.mounted) {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.go('/home');
                                  }
                                }
                              } else {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go('/home');
                                }
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
                                        ? FileImage(_imageFile!)
                                              as ImageProvider
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
                                  onChanged: (value) {
                                    if (!hasUnsavedChanges)
                                      setState(() {
                                        hasUnsavedChanges = true;
                                      });
                                  },
                                ),
                                const SizedBox(height: 20),

                                CustomTextField(
                                  label: "البريد الإلكتروني",
                                  hint: "example@mail.com",
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  onChanged: (value) {
                                    if (!hasUnsavedChanges)
                                      setState(() {
                                        hasUnsavedChanges = true;
                                      });
                                  },
                                ),
                                const SizedBox(height: 20),

                                CustomTextField(
                                  label: "رقم الهاتف",
                                  hint: "05X XXX XXXX",
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  onChanged: (value) {
                                    if (!hasUnsavedChanges)
                                      setState(() {
                                        hasUnsavedChanges = true;
                                      });
                                  },
                                ),
                                const SizedBox(height: 20),

                                CustomTextField(
                                  label: "العنوان",
                                  hint: "المدينة، الحي، الشارع",
                                  controller: _addressController,
                                  keyboardType: TextInputType.streetAddress,
                                  onChanged: (value) {
                                    if (!hasUnsavedChanges)
                                      setState(() {
                                        hasUnsavedChanges = true;
                                      });
                                  },
                                ),
                                const SizedBox(height: 30),

                                // --- بطاقة الموقع الجغرافي ---
                                Text(
                                  "الموقع الجغرافي",
                                  style: GoogleFonts.cairo(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                GestureDetector(
                                  onTap: () async {
                                    await context.push('/map-picker');
                                    _loadSavedData();
                                    if (!hasUnsavedChanges)
                                      setState(() {
                                        hasUnsavedChanges = true;
                                      });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1B172E),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.08),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            children: [
                                              Text(
                                                "تحديد الموقع على الخريطة",
                                                style: GoogleFonts.cairo(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                "في حال إختلاف موقعك الحالي عن موقع التوصيل، يرجى تحديد الموقع الخاص بك بالضغط على الخريطة التالية",
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.cairo(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                bottom: Radius.circular(16),
                                              ),
                                          child: Image.asset(
                                            'assets/images/map_snapshot.png',
                                            height: 150,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                                      height: 150,
                                                      width: double.infinity,
                                                      color: Colors.white
                                                          .withOpacity(0.05),
                                                      child: const Icon(
                                                        Icons.map_outlined,
                                                        color: Colors.white54,
                                                        size: 50,
                                                      ),
                                                    ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                if (_locationController.text.isNotEmpty) ...[
                                  const SizedBox(height: 15),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        color: Color(0xFF0F55E8),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _locationController.text,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textDirection: TextDirection.ltr,
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // --- زر الحفظ ---
                        // --- زر الحفظ ---
                        isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF0F55E8),
                                ),
                              )
                            : ShinyButton(
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
      ),
    );
  }

  Future<bool> _showUnsavedChangesDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color(0xFF140C36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  "تنبيه",
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              "لديك تغييرات لم يتم حفظها، هل أنت متأكد أنك تريد الخروج؟",
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  "إلغاء",
                  style: GoogleFonts.cairo(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  "تجاهل",
                  style: GoogleFonts.cairo(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F55E8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  await _saveProfile();
                  if (context.mounted) {
                    Navigator.of(context).pop(true);
                  }
                },
                child: Text(
                  "حفظ",
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
    return result ?? false;
  }
}