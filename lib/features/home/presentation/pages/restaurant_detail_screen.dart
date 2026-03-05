import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/custom_background.dart';

class RestaurantDetailScreen extends StatefulWidget {
  const RestaurantDetailScreen({super.key});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  // فئات المنيو
  final List<String> _categories = ["الاكثر طلبا 🔥", "المقبلات", "الغداء", "الفته"];
  int _selectedCategoryIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomBackground(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. الصورة العلوية مع الأزرار العائمة وتداخل البطاقة
                _buildHeroSection(context),

                // 2. المحتوى السفلي المرفوع لأعلى ليتداخل مع الصورة
                Transform.translate(
                  offset: const Offset(0, -40), // رفع المحتوى لأعلى ليتداخل مع الصورة
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // بطاقة تفاصيل المطعم الزجاجية
                        _buildRestaurantInfoCard(),
                        
                        const SizedBox(height: 20),
                        
                        // شريط حالة المطعم (مفتوح / الأسعار)
                        _buildStatusAndPriceRow(),
                        
                        const SizedBox(height: 25),
                        
                        // شريط تصنيفات المنيو
                        _buildMenuTabBar(),
                        
                        const SizedBox(height: 25),
                        
                        // عنوان القسم الحالي
                        Text(
                          "الاكثر طلبا",
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        const SizedBox(height: 15),
                        
                        // قائمة الوجبات
                        _buildMenuItemsList(),
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

  // ===========================================================================
  // 1. القسم العلوي (الصورة + أزرار التحكم)
  // ===========================================================================
  Widget _buildHeroSection(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // صورة المطعم
        Container(
          height: 280,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              // يرجى التأكد من وجود صورة مناسبة في هذا المسار
              image: AssetImage('assets/images/group.jpg'), 
              fit: BoxFit.cover,
            ),
          ),
          // إضافة تدرج لوني داكن أسفل الصورة لدمجها بسلاسة مع الخلفية
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  const Color(0xFF140C36).withOpacity(0.8), // لون الخلفية
                ],
                stops: const [0.6, 1.0],
              ),
            ),
          ),
        ),
        
        // الأزرار العلوية (رجوع، مفضلة، خيارات)
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // زر الرجوع
                _buildTopIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => context.pop(),
                  iconSize: 18,
                ),
                // أزرار اليسار
                Row(
                  children: [
                    _buildTopIconButton(
                      icon: Icons.favorite,
                      onTap: () {},
                      iconSize: 20,
                    ),
                    const SizedBox(width: 10),
                    _buildTopIconButton(
                      icon: Icons.more_horiz,
                      onTap: () {},
                      iconSize: 24,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // زر دائري داكن للأيقونات العلوية
  Widget _buildTopIconButton({required IconData icon, required VoidCallback onTap, double iconSize = 20}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Center(
              child: Icon(icon, color: Colors.white, size: iconSize),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. بطاقة معلومات المطعم الزجاجية
  // ===========================================================================
  Widget _buildRestaurantInfoCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1A34).withOpacity(0.65),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "اجواء طيبه",
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.arrow_back_ios_rounded, color: Colors.white54, size: 12),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                "فوه المساكن امام صيدلية كيربلس",
                                style: GoogleFonts.cairo(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // زر الخريطة
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Color(0xFF110C24),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.navigation, color: Colors.white, size: 24),
                  ),
                ],
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: Colors.white.withOpacity(0.1), height: 1),
              ),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // النجوم
                  Row(
                    children: List.generate(5, (index) => const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.star, color: Colors.amber, size: 18),
                    )),
                  ),
                  // التقييمات
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "عدد التقييمات",
                        style: GoogleFonts.cairo(color: Colors.white54, fontSize: 10, height: 1),
                      ),
                      Text(
                        "(652)",
                        style: GoogleFonts.cairo(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. شريط الحالة (مفتوح / مطابقة الأسعار)
  // ===========================================================================
  Widget _buildStatusAndPriceRow() {
    return Row(
      children: [
        // زر "مفتوح"
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFC107), // لون أصفر/ذهبي
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "مفتوح",
            style: GoogleFonts.cairo(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 15),
        // زر "الأسعار مطابقة للمطعم"
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1A34).withOpacity(0.60),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Center(
              child: Text(
                "الأسعار مطابقة للمطعم",
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 4. شريط تصنيفات المنيو القابل للتمرير
  // ===========================================================================
  Widget _buildMenuTabBar() {
    return Row(
      children: [
        // أيقونة البحث
        const Icon(Icons.search, color: Colors.white54, size: 24),
        const SizedBox(width: 15),
        // قائمة التصنيفات
        Expanded(
          child: SizedBox(
            height: 35,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedCategoryIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategoryIndex = index),
                  child: Container(
                    margin: const EdgeInsets.only(left: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _categories[index],
                          style: GoogleFonts.cairo(
                            color: isSelected ? Colors.white : Colors.white54,
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        // الخط السفلي للعنصر المحدد
                        if (isSelected)
                          Container(
                            height: 2,
                            width: 30,
                            color: const Color(0xFF0F55E8), // أزرق البراند
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 5. قائمة الوجبات
  // ===========================================================================
  Widget _buildMenuItemsList() {
    return ListView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 3, // عدد الوجبات الافتراضي للعرض
      itemBuilder: (context, index) {
        return _buildMenuItemCard();
      },
    );
  }

  // بطاقة الوجبة الواحدة
  Widget _buildMenuItemCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      height: 130,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A34).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Stack(
        children: [
          // المحتوى الأساسي للبطاقة (النصوص + الصورة)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // النصوص (اليمين)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 35), // مساحة لزر القلب
                        child: Text(
                          "بيتزا مارجريتا",
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "قطع الدجاج المقليه مع البطاطس المقليه و البيتزا اللذيذه",
                        style: GoogleFonts.cairo(
                          color: Colors.white54,
                          fontSize: 11,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        "\$16.00",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                
                // صورة الوجبة (اليسار)
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/dish.png'), // تأكد من المسار
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // أيقونة المفضلة (أعلى اليمين في الكارد)
          const Positioned(
            top: 15,
            right: 15,
            child: Icon(Icons.favorite_border, color: Colors.white, size: 22),
          ),

          // زر الإضافة (+) المتراكب مع الصورة (أسفل اليسار)
          Positioned(
            bottom: 10,
            left: 10,
            child: Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}