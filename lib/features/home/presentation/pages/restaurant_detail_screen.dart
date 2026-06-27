import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'dart:ui';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import '../../../../core/widgets/custom_background.dart';
import '../../../../providers/cart_provider.dart';
import '../../../../providers/favorites_provider.dart';
import '../../../../core/api/endpoints.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final Map<String, dynamic> restaurantData;

  const RestaurantDetailScreen({super.key, required this.restaurantData});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  int? _selectedCategoryId;
  bool _isLoading = true;
  Map<String, dynamic>? _detailedRestaurantData;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchRestaurantDetails();
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

  @override
  // 🌟 أضف هذه الدالة
  Future<void> _fetchRestaurantDetails() async {
    try {
      // 1. جلب التوكن من الذاكرة
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');

      // 2. رقم المطعم الحالي
      final restaurantId = widget.restaurantData['id'];

      // 3. الاتصال بالسيرفر (تأكد من مسار الـ API الخاص بك)
      final response = await Dio().get(
        '${Endpoints.baseUrl}/v1/restaurants/$restaurantId', // 🌟 هكذا سيقرأ الرابط الجديد دائماً
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      // 4. حفظ البيانات وإيقاف التحميل
      if (response.statusCode == 200) {
        setState(() {
          // أحياناً لارافل يضع البيانات داخل كائن 'data'، نفحص ذلك
          _detailedRestaurantData = response.data['data'] ?? response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching restaurant details: $e');
      setState(() {
        _isLoading = false; // نوقف التحميل حتى لو حدث خطأ لكي لا تعلق الشاشة
      });
    }
  }

  // بيانات وهمية للوجبات محذوفة لاستخدام البيانات الحقيقية

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E1E2C), // نفس لون خلفية تطبيقك
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    // 🌟 السطر الذهبي: تحديد مصدر البيانات
    // إذا كانت البيانات التفصيلية موجودة نستخدمها، وإلا نستخدم البيانات المختصرة كاحتياط
    final dataSource = _detailedRestaurantData ?? widget.restaurantData;
    // Task 3: Print full data for debugging
    debugPrint(
      "DEBUG: Full Restaurant Data: ${jsonEncode(widget.restaurantData)}",
    );

    final bool isRestaurantOpen = dataSource['isOpen'] == true ||
                                  dataSource['is_open'] == true || 
                                  dataSource['is_open'] == 1 || 
                                  dataSource['is_open'] == '1' ||
                                  dataSource['status']?.toString().toLowerCase() == 'open';
    
    final bool isClosed = !isRestaurantOpen;

    // 1. استخراج الفئات والوجبات وتجهيزها للفلترة
    // تم إضافة بدائل إضافية (categories, items, products) لضمان عدم اختفاء البيانات
    final List<dynamic> categoriesRaw =
        dataSource['meal_categories'] ??
        dataSource['menus'] ??
        dataSource['categories'] ??
        [];

    // Task 2: Category List Builder Check (Debug Message)
    if (categoriesRaw.isEmpty) {
      debugPrint(
        "Debug: Restaurant categories list is empty! Key 'meal_categories' not found or has no items.",
      );
      debugPrint("Raw Data Keys: ${widget.restaurantData.keys.toList()}");
    }

    // تجهيز الوجبات مع التأكد من وجود معرف الفئة لكل وجبة
    final List<dynamic> allMeals = [];
    final Set<String> seenMealIds = {};

    for (var category in categoriesRaw) {
      final categoryId = category['id'];
      final meals = category['meals'] as List? ?? [];

      for (var meal in meals) {
        final mealId = meal['id']?.toString() ?? meal['name']?.toString() ?? '';
        if (seenMealIds.add(mealId)) {
          // إضافة معرف الفئة للوجبة لتسهيل الفلترة لاحقاً
          final updatedMeal = Map<String, dynamic>.from(meal);
          updatedMeal['category_id'] ??= categoryId;
          allMeals.add(updatedMeal);
        }
      }
    }

    // إضافة الوجبات الموجودة في المستوى الأعلى (إن وجدت) - مع دعم بدائل للمفاتيح
    final List<dynamic> topLevelMeals =
        dataSource['meals'] ??
        dataSource['items'] ??
        dataSource['products'] ??
        [];
    for (var meal in topLevelMeals) {
      final mealId = meal['id']?.toString() ?? meal['name']?.toString() ?? '';
      if (seenMealIds.add(mealId)) {
        allMeals.add(meal);
      }
    }

    // 2. بناء قائمة الفئات للـ UI
    final List<Map<String, dynamic>> dynamicCategories = [
      {
        "id": null,
        "name": "الكل",
        "icon": Icons.local_fire_department,
        "color": const Color(0xFFF27B21),
        "isIcon": true,
      },
      ...categoriesRaw.map((cat) {
        // 1. استخراج مسار الصورة ومعالجته (مثلما فعلنا مع الوجبات)
        String? rawImage = cat['image'];
        String? finalCatImageUrl;

        if (rawImage != null && rawImage.toString().isNotEmpty) {
          if (rawImage.toString().startsWith('http')) {
            finalCatImageUrl = rawImage.toString();
          } else {
            // ⚠️ ضع رابط السيرفر الخاص بك هنا
            finalCatImageUrl =
                'https://tennessee-refine-ancient-supporters.trycloudflare.com/storage/$rawImage';
          }
        }

        return {
          "id": cat['id'],
          "name": cat['name'] ?? 'بدون اسم',
          "icon": Icons.restaurant_menu, // الأيقونة الاحتياطية
          "color": const Color(0xFFE53935),
          "isIcon":
              finalCatImageUrl ==
              null, // 🌟 إذا لم تكن هناك صورة، استخدم الأيقونة
          "image": finalCatImageUrl, // 🌟 تمرير رابط الصورة الصحيح
        };
      }),
    ];

    final selectedCategoryName = dynamicCategories.firstWhere(
      (cat) => cat['id'] == _selectedCategoryId,
      orElse: () => dynamicCategories.first,
    )['name'];

    // تصفية الوجبات بناءً على الفئة المختارة والبحث
    final filteredMeals = allMeals.where((meal) {
      final matchesCategory =
          _selectedCategoryId == null ||
          meal['category_id'] == _selectedCategoryId;
      final matchesSearch =
          _searchQuery.isEmpty ||
          (meal['name']?.toString().contains(_searchQuery) ?? false);
      return matchesCategory && matchesSearch;
    }).toList();

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
                    _buildHeroSection(context, isClosed),

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
                                _buildStatusAndPriceRow(isClosed),
                              ],
                            ),
                          ),

                          const SizedBox(height: 25),
                          // Task 3: Layout Constraints (Wrapped in SizedBox/Height to prevent collapse)
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
                                _buildMenuItemsList(filteredMeals, isClosed),
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
  Widget _buildHeroSection(BuildContext context, bool isClosed) {
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
        child: isClosed ? Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.9),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_clock, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Text(
                  "currently_closed".tr(),
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ) : null,
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
                          hintText: "search_meal_hint".tr(),
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
                              "restaurant_name_unavailable".tr(),
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
                                "restaurant_location".tr(),
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
                        "review_count".tr(),
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
  Widget _buildStatusAndPriceRow(bool isClosed) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isClosed ? Colors.red : const Color(0xFFFFC107),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isClosed ? "closed".tr() : "open".tr(),
            style: GoogleFonts.cairo(
              color: isClosed ? Colors.white : Colors.black,
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
                "prices_match_restaurant".tr(),
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
                    child: category["isIcon"]
                        ? Icon(
                            category["icon"],
                            color: category["color"],
                            size: 20,
                          )
                        : Image.network(
                            // ✅ تم التعديل إلى صورة من الإنترنت
                            category["image"],
                            width: 34,
                            height: 34,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // إذا فشل تحميل الصورة لسبب ما، اعرض الأيقونة الاحتياطية
                              return Icon(
                                category["icon"],
                                color: category["color"],
                                size: 20,
                              );
                            },
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
  Widget _buildMenuItemsList(List<dynamic> filteredMeals, bool isClosed) {
    if (_searchQuery.isNotEmpty && filteredMeals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'no_meals_search'.tr(),
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    } else if (_searchQuery.isEmpty && filteredMeals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'no_meals_category'.tr(),
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: filteredMeals.length,
      itemBuilder: (context, index) {
        final meal = filteredMeals[index];
        return _buildMenuItemCard(meal, index, isClosed);
      },
    );
  }

  Widget _buildMenuItemCard(Map<String, dynamic> meal, int index, bool isClosed) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // تحديد متغيرات الوجبة بأمان
    final String mealId = meal['id'].toString();
    final String mealName = meal['name'] ?? 'no_name'.tr();
    final bool hasOptions = meal['variants'] != null && (meal['variants'] as List).isNotEmpty;
    final String mealDesc = meal['description'] ?? 'no_description'.tr();
    final double mealPrice = meal['price'] != null
        ? double.tryParse(meal['price'].toString()) ?? 0.0
        : 0.0;

    // Parse discount properties safely
    final double? priceAfterDiscount = meal['price_after_discount'] != null
        ? double.tryParse(meal['price_after_discount'].toString())
        : null;

    final String? discountType = meal['discount_type']?.toString();
    final double? discountValue = meal['discount_value'] != null
        ? double.tryParse(meal['discount_value'].toString())
        : null;

    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }
    final DateTime? discountStart = parseDateTime(meal['discount_start']);
    final DateTime? discountEnd = parseDateTime(meal['discount_end']);

    final now = DateTime.now();
    final bool isPromoActive = priceAfterDiscount != null &&
        priceAfterDiscount > 0 &&
        priceAfterDiscount < mealPrice &&
        (discountStart == null || discountStart.isBefore(now)) &&
        (discountEnd == null || discountEnd.isAfter(now));

    final double price = isPromoActive ? priceAfterDiscount : mealPrice;
    final double? oldPrice = isPromoActive ? mealPrice : null;

    int? discountPercent;
    if (isPromoActive) {
      if (discountType == 'percentage' && discountValue != null) {
        discountPercent = discountValue.round();
      } else {
        final double diff = mealPrice - priceAfterDiscount;
        discountPercent = ((diff / mealPrice) * 100).round();
      }
    }
    // 🌟 البحث عن الصورة باسم image أو imageUrl
    String? rawImage = meal['image'] ?? meal['imageUrl'] ?? meal['photo'];

    String? finalImageUrl;
    if (rawImage != null && rawImage.isNotEmpty) {
      // إذا كان الرابط كاملاً من لارافل نستخدمه، وإذا كان مساراً فقط نضيف له رابط السيرفر
      if (rawImage.startsWith('http')) {
        finalImageUrl = rawImage;
      } else {
        // ⚠️ تأكد من وضع الرابط الأساسي لسيرفرك هنا
        finalImageUrl =
            'https://tennessee-refine-ancient-supporters.trycloudflare.com/storage/$rawImage';
      }
    }

    // ثم مرر المتغير الجديد
    final String? imageUrl = finalImageUrl;

    final bool isAvailable = meal['available'] == null
        ? true
        : (meal['available'] is bool
              ? meal['available']
              : (meal['available'] is int
                    ? meal['available'] == 1
                    : (meal['available'].toString() == '1' ||
                          meal['available'].toString().toLowerCase() ==
                              'true')));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E1A34).withOpacity(0.5)
                  : Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white.withOpacity(0.5),
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
            child: Opacity(
              opacity: (isAvailable && !isClosed) ? 1.0 : 0.5,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // 1. صورة الوجبة (مع معالجة الأخطاء)
                  Stack(
                    children: [
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
                      if (isPromoActive && discountPercent != null && discountPercent > 0)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5555),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF5555).withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              "-$discountPercent%",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
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
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
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
                                    onTap: () => fav.toggleMeal(
                                      Map<String, dynamic>.from(meal),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8.0,
                                      ),
                                      child: Icon(
                                        isFav
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: isFav
                                            ? const Color(0xFFFF416C)
                                            : Colors.grey,
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
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black54,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),

                          // السعر وزر الإضافة
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '${price.toStringAsFixed(0)} ',
                                    style: TextStyle(
                                      color: isPromoActive ? const Color(0xFFFF5555) : (isDark ? Colors.white : Colors.black87),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${'currency'.tr()} ',
                                    style: TextStyle(
                                      color: isPromoActive ? const Color(0xFFFF5555) : (isDark ? Colors.white70 : Colors.black54),
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (oldPrice != null) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '${oldPrice.toStringAsFixed(0)} ${'currency'.tr()}',
                                      style: TextStyle(
                                        color: isDark ? Colors.white38 : Colors.black38,
                                        fontSize: 12,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ],
                                ],
                              ),

                              // زر الإضافة للسلة (مربوط بـ CartProvider)
                              hasOptions 
                                ? ElevatedButton(
                                    onPressed: (!isAvailable || isClosed) ? null : () => _showMealOptionsBottomSheet(context, meal, imageUrl),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isClosed ? Colors.grey : const Color(0xFFE63946),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: Text(
                                      isClosed ? 'restaurant_closed'.tr() : 'view_options'.tr(),
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  )
                                : Consumer<CartProvider>(
                                    builder: (context, cart, child) {
                                  final qty = cart.getQuantityByMealId(mealId);
                                  final isItemLoading = cart.isItemLoading(
                                    mealId,
                                  );

                                  if (qty == 0) {
                                    // ─── زر «أضف للسلة» الاعتيادي ───
                                    return ElevatedButton(
                                      onPressed: (!isAvailable || isItemLoading || isClosed)
                                          ? null
                                          : () {
                                              cart
                                                  .addItem(
                                                    CartItem(
                                                      mealId: mealId,
                                                      name: mealName,
                                                      price: price,
                                                      imageUrl:
                                                          imageUrl ??
                                                          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&q=80',
                                                      quantity: 1,
                                                      addons: [],
                                                    ),
                                                  )
                                                  .then((_) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'item_added_to_cart'
                                                              .tr(
                                                                namedArgs: {
                                                                  'name':
                                                                      mealName,
                                                                },
                                                              ),
                                                        ),
                                                        backgroundColor:
                                                            Colors.green,
                                                        duration:
                                                            const Duration(
                                                              seconds: 1,
                                                            ),
                                                      ),
                                                    );
                                                  })
                                                  .catchError((e) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'add_to_cart_failed'.tr(
                                                            namedArgs: {
                                                              'error': e
                                                                  .toString(),
                                                            },
                                                          ),
                                                        ),
                                                        backgroundColor:
                                                            Colors.red.shade700,
                                                      ),
                                                    );
                                                  });
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isClosed ? Colors.grey : const Color(0xFFE63946),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                          : Text(
                                              isClosed ? 'restaurant_closed'.tr() : (isAvailable ? 'add_to_cart'.tr() : 'out_of_stock'.tr()),
                                              style: const TextStyle(
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
                                      color: isClosed ? Colors.grey : const Color(0xFFE63946),
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
                                            icon: const Icon(
                                              Icons.remove,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            onPressed:
                                                isItemLoading ||
                                                    cartItemId.isEmpty
                                                ? null
                                                : () => cart.decrementQuantity(
                                                    cartItemId,
                                                  ),
                                          ),
                                        ),
                                        // ─ الكمية ─
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                          ),
                                          child: isItemLoading
                                              ? const SizedBox(
                                                  width: 14,
                                                  height: 14,
                                                  child:
                                                      CircularProgressIndicator(
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
                                            icon: const Icon(
                                              Icons.add,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            onPressed:
                                                isItemLoading ||
                                                        cartItemId.isEmpty ||
                                                        isClosed
                                                    ? null
                                                : () => cart.incrementQuantity(
                                                    cartItemId,
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
                        ],
                      ),
                    ),
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
  // 5a. Bottom Sheet for Options
  // ===========================================================================
  void _showMealOptionsBottomSheet(BuildContext context, dynamic meal, String? imageUrl) {
    final List variants = meal['variants'] ?? [];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1A34).withOpacity(0.9),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'available_options'.tr(),
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: variants.length,
                      separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.1)),
                      itemBuilder: (context, index) {
                        final variant = variants[index];
                        final String variantName = variant['name']?.toString() ?? '';
                        final double variantPrice = double.tryParse(variant['price']?.toString() ?? '0') ?? 0.0;
                        final int variantId = int.tryParse(variant['id']?.toString() ?? '0') ?? 0;
                        
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                variantName,
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${variantPrice.toStringAsFixed(0)} ${'currency'.tr()}',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFFFF5555),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Consumer<CartProvider>(
                              builder: (context, cart, child) {
                                final isItemLoading = cart.isItemLoading(meal['id'].toString(), variantId: variantId);
                                
                                return ElevatedButton(
                                  onPressed: isItemLoading ? null : () {
                                    cart.addItem(
                                      CartItem(
                                        mealId: meal['id'].toString(),
                                        variantId: variantId,
                                        variantName: variantName,
                                        name: meal['name']?.toString() ?? '',
                                        price: variantPrice,
                                        imageUrl: imageUrl ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&q=80',
                                        quantity: 1,
                                      )
                                    ).then((_) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('item_added_to_cart'.tr(namedArgs: {'name': '${meal['name']} ($variantName)'})),
                                          backgroundColor: Colors.green,
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                      Navigator.pop(context);
                                    }).catchError((e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('add_to_cart_failed'.tr(namedArgs: {'error': e.toString()})),
                                          backgroundColor: Colors.red.shade700,
                                        ),
                                      );
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE63946),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: isItemLoading 
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : Text('add_to_cart'.tr(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                                );
                              }
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
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
                        'special_offer'.tr(),
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
                  meal['name'] ?? 'meal'.tr(),
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
                      '${meal['price']} ${'currency'.tr()}',
                      style: GoogleFonts.cairo(
                        color: const Color(0xFFED922A),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$oldPrice ${'currency'.tr()}',
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
                        'save_amount'.tr(
                          namedArgs: {
                            'amount': '${(oldPrice - (meal['price'] ?? 0))}',
                            'currency': 'currency'.tr(),
                          },
                        ),
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
                                      name:
                                          meal['name']?.toString() ??
                                          'meal'.tr(),
                                      imageUrl:
                                          meal['imageUrl']?.toString() ??
                                          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&q=80',
                                      price: price,
                                      quantity: 1,
                                      addons: [],
                                    ),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'item_added_to_cart'.tr(
                                          namedArgs: {
                                            'name': '${meal['name']}',
                                          },
                                        ),
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
                                        'add_to_cart_failed'.tr(
                                          namedArgs: {'error': e.toString()},
                                        ),
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
                                        'add_to_cart'.tr(),
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
                            icon: const Icon(
                              Icons.remove,
                              color: Colors.white,
                              size: 20,
                            ),
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
                            icon: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 20,
                            ),
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
                        'available_options'.tr(),
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
                              '$optionPrice ${'currency'.tr()}',
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
                                      'item_added_to_cart'.tr(
                                        namedArgs: {
                                          'name':
                                              '${meal['name']} - $optionName',
                                        },
                                      ),
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
                                      'add_to_cart_failed'.tr(
                                        namedArgs: {'error': e.toString()},
                                      ),
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
                                'add_to_cart'.tr(),
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
