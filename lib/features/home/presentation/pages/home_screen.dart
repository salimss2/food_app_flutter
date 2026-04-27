import 'dart:async'; // For auto scroll carousel interval
import 'dart:convert';
import 'dart:ui'; // <-- هام جداً لتأثير الزجاج
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart'; // <-- استيراد go_router
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Consumer, Provider;

import '../../../../core/widgets/global_exit_wrapper.dart';

import '../../../../core/widgets/custom_background.dart';
import '../../../../providers/favorites_provider.dart';
import '../../../../providers/favorites_provider.dart';
import '../../../../providers/restaurant_provider.dart';
import '../../../../models/restaurant_model.dart';
import '../widgets/home_drawer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  // الحالة لتتبع القسم المختار لفلترة المطاعم
  String _selectedCategoryFilter = "الكل";

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
    {"name": "الكل", "icon": Icons.grid_view_rounded},
    {"name": "الوجبات", "icon": Icons.restaurant_menu_rounded},
    {"name": "المطاعم", "icon": Icons.fastfood_rounded},
    {"name": "مشاريع منزلية", "icon": Icons.home_work_rounded},
    {"name": "دجاج", "icon": Icons.local_dining_rounded},
    {"name": "عسل", "icon": Icons.hive_rounded},
    {"name": "خضروات", "icon": Icons.apple_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                          color: isDark ? const Color(0xFF140C36).withOpacity(0.85) : Colors.white.withOpacity(0.9),
                          border: Border(
                            bottom: BorderSide(
                              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
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
        final isDark = Theme.of(context).brightness == Brightness.dark;
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
                  color: isDark ? const Color(0xFF1E1A34).withOpacity(0.85) : Colors.white.withOpacity(0.95),
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
                                  color: isDark ? Colors.white : Colors.black87,
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
                                  child: Icon(
                                    Icons.close,
                                    color: isDark ? Colors.white : Colors.black87,
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
                                    color: isDark ? Colors.white : Colors.black87,
                                    size: 35,
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);

                                    if (_categories[index]["name"] ==
                                        "الوجبات") {
                                      context.push('/meals-list');
                                    } else {
                                      setState(() {
                                        _selectedCategoryFilter =
                                            _categories[index]["name"]
                                                as String;
                                      });
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 110,
      child: Row(
        children: [
          _buildCategoryItem(
            title: "كل الاقسام",
            child: Icon(
              Icons.grid_view_rounded,
              color: isDark ? Colors.white.withOpacity(0.8) : Colors.black87,
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
                    color: isDark ? Colors.white : Colors.black87,
                    size: 35,
                  ),
                  onTap: () {
                    if (_categories[index]["name"] == "الوجبات") {
                      context.push('/meals-list');
                    } else {
                      setState(() {
                        _selectedCategoryFilter =
                            _categories[index]["name"] as String;
                      });
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                color: isDark ? const Color(0xFF1E1A34).withOpacity(0.60) : Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
              ),
              child: child,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.cairo(
                color: _selectedCategoryFilter == title
                    ? const Color(0xFF0F55E8)
                    : (isDark ? Colors.white : Colors.black87),
                fontSize: 13,
                fontWeight: _selectedCategoryFilter == title
                    ? FontWeight.bold
                    : FontWeight.normal,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.cairo(
            color: isDark ? Colors.white : Colors.black87,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: Container(
        height: 75,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: isDark ? const Color.fromARGB(255, 54, 37, 124).withOpacity(0.8) : Colors.black.withOpacity(0.1),
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
                color: isDark ? const Color(0xFF1E1A34).withOpacity(0.85) : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(35),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.1),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              Icon(unselectedIcon, color: isDark ? Colors.white54 : Colors.black54, size: 26),

            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.cairo(
                color: isSelected ? const Color(0xFF0F55E8) : (isDark ? Colors.white54 : Colors.black54),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        PopupMenuButton<String>(
          offset: const Offset(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          color: isDark ? const Color(0xFF1E1A34) : Colors.white,
          icon: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.1)),
            ),
            child: Icon(
              Icons.settings_outlined,
              color: isDark ? Colors.white : Colors.black87,
              size: 20,
            ),
          ),
          onSelected: (value) {
            if (value == 'logout') {
              // هنا يتم استدعاء دالة تسجيل الخروج من المزود الخاص بك
              // context.read<AuthProvider>().logout();
              // context.go('/login');
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'تسجيل الخروج',
                    style: GoogleFonts.cairo(
                      color: Colors.redAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.logout_rounded,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ),
        Column(
          children: [
            Text(
              "التوصيل الآن",
              style: GoogleFonts.cairo(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12),
            ),
            Row(
              children: [
                Text(
                  "Maplewood Suites",
                  style: GoogleFonts.cairo(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: isDark ? Colors.white : Colors.black87,
                  size: 16,
                ),
              ],
            ),
          ],
        ),
        IconButton(
          icon: Icon(Icons.menu, color: isDark ? Colors.white : Colors.black87),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        context.push('/search');
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1A34).withOpacity(0.60) : Colors.white.withOpacity(0.60),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
        ),
        child: IgnorePointer(
          child: TextField(
            style: GoogleFonts.cairo(color: isDark ? Colors.white : Colors.black87),
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: "عن ماذا تبحث؟",
              hintStyle: GoogleFonts.cairo(color: isDark ? Colors.white54 : Colors.black54),
              prefixIcon: Icon(Icons.search, color: isDark ? Colors.white54 : Colors.black54),
              suffixIcon: Icon(
                Icons.qr_code_scanner,
                color: isDark ? Colors.white54 : Colors.black54,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final restaurantsAsyncValue = ref.watch(restaurantProvider);

    return restaurantsAsyncValue.when(
      data: (allRestaurants) {
        final displayedRestaurants = _selectedCategoryFilter == "الكل"
            ? allRestaurants
            : allRestaurants.where((r) {
                return r.tags.any(
                  (tag) => tag.contains(_selectedCategoryFilter),
                );
              }).toList();

        if (displayedRestaurants.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                "لا توجد مطاعم مطابقة لهذا القسم",
                style: GoogleFonts.cairo(color: isDark ? Colors.white : Colors.black87, fontSize: 16),
              ),
            ),
          );
        }

        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: displayedRestaurants.length,
          itemBuilder: (context, index) {
            final Restaurant restaurant = displayedRestaurants[index];
            final double parsedRating = restaurant.rating;
            final double parsedDistance =
                double.tryParse(
                  restaurant.distance.replaceAll(RegExp(r'[^0-9.]'), ''),
                ) ??
                2.5;

            // Simple map for fav usage
            final Map<String, dynamic> restaurantMap = {
              "id": restaurant.id,
              "name": restaurant.name,
              "address": restaurant.address,
              "distance": restaurant.distance,
              "rating": restaurant.rating,
              "isOpen": restaurant.isOpen,
              "imageUrl": restaurant.imageUrl,
              "tags": restaurant.tags,
              "menus": restaurant.menus
                  .map(
                    (menu) => {
                      "id": menu.id,
                      "name": menu.name,
                      "meals": menu.meals
                          .map(
                            (meal) => {
                              "id": meal.id,
                              "name": meal.name,
                              "description": meal.description,
                              "price": meal.price,
                              "imageUrl": meal.imageUrl,
                            },
                          )
                          .toList(),
                    },
                  )
                  .toList(),
              "meals": restaurant.meals
                  .map(
                    (meal) => {
                      "id": meal.id,
                      "name": meal.name,
                      "description": meal.description,
                      "price": meal.price,
                      "imageUrl": meal.imageUrl,
                    },
                  )
                  .toList(),
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
                    Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            restaurant.imageUrl ??
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
                            color: isDark ? Colors.white70 : Colors.black87,
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
                            restaurant.name.isNotEmpty
                                ? restaurant.name
                                : "اسم غير متوفر",
                            style: GoogleFonts.cairo(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "مطعم ${restaurant.name}",
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
                            children: restaurant.tags
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

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (restaurant.isOpen)
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
                            final rId = restaurant.id.isNotEmpty
                                ? restaurant.id
                                : restaurant.name;
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
            "حدث خطأ أثناء تحميل المطاعم",
            style: GoogleFonts.cairo(color: isDark ? Colors.white : Colors.black87),
          ),
        ),
      ),
    );
  }
}
