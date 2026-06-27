import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../core/widgets/custom_background.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/api/endpoints.dart';

class ComplaintOrInquiryScreen extends StatefulWidget {
  const ComplaintOrInquiryScreen({super.key});

  @override
  State<ComplaintOrInquiryScreen> createState() =>
      _ComplaintOrInquiryScreenState();
}

class _ComplaintOrInquiryScreenState extends State<ComplaintOrInquiryScreen> {
  // 🌟 التعديل هنا: القيمة الافتراضية أصبحت بالإنجليزية ليفهمها السيرفر
  String selectedType = 'inquiry'; // Options: 'complaint', 'inquiry'
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    final subject = _subjectController.text.trim();
    final details = _detailsController.text.trim();

    if (subject.isEmpty || details.isEmpty) {
      _showSnackBar('الرجاء تعبئة جميع الحقول', Colors.red.shade700);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dio = DioClient().dio;
      final response = await dio.post(
        Endpoints.sendSupportMessage,
        data: {
          'type': selectedType, // 🌟 سيتم إرسال inquiry أو complaint
          'subject': subject,
          'details': details,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar('تم إرسال رسالتك بنجاح', Colors.green.shade700);
        _subjectController.clear();
        _detailsController.clear();
        
        if (mounted) {
          context.pop();
        }
      }
    } on DioException catch (e) {
      debugPrint('API Error: ${e.response?.data}');
      _showSnackBar('فشل في إرسال الرسالة، يرجى المحاولة لاحقاً', Colors.red.shade700);
    } catch (e) {
      debugPrint('Unexpected Error: $e');
      _showSnackBar('حدث خطأ غير متوقع', Colors.red.shade700);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cairo(color: Colors.white),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomBackground(
          child: SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "نوع الرسالة",
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildTypeSelector(),
                        const SizedBox(height: 25),
                        Text(
                          "الموضوع",
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(
                          controller: _subjectController,
                          hint: "أدخل عنوان المشكلة أو الاستفسار",
                          maxLines: 1,
                        ),
                        const SizedBox(height: 25),
                        Text(
                          "التفاصيل",
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(
                          controller: _detailsController,
                          hint: "يرجى وصف التفاصيل بوضوح...",
                          minLines: 5,
                          maxLines: 10,
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFED922A),
                              disabledBackgroundColor: Colors.grey.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                              shadowColor: const Color(
                                0xFFED922A,
                              ).withOpacity(0.5),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    "إرسال",
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
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

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_forward_ios_rounded, // RTL correct direction
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Text(
            "إرسال شكوى أو استفسار",
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        // 🌟 التعديل هنا: تمرير النص للواجهة والقيمة للسيرفر
        _buildTypeChip(title: 'استفسار', value: 'inquiry'),
        const SizedBox(width: 15),
        _buildTypeChip(title: 'شكوى', value: 'complaint'),
      ],
    );
  }

  // 🌟 التعديل هنا: استقبال المتغيرين المنفصلين
  Widget _buildTypeChip({required String title, required String value}) {
    bool isSelected = selectedType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedType = value), // يحفظ القيمة الإنجليزية
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFED922A)
                : const Color(0xFF2A2640),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFED922A)
                  : Colors.white.withOpacity(0.1),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFED922A).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              title, // يعرض النص العربي في الواجهة
              style: GoogleFonts.cairo(
                color: isSelected ? Colors.white : Colors.white54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int? minLines,
    int? maxLines,
  }) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      style: GoogleFonts.cairo(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.cairo(color: Colors.white30),
        filled: true,
        fillColor: const Color(0xFF1E1A34).withOpacity(0.6),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFED922A), width: 1.5),
        ),
      ),
    );
  }
}