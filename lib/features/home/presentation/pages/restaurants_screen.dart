import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart'; // <-- استيراد حزمة التوجيه

import '../../../../core/widgets/custom_background.dart';
import '../../../../core/widgets/global_exit_wrapper.dart';

class RestaurantsScreen extends StatefulWidget {
  const RestaurantsScreen({super.key});

  @override
  State<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends State<RestaurantsScreen> {
  // تم تعيين الاندكس إلى 1 ليكون مطابقاً لزر "البحث / تصفح المطاعم"
  int _selectedIndex = 1;

  List<dynamic> allRestaurants = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadRestaurants();
  }

  Future<void> loadRestaurants() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/mock_database.json',
      );
      final data = await json.decode(response);
      setState(() {
        allRestaurants = data['restaurants'];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint("Error loading restaurants: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlobalExitWrapper(
      child: Scaffold(
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: CustomBackground(
            child: Stack(
              children: [
                // --- محتوى الصفحة القابل للتمرير ---
                SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 120),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),

                          // 1. شريط البحث
                          _buildSearchBar(),

                          const SizedBox(height: 25),

                          // 2. التصنيفات
                          _buildCategories(),

                          const SizedBox(height: 25),

                          // 3. قائمة المطاعم
                          _buildRestaurantList(),
                        ],
                      ),
                    ),
                  ),
                ),

                // --- شريط التنقل السفلي العائم ---
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _buildFloatingNavBar(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. شريط البحث
  // ===========================================================================
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A34).withOpacity(0.60),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        style: GoogleFonts.cairo(color: Colors.white),
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: "عن ماذا تبحث؟",
          hintStyle: GoogleFonts.cairo(color: Colors.white54),
          prefixIcon: const Icon(Icons.search, color: Colors.white54),
          suffixIcon: const Icon(Icons.qr_code_scanner, color: Colors.white54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. التصنيفات
  // ===========================================================================
  Widget _buildCategories() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildCategoryItem("مشاريع منزلية", Icons.home_rounded, false),
        _buildCategoryItem("الأقرب", Icons.map_rounded, false),
        _buildCategoryItem("الجديدة", Icons.new_releases, true),
        _buildCategoryItem("المفضلة", Icons.favorite_rounded, false),
      ],
    );
  }

  Widget _buildCategoryItem(String title, IconData icon, bool isNew) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1A34).withOpacity(0.6),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              size: 35,
              color: isNew
                  ? Colors.purpleAccent
                  : Colors.white.withOpacity(0.7),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 3. بطاقات المطاعم
  // ===========================================================================
  Widget _buildRestaurantList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }

    if (allRestaurants.isEmpty) {
      return Center(
        child: Text(
          "لا توجد مطاعم",
          style: GoogleFonts.cairo(color: Colors.white),
        ),
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: allRestaurants.length,
      itemBuilder: (context, index) {
        final restaurant = allRestaurants[index];
        final String name = restaurant['name']?.toString() ?? 'اسم المطعم';
        final String desc = restaurant['description']?.toString() ?? '';
        final String image =
            restaurant['imageUrl']?.toString() ??
            'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=500&q=80';
        final double rating =
            double.tryParse(restaurant['rating']?.toString() ?? '4.0') ?? 4.0;
        final double parsedDistance =
            double.tryParse(restaurant['distance']?.toString() ?? '2.5') ?? 2.5;
        final bool isOpen = restaurant['isOpen'] ?? true;
        final List<dynamic> tags = restaurant['tags'] ?? [];

        return GestureDetector(
          onTap: () {
            context.push('/restaurant-detail', extra: restaurant);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1A34).withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- اليمين: اللوجو والتقييم والمسافة ---
                Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(image),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${parsedDistance.toStringAsFixed(1)} كيلو",
                      style: GoogleFonts.cairo(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (starIndex) => Icon(
                          Icons.star,
                          color: starIndex < rating.toInt()
                              ? Colors.amber
                              : Colors.white24,
                          size: 10,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 12),

                // --- الوسط: التفاصيل (الاسم، العنوان، التاجات) ---
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        desc,
                        style: GoogleFonts.cairo(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: tags
                            .map(
                              (tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                child: Text(
                                  tag.toString(),
                                  style: GoogleFonts.cairo(
                                    color: Colors.white70,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),

                // --- اليسار: حالة المطعم والمفضلة ---
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isOpen)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFE69B35,
                          ).withOpacity(0.2), // برتقالي شفاف
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE69B35).withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          "مفتوح",
                          style: GoogleFonts.cairo(
                            color: const Color(0xFFE69B35),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 15),
                    const Icon(
                      Icons.favorite_border,
                      color: Color(0xFFFF5555),
                      size: 22,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 4. شريط التنقل السفلي
  // ===========================================================================
  Widget _buildFloatingNavBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: Container(
        height: 75,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 54, 37, 124).withOpacity(0.8),
              blurRadius: 25,
              offset: const Offset(0, 10),
              spreadRadius: -5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1A34).withOpacity(0.1),
                borderRadius: BorderRadius.circular(35),
                border: Border.all(
                  color: Colors.white.withOpacity(0.7),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _navItem(
                    selectedIcon: Icons.manage_search,
                    unselectedIcon: Icons.manage_search_outlined,
                    label: "البحث",
                    index: 1,
                  ),
                  _navItem(
                    selectedIcon: Icons.shopping_cart,
                    unselectedIcon: Icons.shopping_cart_outlined,
                    label: "السلة",
                    index: 2,
                  ),
                  _navItem(
                    selectedIcon: Icons.home,
                    unselectedIcon: Icons.home_outlined,
                    label: "الرئيسية",
                    index: 0,
                  ),
                  _navItem(
                    selectedIcon: Icons.receipt,
                    unselectedIcon: Icons.receipt_outlined,
                    label: "طلباتي",
                    index: 3,
                  ),
                  _navItem(
                    selectedIcon: Icons.person,
                    unselectedIcon: Icons.person_outline,
                    label: "حسابي",
                    index: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // منطق الانتقال بين الصفحات
  // ===========================================================================
  Widget _navItem({
    required IconData selectedIcon,
    required IconData unselectedIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        // إذا ضغط المستخدم على نفس الصفحة التي هو فيها، لا تفعل شيئاً
        if (isSelected) return;

        if (index == 0) {
          // الانتقال إلى الصفحة الرئيسية
          context.go('/home');
        } else if (index == 2) {
          // الانتقال إلى سلة المشتريات
          context.push('/cart');
        } else if (index == 4) {
          // الانتقال إلى صفحة الملف الشخصي
          context.go('/profile');
        } else {
          // للصفحات الأخرى (مثل السلة والطلبات)، نحدث الـ UI مؤقتاً
          setState(() => _selectedIndex = index);
        }
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              ShaderMask(
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    colors: [
                      Color(0xFF0F55E8),
                      Color.fromARGB(255, 130, 87, 199),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ).createShader(bounds);
                },
                child: Icon(selectedIcon, color: Colors.white, size: 26),
              )
            else
              Icon(unselectedIcon, color: Colors.white54, size: 26),

            const SizedBox(height: 4),

            Text(
              label,
              style: GoogleFonts.cairo(
                color: isSelected ? const Color(0xFF0F55E8) : Colors.white54,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
