import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/custom_background.dart';
import '../../../../providers/cart_provider.dart';
import '../../../../providers/favorites_provider.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final Map<String, dynamic> restaurantData;

  const RestaurantDetailScreen({super.key, required this.restaurantData});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  int? _selectedCategoryId;

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // بيانات وهمية للوجبات محذوفة لاستخدام البيانات الحقيقية

  @override
  Widget build(BuildContext context) {
    // Flatten all meals from nested menus structure: menus[].meals[]
    final List<dynamic> menusRaw = widget.restaurantData['meal_categories'] ?? widget.restaurantData['menus'] ?? [];
    final List<dynamic> nestedMeals = menusRaw
        .expand((menu) => (menu['meals'] as List? ?? []))
        .toList();

    // Also capture any top-level meals (from restaurant.meals directly)
    final List<dynamic> topLevelMeals = widget.restaurantData['meals'] ?? [];

    // Merge both sources, avoiding duplicates by id
    final Set<String> seenIds = {};
    final List<dynamic> menu = [];
    for (final m in [...nestedMeals, ...topLevelMeals]) {
      final id = m['id']?.toString() ?? m['name']?.toString() ?? '';
      if (seenIds.add(id)) {
        menu.add(m);
      }
    }

    // بناء قائمة الفئات ديناميكيًا
    final List<Map<String, dynamic>> dynamicCategories = [
      {
        "id": null,
        "name": "الكل",
        "icon": Icons.local_fire_department,
        "color": const Color(0xFFF27B21),
        "isIcon": true,
      },
      ...menusRaw.map((m) => {
            "id": m['id'],
            "name": m['name'] ?? 'بدون اسم',
            "icon": Icons.restaurant_menu,
            "color": const Color(0xFFE53935),
            "isIcon": true,
          }),
    ];

    final selectedCategoryName = dynamicCategories.firstWhere(
      (cat) => cat['id'] == _selectedCategoryId,
      orElse: () => dynamicCategories.first,
    )['name'];

    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomBackground(
          child: Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 50),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. الصورة العلوية
                    _buildHeroSection(context),

                    // 2. المحتوى السفلي
                    Transform.translate(
                      offset: const Offset(0, -40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                _buildRestaurantInfoCard(),
                                const SizedBox(height: 20),
                                _buildStatusAndPriceRow(),
                              ],
                            ),
                          ),

                          const SizedBox(height: 25),
                          _buildMenuTabBar(dynamicCategories),
                          const SizedBox(height: 25),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedCategoryName,
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 15),

                                // قائمة الوجبات
                                _buildMenuItemsList(menu),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildStickyActionBar(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. القسم العلوي
  // ===========================================================================
  Widget _buildHeroSection(BuildContext context) {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(
            widget.restaurantData['imageUrl'] ??
                'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=500&q=80',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              const Color(0xFF140C36).withOpacity(0.8),
            ],
            stops: const [0.6, 1.0],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // Sticky Action Bar
  // ===========================================================================
  Widget _buildStickyActionBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: _isSearching
            ? Row(
                children: [
                  _buildTopIconButton(
                    icon: Icons.arrow_forward,
                    onTap: () {
                      setState(() {
                        _isSearching = false;
                        _searchController.clear();
                      });
                    },
                    iconSize: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1A34).withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: "ابحث عن وجبة...",
                          hintStyle: GoogleFonts.cairo(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.only(
                            bottom: 11,
                            right: 15,
                            left: 15,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white54,
                              size: 18,
                            ),
                            onPressed: () {
                              _searchController.clear();
                            },
                          ),
                        ),
                        cursorColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTopIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => context.pop(),
                    iconSize: 18,
                  ),
                  Row(
                    children: [
                      _buildTopIconButton(
                        icon: Icons.person_outline,
                        onTap: () {},
                        iconSize: 22,
                      ),
                      const SizedBox(width: 8),
                      _buildTopIconButton(
                        icon: Icons.ios_share_outlined,
                        onTap: () {},
                        iconSize: 22,
                      ),
                      const SizedBox(width: 8),
                      _buildCartIconButton(context),
                      const SizedBox(width: 8),
                      _buildTopIconButton(
                        icon: Icons.search_outlined,
                        onTap: () => setState(() => _isSearching = true),
                        iconSize: 22,
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCartIconButton(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        int totalItems = cart.items.fold(0, (sum, item) => sum + item.quantity);
        return GestureDetector(
          onTap: () => context.push('/cart'),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
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
                        Icons.shopping_cart_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
              if (totalItems > 0)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF416C),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF140C36),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      '$totalItems',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopIconButton({
    required IconData icon,
    required VoidCallback onTap,
    double iconSize = 20,
  }) {
    return GestureDetector(
      onTap: onTap,
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
            child: Center(
              child: Icon(icon, color: Colors.white, size: iconSize),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. بطاقة معلومات المطعم
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
                          widget.restaurantData['name'] ??
                              "اسم المطعم غير متوفر",
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.white54,
                              size: 12,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                "المكلا، أمام المملكة مول",
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
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Color(0xFF110C24),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.navigation,
                      color: Colors.white,
                      size: 24,
                    ),
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
                  Row(
                    children: List.generate(
                      5,
                      (index) => const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.star, color: Colors.amber, size: 18),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "عدد التقييمات",
                        style: GoogleFonts.cairo(
                          color: Colors.white54,
                          fontSize: 10,
                          height: 1,
                        ),
                      ),
                      Text(
                        "(652)",
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
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
  // 3. شريط الحالة
  // ===========================================================================
  Widget _buildStatusAndPriceRow() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFC107),
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
  // 4. أزرار الفلترة
  // ===========================================================================
  Widget _buildMenuTabBar(List<Map<String, dynamic>> categories) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategoryId == category['id'];

          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryId = category['id']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(left: 12),
              padding: const EdgeInsets.only(
                right: 6,
                left: 16,
                top: 6,
                bottom: 6,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFED922A)
                    : const Color(0xFF2A2640).withOpacity(0.7),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : Colors.white.withOpacity(0.05),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Center(
                      child: category["isIcon"]
                          ? Icon(
                              category["icon"],
                              color: category["color"],
                              size: 20,
                            )
                          : Image.asset(
                              category["image"],
                              width: 34,
                              height: 34,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    category["name"],
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                    ),
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
  // 5. قائمة الوجبات المحدثة (تصميم مطابق للسكرين شوت)
  // ===========================================================================
  Widget _buildMenuItemsList(List<dynamic> menu) {
    // --- فلترة الوجبات حسب الفئة المختارة ---
    final displayMenu = _selectedCategoryId == null
        ? menu
        : menu.where((meal) => 
            meal['meal_category_id'] == _selectedCategoryId || 
            meal['menu_id'] == _selectedCategoryId).toList();

    List<dynamic> finalMenu = displayMenu;
    if (_searchQuery.isNotEmpty) {
      finalMenu = finalMenu.where((meal) {
        final name = meal['name']?.toString().toLowerCase() ?? '';
        return name.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (_searchQuery.isNotEmpty && finalMenu.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'لا توجد وجبات مطابقة لبحثك 🍽️',
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    } else if (_searchQuery.isEmpty && finalMenu.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'لا توجد وجبات مضافة في هذه الفئة 😔',
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: finalMenu.length,
      itemBuilder: (context, index) {
        final meal = finalMenu[index];
        final originalIndex = menu.indexOf(meal);
        // يمكنك إرجاع _buildOfferCard إذا كانت هناك طريقة ديناميكية لمعرفة العروض
        return _buildMenuItemCard(meal, originalIndex);
      },
    );
  }

  Widget _buildMenuItemCard(Map<String, dynamic> meal, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // تحديد متغيرات الوجبة بأمان
    final String mealId = meal['id'].toString();
    final String mealName = meal['name'] ?? 'بدون اسم';
    final String mealDesc = meal['description'] ?? 'لا يوجد وصف';
    final double mealPrice = meal['price'] != null
        ? double.tryParse(meal['price'].toString()) ?? 0.0
        : 0.0;
    final String? imageUrl = meal['imageUrl'];
    

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1A34).withOpacity(0.5) : Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                if (isDark)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                else
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
              ],
            ),
            child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. صورة الوجبة (مع معالجة الأخطاء)
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 120,
                        height: 120,
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.fastfood,
                          color: Colors.grey,
                          size: 40,
                        ),
                      );
                    },
                  )
                : Container(
                    width: 120,
                    height: 120,
                    color: Colors.grey[800],
                    child: const Icon(
                      Icons.fastfood,
                      color: Colors.grey,
                      size: 40,
                    ),
                  ),
          ),

          // 2. تفاصيل الوجبة (باستخدام Expanded لمنع الخروج عن الشاشة)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // اسم الوجبة مع أيقونة المفضلة
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          mealName,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Consumer<FavoritesProvider>(
                        builder: (context, fav, _) {
                          final isFav = fav.isMealFav(mealId);
                          return GestureDetector(
                            onTap: () => fav.toggleMeal(Map<String, dynamic>.from(meal)),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? const Color(0xFFFF416C) : Colors.grey,
                                size: 22,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // وصف الوجبة
                  Text(
                    mealDesc,
                    style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // السعر وزر الإضافة
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$mealPrice ر.ي',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // زر الإضافة للسلة (مربوط بـ CartProvider)
                      Consumer<CartProvider>(
                        builder: (context, cart, child) {
                          final qty = cart.getQuantityByMealId(mealId);
                          final isItemLoading = cart.isItemLoading(mealId);

                          if (qty == 0) {
                            // ─── زر «أضف للسلة» الاعتيادي ───
                            return ElevatedButton(
                              onPressed: isItemLoading
                                  ? null
                                  : () {
                                      cart
                                          .addItem(
                                            CartItem(
                                              mealId: mealId,
                                              name: mealName,
                                              price: mealPrice,
                                              imageUrl: imageUrl ??
                                                  'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&q=80',
                                              quantity: 1,
                                              addons: [],
                                            ),
                                          )
                                          .then((_) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'تمت إضافة $mealName إلى السلة! 🛒',
                                                ),
                                                backgroundColor: Colors.green,
                                                duration:
                                                    const Duration(seconds: 1),
                                              ),
                                            );
                                          })
                                          .catchError((e) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'فشل الإضافة: $e'),
                                                backgroundColor:
                                                    Colors.red.shade700,
                                              ),
                                            );
                                          });
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE63946),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: isItemLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'أضف للسلة',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                            );
                          }
                          // ─── عداد +/- ───
                          final cartItem = cart.getItemByMealId(mealId);
                          final cartItemId = cartItem?.id ?? '';
                          return Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE63946),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // ─ زر الطرح ─
                                SizedBox(
                                  width: 32,
                                  height: 36,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.remove,
                                        color: Colors.white, size: 16),
                                    onPressed: isItemLoading || cartItemId.isEmpty
                                        ? null
                                        : () => cart
                                            .decrementQuantity(cartItemId),
                                  ),
                                ),
                                // ─ الكمية ─
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6),
                                  child: isItemLoading
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          '$qty',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                                // ─ زر الجمع ─
                                SizedBox(
                                  width: 32,
                                  height: 36,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.add,
                                        color: Colors.white, size: 16),
                                    onPressed: isItemLoading || cartItemId.isEmpty
                                        ? null
                                        : () => cart
                                            .incrementQuantity(cartItemId),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
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

  // ===========================================================================
  // 5b. بطاقة العرض الكبيرة (Offer Card)
  // ===========================================================================
  Widget _buildOfferCard(dynamic meal, int mealIndex) {
    final mealId = meal['id']?.toString() ?? meal['name']?.toString() ?? '';
    final double price =
        double.tryParse(
          (meal['price']?.toString() ?? '0').replaceAll(RegExp(r'[^0-9.]'), ''),
        ) ??
        0.0;
    final oldPrice = meal['oldPrice'] ?? meal['price'];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A34),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- القسم العلوي: الصورة والبادجات ---
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Image.network(
                  meal['imageUrl'] ??
                      'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&q=80',
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 180,
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
              // --- تدرج داكن فوق الصورة ---
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF1E1A34).withOpacity(0.7),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // --- بادج "عرض خاص" (أعلى اليسار) ---
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE53935), Color(0xFFFF5252)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE53935).withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_offer,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'عرض خاص',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // --- أيقونة المفضلة (أعلى اليمين) ---
              Positioned(
                top: 12,
                right: 12,
                child: Consumer<FavoritesProvider>(
                  builder: (context, fav, _) {
                    final isFav = fav.isMealFav(mealId);
                    return GestureDetector(
                      onTap: () =>
                          fav.toggleMeal(Map<String, dynamic>.from(meal)),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: const Color(0xFFFF416C),
                          size: 18,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // --- القسم السفلي: التفاصيل ---
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- اسم الوجبة ---
                Text(
                  meal['name'] ?? 'وجبة',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (meal['description'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    meal['description'],
                    style: GoogleFonts.cairo(
                      color: Colors.white54,
                      fontSize: 12,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),

                // --- صف السعر ---
                Row(
                  children: [
                    Text(
                      '${meal['price']} ر.ي',
                      style: GoogleFonts.cairo(
                        color: const Color(0xFFED922A),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$oldPrice ر.ي',
                      style: GoogleFonts.cairo(
                        color: Colors.white38,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: Colors.white38,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFE53935).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'وفّر ${(oldPrice - (meal['price'] ?? 0))} ر.ي',
                        style: GoogleFonts.cairo(
                          color: const Color(0xFFE53935),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // --- زر أضف للسلة ---
                Consumer<CartProvider>(
                  builder: (context, cart, child) {
                    final qty = cart.getQuantityByMealId(mealId);
                    final isItemLoading = cart.isItemLoading(mealId);

                    if (qty == 0) {
                      // ─── زر «أضف للسلة» كامل العرض ───
                      return GestureDetector(
                        onTap: isItemLoading
                            ? null
                            : () async {
                                try {
                                  await cart.addItem(
                                    CartItem(
                                      mealId: mealId,
                                      name: meal['name']?.toString() ?? 'وجبة',
                                      imageUrl: meal['imageUrl']?.toString() ??
                                          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&q=80',
                                      price: price,
                                      quantity: 1,
                                      addons: [],
                                    ),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'تمت إضافة ${meal['name']} للسلة بنجاح 🛒',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                      backgroundColor: Colors.green.shade700,
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'فشل الإضافة: ${e.toString()}',
                                        style:
                                            GoogleFonts.cairo(color: Colors.white),
                                      ),
                                      backgroundColor: Colors.red.shade700,
                                    ),
                                  );
                                }
                              },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE53935), Color(0xFFFF5252)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE53935).withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: isItemLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.shopping_cart_outlined,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'أضف للسلة',
                                        style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      );
                    }
                    // ─── عداد +/- كامل العرض ───
                    final cartItem = cart.getItemByMealId(mealId);
                    final cartItemId = cartItem?.id ?? '';
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE53935), Color(0xFFFF5252)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE53935).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // ─ زر الطرح ─
                          IconButton(
                            icon: const Icon(Icons.remove,
                                color: Colors.white, size: 20),
                            onPressed: isItemLoading || cartItemId.isEmpty
                                ? null
                                : () => cart.decrementQuantity(cartItemId),
                          ),
                          // ─ الكمية ─
                          isItemLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  '$qty',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          // ─ زر الجمع ─
                          IconButton(
                            icon: const Icon(Icons.add,
                                color: Colors.white, size: 20),
                            onPressed: isItemLoading || cartItemId.isEmpty
                                ? null
                                : () => cart.incrementQuantity(cartItemId),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 6. البوتوم شيت - خيارات الوجبة
  // ===========================================================================
  void _showOptionsBottomSheet(
    BuildContext context,
    dynamic meal,
    List<dynamic> options,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.only(top: 12, bottom: 24),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1A34),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- مقبض السحب ---
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),

                // --- العنوان ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        'الخيارات المتوفرة',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(sheetContext),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white54,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Divider(color: Colors.white.withOpacity(0.1), height: 1),
                const SizedBox(height: 8),

                // --- قائمة الخيارات ---
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: options.length,
                  separatorBuilder: (_, __) =>
                      Divider(color: Colors.white.withOpacity(0.06), height: 1),
                  itemBuilder: (ctx, i) {
                    final option = options[i];
                    final optionName = option['name']?.toString() ?? '';
                    final optionPrice = option['price'] ?? meal['price'] ?? 0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          // --- اسم الخيار ---
                          Expanded(
                            child: Text(
                              optionName,
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          // --- حبة السعر البرتقالية ---
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFED922A).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFED922A).withOpacity(0.4),
                              ),
                            ),
                            child: Text(
                              '$optionPrice ر.ي',
                              style: GoogleFonts.cairo(
                                color: const Color(0xFFED922A),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // --- زر أضف للسلة ---
                          GestureDetector(
                            onTap: () async {
                              final double price =
                                  double.tryParse(
                                    optionPrice.toString().replaceAll(
                                      RegExp(r'[^0-9.]'),
                                      '',
                                    ),
                                  ) ??
                                  0.0;

                              final mealId =
                                  meal['id']?.toString() ??
                                  meal['name']?.toString() ??
                                  '';

                              try {
                                await context.read<CartProvider>().addItem(
                                  CartItem(
                                    mealId: mealId,
                                    name: '${meal['name']} - $optionName',
                                    imageUrl:
                                        meal['imageUrl']?.toString() ??
                                        'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&q=80',
                                    price: price,
                                    quantity: 1,
                                    addons: [],
                                  ),
                                );

                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'تمت إضافة ${meal['name']} - $optionName للسلة بنجاح 🛒',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                    backgroundColor: Colors.green.shade700,
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'فشل الإضافة: ${e.toString()}',
                                      style: GoogleFonts.cairo(
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: Colors.red.shade700,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 237, 42, 42),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'أضف للسلة',
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
