import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/custom_background.dart';
import '../../../../providers/cart_provider.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final Map<String, dynamic> restaurantData;

  const RestaurantDetailScreen({super.key, required this.restaurantData});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  // فئات المنيو
  final List<Map<String, dynamic>> _categories = [
    {
      "name": "المفضلة",
      "icon": Icons.favorite,
      "color": const Color(0xFFFF416C),
      "isIcon": true,
    },
    {
      "name": "الأكثر طلبًا",
      "icon": Icons.local_fire_department,
      "color": const Color(0xFFF27B21),
      "isIcon": true,
    },
    {"name": "المقبلات", "image": "assets/images/dish.png", "isIcon": false},
    {
      "name": "الأطباق الرئيسية",
      "image": "assets/images/burger.png",
      "isIcon": false,
    },
  ];

  int _selectedCategoryIndex = 1;

  // بيانات وهمية للوجبات محذوفة لاستخدام البيانات الحقيقية

  @override
  Widget build(BuildContext context) {
    final List<dynamic> menu = widget.restaurantData['menu'] ?? [];

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
                          _buildMenuTabBar(),
                          const SizedBox(height: 25),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _categories[_selectedCategoryIndex]["name"],
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
        child: Row(
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
                  onTap: () {},
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
  Widget _buildMenuTabBar() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategoryIndex == index;
          final category = _categories[index];

          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
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
    return ListView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: menu.length,
      itemBuilder: (context, index) {
        return _buildMenuItemCard(menu[index]);
      },
    );
  }

  Widget _buildMenuItemCard(dynamic meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      height: 110, // ارتفاع مناسب للبطاقة
      decoration: BoxDecoration(
        color: const Color(
          0xFF2A2640,
        ).withOpacity(0.6), // لون الخلفية الداكن المائل للرمادي
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          // --- 1. الصورة وأيقونة المفضلة (اليمين) ---
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
                ),
              ),
              // أيقونة القلب في دائرة بيضاء
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_border,
                    color: Color(0xFFFF416C), // لون أحمر/وردي
                    size: 16,
                  ),
                ),
              ),
              // شعار التوصيل (مصغر في الأسفل)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delivery_dining,
                    color: Colors.red,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),

          // --- 2. النصوص (المنتصف) ---
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

          // --- 3. السعر والزر (اليسار) ---
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                Consumer<CartProvider>(
                  builder: (context, cart, _) {
                    final mealId =
                        meal['id']?.toString() ??
                        meal['name']?.toString() ??
                        '';
                    final index = cart.items.indexWhere(
                      (item) => item.id == mealId,
                    );
                    final cartItem = index >= 0 ? cart.items[index] : null;

                    if (cartItem == null) {
                      return GestureDetector(
                        onTap: () {
                          final double price =
                              double.tryParse(
                                (meal['price']?.toString() ?? '0').replaceAll(
                                  RegExp(r'[^0-9.]'),
                                  '',
                                ),
                              ) ??
                              0.0;
                          Provider.of<CartProvider>(
                            context,
                            listen: false,
                          ).addItem(
                            CartItem(
                              id: mealId,
                              name: meal['name']?.toString() ?? 'وجبة',
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
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFED922A),
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
                      );
                    } else {
                      return Container(
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => Provider.of<CartProvider>(
                                context,
                                listen: false,
                              ).incrementQuantity(cartItem.id),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                            Text(
                              cartItem.quantity.toString(),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Provider.of<CartProvider>(
                                context,
                                listen: false,
                              ).decrementQuantity(cartItem.id),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Icon(
                                  Icons.remove,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
