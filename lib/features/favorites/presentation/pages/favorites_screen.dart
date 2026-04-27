import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../providers/favorites_provider.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesProvider>().fetchFavorites();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF140C36), Color(0xFF0A0618)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // --- الهيدر ---
                _buildHeader(context),
                const SizedBox(height: 20),

                // --- التابات ---
                _buildTabBar(),
                const SizedBox(height: 20),

                // --- محتوى التابات ---
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const BouncingScrollPhysics(),
                    children: [_buildRestaurantsTab(), _buildMealsTab()],
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
  // الهيدر
  // ===========================================================================
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
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
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Text(
            'المفضلة',
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF416C).withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFF416C).withOpacity(0.3),
              ),
            ),
            child: const Icon(
              Icons.favorite,
              color: Color(0xFFFF416C),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // شريط التابات
  // ===========================================================================
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A34).withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'المطاعم'),
          Tab(text: 'الوجبات'),
        ],
      ),
    );
  }

  // ===========================================================================
  // تاب المطاعم المفضلة
  // ===========================================================================
  Widget _buildRestaurantsTab() {
    return Consumer<FavoritesProvider>(
      builder: (context, fav, _) {
        if (fav.favRestaurants.isEmpty) {
          return _buildEmptyState('لا توجد مطاعم مفضلة بعد 💔');
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: fav.favRestaurants.length,
          itemBuilder: (context, index) {
            final restaurant = fav.favRestaurants[index];
            return _buildRestaurantCard(context, restaurant, fav);
          },
        );
      },
    );
  }

  Widget _buildRestaurantCard(
    BuildContext context,
    Map<String, dynamic> restaurant,
    FavoritesProvider fav,
  ) {
    final String name = restaurant['name']?.toString() ?? 'اسم المطعم';
    final double rating =
        double.tryParse(restaurant['rating']?.toString() ?? '4.0') ?? 4.0;
    final bool isOpen = restaurant['isOpen'] ?? true;

    final String desc = restaurant['description']?.toString() ?? '';
    final String image =
        restaurant['imageUrl']?.toString() ??
        'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=500&q=80';

    return GestureDetector(
      onTap: () => context.push('/restaurant-detail', extra: restaurant),
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
            // --- الصورة ---
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

            // --- التفاصيل ---
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
                ],
              ),
            ),

            // --- الحالة والمفضلة ---
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
                      color: const Color(0xFFE69B35).withOpacity(0.2),
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
                GestureDetector(
                  onTap: () => fav.toggleRestaurant(restaurant),
                  child: const Icon(
                    Icons.favorite,
                    color: Color(0xFFFF5555),
                    size: 22,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // تاب الوجبات المفضلة
  // ===========================================================================
  Widget _buildMealsTab() {
    return Consumer<FavoritesProvider>(
      builder: (context, fav, _) {
        if (fav.favMeals.isEmpty) {
          return _buildEmptyState('لا توجد وجبات مفضلة بعد 💔');
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: fav.favMeals.length,
          itemBuilder: (context, index) {
            final meal = fav.favMeals[index];
            return _buildMealCard(context, meal, fav);
          },
        );
      },
    );
  }

  Widget _buildMealCard(
    BuildContext context,
    Map<String, dynamic> meal,
    FavoritesProvider fav,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      height: 110,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2640).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          // --- الصورة ---
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: Image.network(
                  meal['imageUrl'] ??
                      'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&q=80',
                  width: 110,
                  height: 110,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 110,
                      height: 110,
                      color: const Color(0xFF2A2547),
                      child: const Center(
                        child: Icon(
                          Icons.wifi_off,
                          color: Colors.grey,
                          size: 30,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => fav.toggleMeal(meal),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Color(0xFFFF416C),
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),

          // --- النصوص ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal['name'] ?? "وجبة",
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meal['description'] ?? "تفاصيل الوجبة غير متوفرة",
                    style: GoogleFonts.cairo(
                      color: Colors.white54,
                      fontSize: 10,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

          // --- السعر ---
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${meal['price']} ر.ي",
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // حالة فارغة
  // ===========================================================================
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1A34).withOpacity(0.6),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Center(
              child: Icon(
                Icons.favorite_border,
                color: Colors.white.withOpacity(0.2),
                size: 50,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: GoogleFonts.cairo(
              color: Colors.white54,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'اضغط على أيقونة القلب لإضافة العناصر هنا',
            style: GoogleFonts.cairo(color: Colors.white30, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
