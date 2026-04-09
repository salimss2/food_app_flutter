import 'dart:async'; // For auto scroll carousel interval
import 'dart:convert';
import 'dart:ui'; // <-- هام جداً لتأثير الزجاج
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart'; // <-- استيراد go_router
import 'package:provider/provider.dart';

import '../../../../core/widgets/global_exit_wrapper.dart';

import '../../../../core/widgets/custom_background.dart';
import '../../../../providers/favorites_provider.dart';
import '../widgets/home_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  List<dynamic> restaurantsList = [];
  bool isLoadingData = true;

  final PageController _pageController = PageController(viewportFraction: 0.93);
  Timer? _timer;
  int _currentPage = 0;

  final List<Map<String, dynamic>> dummyOffers = [
    {
      'title': 'عرض الغداء المدمر 🍔',
      'subtitle': 'خصم 40% على جميع وجبات البرجر',
      'discount': '40%',
      'image':
          'https://images.unsplash.com/photo-1550547660-d9450f859349?w=800&q=80',
      'color': 0xFFD32F2F, // Red theme
    },
    {
      'title': 'عشاق البيتزا 🍕',
      'subtitle': 'اطلب واحدة والثانية علينا مجاناً!',
      'discount': '1+1',
      'image':
          'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800&q=80',
      'color': 0xFFE58B29, // Orange theme
    },
    {
      'title': 'توصيل مجاني 🛵',
      'subtitle': 'لجميع طلباتك فوق 5000 ريال',
      'discount': 'مجاني',
      'image':
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&q=80',
      'color': 0xFF0F55E8, // Blue theme
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
    loadLocalDatabase();
  }

  Future<void> loadLocalDatabase() async {
    final String response = await rootBundle.loadString(
      'assets/data/mock_database.json',
    );
    final data = await json.decode(response);
    setState(() {
      restaurantsList = data['restaurants'];
      isLoadingData = false;
    });
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < dummyOffers.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0; // Loop back to the first item
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(
            milliseconds: 800,
          ), // Smooth and slow transition
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // قائمة الأقسام (تم التعديل هنا لاستخدام الأيقونات بدلاً من الصور)
  // ===========================================================================
  final List<Map<String, dynamic>> _categories = [
    {"name": "وجبات", "icon": Icons.fastfood_rounded},
    {"name": "مشاريع منزلية", "icon": Icons.home_work_rounded},
    {"name": "دجاج", "icon": Icons.local_dining_rounded},
    {"name": "رز", "icon": Icons.rice_bowl_rounded},
    {"name": "المعجنات", "icon": Icons.local_pizza_rounded},
    {"name": "ايسكريم", "icon": Icons.icecream_rounded},
    {"name": "عصائر", "icon": Icons.local_drink_rounded},
    {"name": "حلويات", "icon": Icons.cake_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return GlobalExitWrapper(
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const HomeDrawer(),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: CustomBackground(
            child: Stack(
              children: [
                // --- محتوى الصفحة القابل للتمرير ---
                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // إزاحة المحتوى لأسفل حتى لا يختفي خلف الهيدر الزجاجي في البداية
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 180), // Padding offset for header
                    ),

                    // الأقسام متحررة من الهيدر الثابت
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            _buildSectionTitle("الأقسام", showSeeAll: false),
                            const SizedBox(height: 15),
                            _buildCategoriesList(),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),

                    // باقي المحتوى
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          children: [
                            const SizedBox(height: 15),
                            _buildPromoBanner(),
                            const SizedBox(height: 25),

                            _buildSectionTitle(
                              "جميع المطاعم",
                              showSeeAll: true,
                              isButtonHighlighted: true,
                              onSeeAllTap: () {
                                context.go('/restaurants');
                              },
                            ),
                            const SizedBox(height: 15),

                            _buildRestaurantList(),
                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // --- Fixed Glassmorphism Header ---
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
                        decoration: BoxDecoration(
                          color: const Color(0xFF140C36).withOpacity(0.85),
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white.withOpacity(0.05),
                              width: 1,
                            ),
                          ),
                        ),
                        child: SafeArea(
                          bottom: false,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 10),
                              _buildHeader(),
                              const SizedBox(height: 15),
                              _buildSearchBar(),
                            ],
                          ),
                        ),
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
  // دالة عرض النافذة المنبثقة (Modal Drawer)
  // ===========================================================================
  void _showAllCategoriesModal() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1A34).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "جميع الأقسام",
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            child: GridView.builder(
                              physics: const BouncingScrollPhysics(),
                              shrinkWrap: true,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    childAspectRatio: 0.8,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 15,
                                  ),
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                return _buildCategoryItem(
                                  title: _categories[index]["name"] as String,
                                  // التعديل هنا لعرض الأيقونة
                                  child: Icon(
                                    _categories[index]["icon"] as IconData,
                                    color: Colors.white,
                                    size: 35,
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);

                                    if (_categories[index]["name"] == "وجبات") {
                                      context.push('/meals-list');
                                    }
                                  },
                                  isGrid: true,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // قائمة الأقسام
  // ===========================================================================
  Widget _buildCategoriesList() {
    return SizedBox(
      height: 110,
      child: Row(
        children: [
          _buildCategoryItem(
            title: "كل الاقسام",
            child: Icon(
              Icons.grid_view_rounded,
              color: Colors.white.withOpacity(0.8),
              size: 35,
            ),
            onTap: _showAllCategoriesModal,
          ),

          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                return _buildCategoryItem(
                  title: _categories[index]["name"] as String,
                  // التعديل هنا لعرض الأيقونة
                  child: Icon(
                    _categories[index]["icon"] as IconData,
                    color: Colors.white,
                    size: 35,
                  ),
                  onTap: () {
                    if (_categories[index]["name"] == "وجبات") {
                      context.push('/meals-list');
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem({
    required String title,
    required Widget child,
    required VoidCallback onTap,
    bool isGrid = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(left: isGrid ? 0 : 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 75,
              height: 75,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1A34).withOpacity(0.60),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: child,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // العناوين
  // ===========================================================================
  Widget _buildSectionTitle(
    String title, {
    bool showSeeAll = false,
    bool isButtonHighlighted = false,
    VoidCallback? onSeeAllTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (showSeeAll)
          InkWell(
            onTap: onSeeAllTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isButtonHighlighted ? 12.0 : 8.0,
                vertical: isButtonHighlighted ? 6.0 : 4.0,
              ),
              decoration: isButtonHighlighted
                  ? BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F55E8), Color(0xFF5D12D2)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F55E8).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    )
                  : null,
              child: Text(
                "الكل",
                style: GoogleFonts.cairo(
                  color: isButtonHighlighted ? Colors.white : Colors.white54,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ===========================================================================
  // شريط التنقل السفلي
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
                    unselectedIcon: Icons.restaurant,
                    label: "المطاعم",
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

  Widget _navItem({
    required IconData selectedIcon,
    required IconData unselectedIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        if (isSelected) return;

        if (index == 1) {
          context.go('/restaurants');
        } else if (index == 2) {
          context.push('/cart');
        } else if (index == 3) {
          context.go('/orders');
        } else if (index == 4) {
          context.go('/profile');
        } else {
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

  // ===========================================================================
  // بقية الودجت
  // ===========================================================================
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            image: const DecorationImage(
              image: AssetImage('assets/images/group.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Column(
          children: [
            Text(
              "التوصيل الآن",
              style: GoogleFonts.cairo(color: Colors.white54, fontSize: 12),
            ),
            Row(
              children: [
                Text(
                  "Maplewood Suites",
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () {
        context.push('/search');
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1A34).withOpacity(0.60),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: IgnorePointer(
          child: TextField(
            style: GoogleFonts.cairo(color: Colors.white),
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: "عن ماذا تبحث؟",
              hintStyle: GoogleFonts.cairo(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              suffixIcon: const Icon(
                Icons.qr_code_scanner,
                color: Colors.white54,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPromoBanner() {
    return SizedBox(
      height: 180,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (int index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemCount: dummyOffers.length,
        itemBuilder: (context, index) {
          final offer = dummyOffers[index];
          return Container(
            margin: const EdgeInsets.only(left: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image with offline fallback
                  Image.network(
                    offer['image'] as String,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 180,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
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
                  // Dark overlay
                  Container(color: Colors.black.withOpacity(0.6)),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          offer['title'] as String,
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          offer['subtitle'] as String,
                          style: GoogleFonts.cairo(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 15,
                    left: 15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Color(offer['color'] as int),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        offer['discount'] as String,
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Widget _buildRestaurantList() {
    if (isLoadingData) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (restaurantsList.isEmpty) {
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
      itemCount: restaurantsList.length,
      itemBuilder: (context, index) {
        final restaurant = restaurantsList[index];
        final double parsedRating =
            double.tryParse(restaurant['rating']?.toString() ?? '4.0') ?? 4.0;
        final double parsedDistance =
            double.tryParse(restaurant['distance']?.toString() ?? '2.5') ?? 2.5;

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
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        restaurant["imageUrl"]?.toString() ??
                            'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=500&q=80',
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
                          color: starIndex < parsedRating.toInt()
                              ? Colors.amber
                              : Colors.white24,
                          size: 10,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant["name"]?.toString() ?? "اسم غير متوفر",
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        restaurant["description"]?.toString() ??
                            "وصف غير متوفر",
                        style: GoogleFonts.cairo(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Tags row mapper using the array loop logic mapped out explicitly to wrap strings explicitly
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: ((restaurant["tags"] as List?) ?? [])
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

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (restaurant["isOpen"] ?? true)
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
                    Consumer<FavoritesProvider>(
                      builder: (context, fav, _) {
                        final rId =
                            restaurant['id']?.toString() ??
                            restaurant['name']?.toString() ??
                            '';
                        final isFav = fav.isRestaurantFav(rId);
                        return GestureDetector(
                          onTap: () => fav.toggleRestaurant(
                            Map<String, dynamic>.from(restaurant),
                          ),
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
  }
}
