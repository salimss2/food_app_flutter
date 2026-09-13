import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart'; // <-- استيراد حزمة التوجيه
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Consumer, Provider;

import '../../../../core/widgets/custom_background.dart';
import '../../../../core/widgets/shared_bottom_nav_bar.dart';
import '../../../../providers/favorites_provider.dart';
import '../../../../providers/restaurant_provider.dart';

class RestaurantsScreen extends ConsumerStatefulWidget {
  const RestaurantsScreen({super.key});

  @override
  ConsumerState<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends ConsumerState<RestaurantsScreen> {
  // تم تعيين الاندكس إلى 1 ليكون مطابقاً لزر "البحث / تصفح المطاعم"
  int _selectedIndex = 1;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // This is a root-tab screen — never allow the system pop here.
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (didPop) return;
        // Hardware back button → always go to Home (never exit the app).
        context.go('/home');
      },
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
                  child: const SharedBottomNavBar(selectedIndex: 1),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1A34).withOpacity(0.60) : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: GoogleFonts.cairo(color: isDark ? Colors.white : Colors.black87),
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: "what_are_you_looking_for".tr(),
          hintStyle: GoogleFonts.cairo(color: isDark ? Colors.white54 : Colors.black54),
          prefixIcon: Icon(Icons.search, color: isDark ? Colors.white54 : Colors.black54),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close, color: isDark ? Colors.white54 : Colors.black54),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : Icon(Icons.qr_code_scanner, color: isDark ? Colors.white54 : Colors.black54),
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
        _buildCategoryItem("home_projects".tr(), Icons.home_rounded, false),
        _buildCategoryItem("nearest".tr(), Icons.map_rounded, false),
        _buildCategoryItem("newest".tr(), Icons.new_releases, true),
        _buildCategoryItem("favorite".tr(), Icons.favorite_rounded, false),
      ],
    );
  }

  Widget _buildCategoryItem(String title, IconData icon, bool isNew) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1A34).withOpacity(0.6) : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.1)),
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
                  ? (isDark ? Colors.purpleAccent : const Color(0xFF0F55E8))
                  : (isDark ? Colors.white.withOpacity(0.7) : Colors.black87),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: GoogleFonts.cairo(
            color: isDark ? Colors.white : Colors.black87,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asyncRestaurants = ref.watch(restaurantProvider);

    return asyncRestaurants.when(
      data: (allRestaurants) {
        if (allRestaurants.isEmpty) {
          return Center(
            child: Text(
              "no_restaurants".tr(),
              style: GoogleFonts.cairo(color: isDark ? Colors.white : Colors.black87),
            ),
          );
        }

        final displayedRestaurants = _searchQuery.isEmpty
            ? allRestaurants
            : allRestaurants.where((restaurant) {
                return restaurant.name.toLowerCase().contains(_searchQuery.toLowerCase());
              }).toList();

        if (displayedRestaurants.isEmpty) {
          return Center(
            child: Text(
              "no_matching_restaurants".tr(),
              style: GoogleFonts.cairo(color: isDark ? Colors.white54 : Colors.black54, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: displayedRestaurants.length,
          itemBuilder: (context, index) {
            final restaurant = displayedRestaurants[index];
            final String name = restaurant.name.isNotEmpty ? restaurant.name : 'restaurant_name'.tr();
            final String desc = "restaurant_desc".tr(namedArgs: {'name': name});
            final String image = restaurant.imageUrl ??
                'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=500&q=80';
            final double rating = restaurant.rating;
            final double parsedDistance =
                double.tryParse(restaurant.distance.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 2.5;
            final bool isOpen = restaurant.isOpen;
            final List<String> tags = restaurant.tags;

            // Simple map for fav and extra param
            final Map<String, dynamic> restaurantMap = {
              "id": restaurant.id,
              "name": restaurant.name,
              "address": restaurant.address,
              "distance": restaurant.distance,
              "rating": restaurant.rating,
              "isOpen": restaurant.isOpen,
              "imageUrl": restaurant.imageUrl,
              "tags": restaurant.tags,
              "menus": restaurant.menus.map((menu) => {
                "id": menu.id,
                "name": menu.name,
                "meals": menu.meals.map((meal) => {
                  "id": meal.id,
                  "name": meal.name,
                  "description": meal.description,
                  "price": meal.price,
                  "imageUrl": meal.imageUrl,
                }).toList(),
              }).toList(),
              "meals": restaurant.meals.map((meal) => {
                "id": meal.id,
                "name": meal.name,
                "description": meal.description,
                "price": meal.price,
                "imageUrl": meal.imageUrl,
              }).toList(),
            };

            return GestureDetector(
              onTap: () {
                context.push('/restaurant-detail', extra: restaurantMap);
              },
          child: Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1A34).withOpacity(0.5) : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- اليمين: اللوجو والتقييم والمسافة ---
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        image,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: const Color(0xFF2A2547),
                            child: const Center(
                              child: Icon(
                                Icons.wifi_off,
                                color: Colors.grey,
                                size: 24,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${parsedDistance.toStringAsFixed(1)} " + "km".tr(),
                      style: GoogleFonts.cairo(
                        color: isDark ? Colors.white70 : Colors.black87,
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
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        desc,
                        style: GoogleFonts.cairo(
                          color: isDark ? Colors.white54 : Colors.black54,
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
                                  color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                                  ),
                                ),
                                child: Text(
                                  tag.toString(),
                                  style: GoogleFonts.cairo(
                                    color: isDark ? Colors.white70 : Colors.black87,
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
                          "open".tr(),
                          style: GoogleFonts.cairo(
                            color: const Color(0xFFE69B35),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 15),
                        Consumer<FavoritesProvider>(
                          builder: (context, fav, _) {
                            final rId = restaurant.id.isNotEmpty ? restaurant.id : restaurant.name;
                            final isFav = fav.isRestaurantFav(rId);
                            return GestureDetector(
                              onTap: () => fav.toggleRestaurant(restaurantMap),
                              child: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: const Color(0xFFFF5555),
                                size: 22,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, StackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            "error_loading_restaurants".tr(),
            style: GoogleFonts.cairo(color: isDark ? Colors.white : Colors.black87),
          ),
        ),
      ),
    );
  }

}
