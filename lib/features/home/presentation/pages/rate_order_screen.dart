import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/custom_background.dart';

class RateOrderScreen extends StatefulWidget {
  const RateOrderScreen({super.key});

  @override
  State<RateOrderScreen> createState() => _RateOrderScreenState();
}

class _RateOrderScreenState extends State<RateOrderScreen> {
  double foodRating = 5;
  double driverRating = 5;
  double restaurantRating = 5;
  final TextEditingController _commentController = TextEditingController();

  Future<void> _submitReview() async {
    // Show thank you message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'شكراً لتقييمك! نحن نقدر ملاحظاتك 💖',
          style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
        ),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Clear navigation stack and go to home
    context.go('/home');
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // --- Header Illustration ---
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD32F2F).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.local_shipping_outlined,
                              color: Color(0xFFD32F2F),
                              size: 50,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "كيف كانت تجربتك؟",
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "تقييمك يساعدنا على تحسين خدماتنا باستمرار",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 35),

                        // --- Rating Sections ---
                        _buildRatingSection(
                          "تقييم الوجبات",
                          foodRating,
                          (rating) => setState(() => foodRating = rating),
                        ),
                        const SizedBox(height: 20),
                        _buildRatingSection(
                          "تقييم المندوب",
                          driverRating,
                          (rating) => setState(() => driverRating = rating),
                        ),
                        const SizedBox(height: 20),
                        _buildRatingSection(
                          "تقييم المطعم",
                          restaurantRating,
                          (rating) => setState(() => restaurantRating = rating),
                        ),
                        const SizedBox(height: 35),

                        // --- Comment Field ---
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            "أضف تعليقاً إضافياً (اختياري)",
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _commentController,
                          maxLines: 4,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            hintText: "أخبرنا برأيك في الطلب والخدمة...",
                            hintStyle: GoogleFonts.cairo(
                              color: Colors.white30,
                              fontSize: 13,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF2A2640).withOpacity(0.6),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 15,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.05),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.05),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFD32F2F),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),

                // --- Bottom Submit Button ---
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF140C36).withOpacity(0.95),
                    border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.05)),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 5,
                        shadowColor: const Color(0xFFD32F2F).withOpacity(0.5),
                      ),
                      child: Text(
                        "إرسال التقييم",
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  // --- AppBar ---
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
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Text(
            "تقييم الطلب",
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 40), // Placeholder to balance AppBar
        ],
      ),
    );
  }

  // --- Reusable Rating Section ---
  Widget _buildRatingSection(
    String title,
    double currentRating,
    Function(double) onRatingChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2640).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              return GestureDetector(
                onTap: () => onRatingChanged(starIndex.toDouble()),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Icon(
                    starIndex <= currentRating ? Icons.star : Icons.star_border,
                    color: starIndex <= currentRating
                        ? const Color(0xFFED922A) // Filled Orange
                        : Colors.white24, // Outline Grey
                    size: 36,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
