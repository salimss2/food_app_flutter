import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Consumer, Provider;

import '../../../../core/widgets/custom_background.dart';
import '../../../../providers/favorites_provider.dart';
import '../../../../providers/restaurant_provider.dart';
import '../../../../models/restaurant_model.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  int _selectedCategoryIndex = 1;
  int _selectedTabIndex = 0;

  final List<Map<String, dynamic>> _categories = [
    {"name": "كل التصنيفات", "icon": Icons.list_alt},
    {"name": "الكل", "icon": Icons.grid_view_rounded},
    {"name": "المطاعم", "icon": Icons.fastfood_outlined},
    {"name": "خضروات وفواكه", "icon": Icons.apple_outlined},
    {"name": "عسل وتمور", "icon": Icons.hive_outlined},
  ];

  final List<String> _tabs = ["الكل", "الاقرب", "الجديدة", "المفضلة"];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asyncRestaurants = ref.watch(restaurantProvider);

    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomBackground(
          child: SafeArea(
            child: Column(
              children: [
                // 1. شريط البحث العلوي
                _buildSearchHeader(context),

                // 2. شريط التصنيفات (أيقونات)
                _buildCategoriesBar(),

                // 3. شريط التبويبات (نصوص)
                _buildTabsBar(),

                const SizedBox(height: 10),

                // 4. قائمة النتائج
                Expanded(
                  child: asyncRestaurants.when(
                    data: (allRestaurants) {
                      final displayedResults = _searchQuery.isEmpty
                          ? allRestaurants
                          : allRestaurants
                              .where((r) => r.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                              .toList();

                      if (displayedResults.isEmpty) {
                        return Center(
                          child: Text(
                            "لا توجد مطاعم مطابقة لبحثك 💔",
                            style: GoogleFonts.cairo(
                              color: isDark ? Colors.white54 : Colors.black54,
                              fontSize: 18,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        itemCount: displayedResults.length,
                        itemBuilder: (context, index) {
                          return _buildSearchResultCard(
                            displayedResults[index],
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, StackTrace) => Center(
                      child: Text(
                        "حدث خطأ أثناء تحميل المعلومات",
                        style: GoogleFonts.cairo(color: isDark ? Colors.white54 : Colors.black54),
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

  // ===========================================================================
  // 1. شريط البحث العلوي
  // ===========================================================================
  Widget _buildSearchHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_forward, color: isDark ? Colors.white : Colors.black87),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1A34).withOpacity(0.60) : Colors.white.withOpacity(0.60),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true, // يفتح الكيبورد تلقائياً
                onChanged: (val) {
                  setState(() => _searchQuery = val);
                },
                style: GoogleFonts.cairo(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: "ابحث عن...",
                  hintStyle: GoogleFonts.cairo(color: isDark ? Colors.white54 : Colors.black54),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 12,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.close,
                      color: isDark ? Colors.white54 : Colors.black54,
                      size: 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. شريط التصنيفات الأفقي (الأيقونات)
  // ===========================================================================
  Widget _buildCategoriesBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: Container(
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF0F55E8).withOpacity(
                        0.3,
                      ) // لون التحديد الأزرق بدلاً من الأحمر
                    : (isDark ? const Color(0xFF1E1A34).withOpacity(0.5) : Colors.white.withOpacity(0.7)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0F55E8)
                      : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.1)),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _categories[index]["icon"],
                    color: isSelected ? (isDark ? Colors.white : const Color(0xFF0F55E8)) : (isDark ? Colors.white54 : Colors.black54),
                    size: 28,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _categories[index]["name"],
                    style: GoogleFonts.cairo(
                      color: isSelected ? (isDark ? Colors.white : const Color(0xFF0F55E8)) : (isDark ? Colors.white54 : Colors.black54),
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 3. شريط التبويبات (النصوص)
  // ===========================================================================
  Widget _buildTabsBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 20),
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _tabs.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedTabIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected
                        ? const Color(0xFF0F55E8)
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  _tabs[index],
                  style: GoogleFonts.cairo(
                    color: isSelected ? (isDark ? Colors.white : const Color(0xFF0F55E8)) : (isDark ? Colors.white54 : Colors.black54),
                    fontSize: 16,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 4. كرت نتيجة البحث المخصص
  // ===========================================================================
  Widget _buildSearchResultCard(Restaurant result) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Map<String, dynamic> resultAsMap = {
      "id": result.id,
      "name": result.name,
      "address": result.address,
      "distance": result.distance,
      "rating": result.rating,
      "isOpen": result.isOpen,
      "imageUrl": result.imageUrl,
      "tags": result.tags,
    };

    final double parsedDistance =
        double.tryParse(result.distance.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 2.5;

    return GestureDetector(
      onTap: () => context.push('/restaurant-detail', extra: resultAsMap),
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
                    result.imageUrl ?? 'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=500&q=80',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: const Color(0xFF2A2547),
                        child: const Center(
                          child: Icon(Icons.wifi_off, color: Colors.grey, size: 24),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${parsedDistance.toStringAsFixed(1)} كيلو",
                  style: GoogleFonts.cairo(color: isDark ? Colors.white70 : Colors.black87, fontSize: 11),
                ),
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      Icons.star,
                      color: index < result.rating
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
                    result.name.isNotEmpty ? result.name : "غير معروف",
                    style: GoogleFonts.cairo(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "مطعم ${result.name}", // Fallback since API description might not exist
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
                    children: result.tags
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
                              tag,
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
                if (result.isOpen)
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
                Consumer<FavoritesProvider>(
                  builder: (context, fav, _) {
                    final isFav = fav.isRestaurantFav(result.name);
                    return GestureDetector(
                      onTap: () => fav.toggleRestaurant(resultAsMap),
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
  }
}
