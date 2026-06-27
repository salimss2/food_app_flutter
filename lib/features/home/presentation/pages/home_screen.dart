import 'dart:async'; // For auto scroll carousel interval
import 'dart:convert';
import 'dart:ui'; // <-- هام جداً لتأثير الزجاج
import 'package:customer_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart'; // <-- استيراد go_router
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Consumer, Provider;
import 'package:shimmer/shimmer.dart';
import 'package:customer_app/features/startup/presentation/pages/location_access_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/widgets/global_exit_wrapper.dart';

import '../../../../core/widgets/custom_background.dart';
import '../../../../providers/favorites_provider.dart';
import '../../../../providers/offers_provider.dart';
import '../../../../providers/cart_provider.dart';
import '../../../../providers/restaurant_provider.dart';
import '../../../../models/restaurant_model.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/api/endpoints.dart';
import '../widgets/home_drawer.dart';
import '../../../../core/widgets/modern_settings_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  // الحالة لتتبع القسم المختار لفلترة المطاعم
  String _selectedCategoryFilter = "";

  final PageController _pageController = PageController(viewportFraction: 0.93);
  Timer? _timer;
  int _currentPage = 0;

  String? _currentAddress;

  Future<void> _loadSavedAddress() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _currentAddress = prefs.getString('saved_location');
      });
    }
  }

  // Fallback palette for offers that don't carry a color
  static const List<int> _offerColors = [
    0xFFD32F2F,
    0xFFE58B29,
    0xFF0F55E8,
    0xFF7B2FBE,
    0xFF1B8F4A,
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedAddress();
    _startAutoScroll();
    _fetchCategories();
    // Check if location is already set before showing the dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowLocationDialog();
    });
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (!mounted) return;
      // Read offer count safely without rebuilding; default to 3 for skeleton phase
      final offerCount = context.read<OffersProvider>().offers.length;
      final maxPage = offerCount > 0 ? offerCount : 3;
      if (_currentPage < maxPage - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
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
  // التحقق وعرض نافذة الوصول للموقع
  // ===========================================================================
  Future<void> _checkAndShowLocationDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSetLocation = prefs.getBool('has_set_location') ?? false;

    if (!hasSetLocation && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const LocationAccessDialog(),
      );
    }
  }

  // ===========================================================================
  // قائمة الأقسام (تم التعديل هنا لاستخدام الأيقونات بدلاً من الصور)
  // ===========================================================================
  List<dynamic> _categories = [];
  bool _isLoadingCategories = true;
  String? _categoriesError;

  Future<void> _fetchCategories() async {
    try {
      final response = await DioClient().dio.get(Endpoints.categories);
      if (response.statusCode == 200 && response.data['data'] != null) {
        if (mounted) {
          setState(() {
            _categories = response.data['data'];
            _isLoadingCategories = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _categoriesError = "Failed to load categories";
            _isLoadingCategories = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _categoriesError = "Error loading categories";
          _isLoadingCategories = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlobalExitWrapper(
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const HomeDrawer(),
        body: Directionality(
          textDirection: context.locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
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
                            SizedBox(height: 20),
                            _buildSectionTitle(
                              "categories".tr(),
                              showSeeAll: false,
                            ),
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
                              "all_restaurants".tr(),
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
                          color: isDark
                              ? const Color(0xFF140C36).withOpacity(0.85)
                              : Colors.white.withOpacity(0.9),
                          border: Border(
                            bottom: BorderSide(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.black.withOpacity(0.05),
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
          textDirection: context.locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E1A34).withOpacity(0.85)
                      : Colors.white.withOpacity(0.95),
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
                                "all_categories".tr(),
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
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
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
                                final category = _categories[index];
                                return _buildCategoryItem(
                                  title: category["name"] ?? '',
                                  categoryKey: category["name"] ?? '',
                                  // التعديل هنا لعرض الأيقونة أو الصورة
                                  child: category["image"] != null
                                      ? Image.network(
                                          category["image"],
                                          width: 35,
                                          height: 35,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) => Icon(
                                            Icons.fastfood_rounded,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                            size: 35,
                                          ),
                                        )
                                      : Icon(
                                          Icons.fastfood_rounded,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                          size: 35,
                                        ),
                                  onTap: () {
                                    Navigator.pop(context);

                                    if (category["name"] == "meals") {
                                      context.push('/meals-list');
                                    } else {
                                      setState(() {
                                        if (_selectedCategoryFilter ==
                                            category["name"]) {
                                          _selectedCategoryFilter = "";
                                        } else {
                                          _selectedCategoryFilter =
                                              category["name"] as String;
                                        }
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

    if (_isLoadingCategories) {
      return const SizedBox(
        height: 110,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_categoriesError != null) {
      return SizedBox(
        height: 110,
        child: Center(
          child: Text(
            _categoriesError!,
            style: GoogleFonts.cairo(color: Colors.red),
          ),
        ),
      );
    }

    if (_categories.isEmpty) {
      return SizedBox(
        height: 110,
        child: Center(
          child: Text(
            "no_categories".tr(),
            style: GoogleFonts.cairo(
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 110,
      child: Row(
        children: [
          _buildCategoryItem(
            title: "all_categories".tr(),
            categoryKey: "all",
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
                final category = _categories[index];
                return _buildCategoryItem(
                  title: category["name"] ?? '',
                  categoryKey: category["name"] ?? '',
                  // التعديل هنا لعرض الأيقونة أو الصورة
                  child: category["image"] != null
                      ? Image.network(
                          category["image"],
                          width: 35,
                          height: 35,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Icon(
                            Icons.fastfood_rounded,
                            color: isDark ? Colors.white : Colors.black87,
                            size: 35,
                          ),
                        )
                      : Icon(
                          Icons.fastfood_rounded,
                          color: isDark ? Colors.white : Colors.black87,
                          size: 35,
                        ),
                  onTap: () {
                    if (category["name"] == "meals") {
                      context.push('/meals-list');
                    } else {
                      setState(() {
                        if (_selectedCategoryFilter == category["name"]) {
                          _selectedCategoryFilter = "";
                        } else {
                          _selectedCategoryFilter = category["name"] as String;
                        }
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
    required String categoryKey,
    required Widget child,
    required VoidCallback onTap,
    bool isGrid = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedCategoryFilter == categoryKey;
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
                color: isDark
                    ? const Color(0xFF1E1A34).withOpacity(0.60)
                    : Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                ),
              ),
              child: child,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.cairo(
                color: isSelected
                    ? const Color(0xFF0F55E8)
                    : (isDark ? Colors.white : Colors.black87),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                "all".tr(),
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
              color: isDark
                  ? const Color.fromARGB(255, 54, 37, 124).withOpacity(0.8)
                  : Colors.black.withOpacity(0.1),
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
                color: isDark
                    ? const Color(0xFF1E1A34).withOpacity(0.85)
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(35),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.7)
                      : Colors.black.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _navItem(
                    selectedIcon: Icons.manage_search,
                    unselectedIcon: Icons.restaurant,
                    label: "restaurants".tr(),
                    index: 1,
                  ),
                  _navItem(
                    selectedIcon: Icons.shopping_cart,
                    unselectedIcon: Icons.shopping_cart_outlined,
                    label: "cart".tr(),
                    index: 2,
                  ),
                  _navItem(
                    selectedIcon: Icons.home,
                    unselectedIcon: Icons.home_outlined,
                    label: "home".tr(),
                    index: 0,
                  ),
                  _navItem(
                    selectedIcon: Icons.receipt,
                    unselectedIcon: Icons.receipt_outlined,
                    label: "my_orders".tr(),
                    index: 3,
                  ),
                  _navItem(
                    selectedIcon: Icons.person,
                    unselectedIcon: Icons.person_outline,
                    label: "my_account".tr(),
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

    // 🌟 إضافة Expanded هنا لتوزيع المساحة الأفقية بالتساوي على الأزرار الـ 5
    return Expanded(
      child: GestureDetector(
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
          // تقليل الـ horizontal padding قليلاً لإعطاء مساحة أكبر للنص
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
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
                Icon(
                  unselectedIcon,
                  color: isDark ? Colors.white54 : Colors.black54,
                  size: 26,
                ),

              const SizedBox(height: 4),

              // 🌟 استخدام FittedBox لوحدها بدون Flexible لكي يعمل التصغير بشكل سليم
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: GoogleFonts.cairo(
                    color: isSelected
                        ? const Color(0xFF0F55E8)
                        : (isDark ? Colors.white54 : Colors.black54),
                    fontSize: 11,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // بقية الودجت
  // ===========================================================================
  // ===========================================================================
  // بقية الودجت
  // ===========================================================================
  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // ── Settings icon → opens modern bottom sheet ──
        GestureDetector(
          onTap: () => showModernSettingsSheet(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.1),
              ),
            ),
            child: Icon(
              Icons.settings_outlined,
              color: isDark ? Colors.white : Colors.black87,
              size: 20,
            ),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                "delivery_now".tr(),
                style: GoogleFonts.cairo(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 12,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        String? address;
                        if (state is Authenticated) {
                          address = state.user.location;
                        }
                        address ??= _currentAddress;
                        return Text(
                          (address != null && address.isNotEmpty)
                              ? address
                              : "current_address_placeholder".tr(),
                          style: GoogleFonts.cairo(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
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
          color: isDark
              ? const Color(0xFF1E1A34).withOpacity(0.60)
              : Colors.white.withOpacity(0.60),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
          ),
        ),
        child: IgnorePointer(
          child: TextField(
            style: GoogleFonts.cairo(
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: "what_are_you_looking_for".tr(),
              hintStyle: GoogleFonts.cairo(
                color: isDark ? Colors.white54 : Colors.black54,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
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

  void _showComboOfferDetails(BuildContext context, Map<String, dynamic> offer) {
    final offerId = offer['id']?.toString() ?? '';
    final title = offer['title']?.toString() ?? 'Combo Offer';
    final description = offer['description']?.toString() ?? '';
    final comboPriceStr = offer['combo_price']?.toString() ?? '0';
    final double comboPrice = double.tryParse(comboPriceStr) ?? 0.0;
    final imageUrl = offer['image_url']?.toString() ?? offer['image']?.toString() ?? '';
    
    // Validity dates
    final startDateStr = offer['start_date']?.toString() ?? '';
    final endDateStr = offer['end_date']?.toString() ?? '';
    
    // Parse list of meals
    List<dynamic> mealsList = [];
    final rawMeals = offer['meals'] ?? offer['included_meals'];
    if (rawMeals is List) {
      mealsList = rawMeals;
    } else if (rawMeals is String && rawMeals.isNotEmpty) {
      try {
        final parsed = jsonDecode(rawMeals);
        if (parsed is List) {
          mealsList = parsed;
        }
      } catch (_) {}
    }
    
    final bool isAr = context.locale.languageCode == 'ar';
    
    String validityText = '';
    if (startDateStr.isNotEmpty && endDateStr.isNotEmpty) {
      try {
        final start = DateTime.parse(startDateStr);
        final end = DateTime.parse(endDateStr);
        final formatter = DateFormat('yyyy/MM/dd', context.locale.languageCode);
        validityText = isAr 
            ? 'صالح من ${formatter.format(start)} إلى ${formatter.format(end)}'
            : 'Valid from ${formatter.format(start)} to ${formatter.format(end)}';
      } catch (_) {
        validityText = isAr ? 'صالح لفترة محدودة' : 'Valid for a limited time';
      }
    } else {
      validityText = isAr ? 'صالح لفترة محدودة' : 'Valid for a limited time';
    }

    int selectedQty = 1;
    bool isAdding = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1A34),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              padding: EdgeInsets.only(
                top: 15,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 25,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handlebar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Restaurant identity
                    if (offer['restaurant'] != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.white12,
                              backgroundImage: offer['restaurant']['image_url'] != null ? NetworkImage(offer['restaurant']['image_url'].toString()) : null,
                              child: offer['restaurant']['image_url'] == null ? const Icon(Icons.storefront, size: 14, color: Colors.white70) : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              offer['restaurant']['name']?.toString() ?? '',
                              style: GoogleFonts.cairo(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),

                    // Image banner
                    if (imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            Image.network(
                              imageUrl,
                              width: double.infinity,
                              height: 160,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFF2A2547),
                                width: double.infinity,
                                height: 160,
                                child: const Center(
                                  child: Icon(Icons.broken_image, color: Colors.grey, size: 50),
                                ),
                              ),
                            ),
                            Container(
                              height: 160,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 15),

                    // Title and price row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE58B29),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${comboPrice.toInt()} ${"currency".tr()}',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Validity badge
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Color(0xFFE58B29), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          validityText,
                          style: GoogleFonts.cairo(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Description
                    if (description.isNotEmpty) ...[
                      Text(
                        description,
                        style: GoogleFonts.cairo(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 15),
                    ],

                    // Included meals title
                    Text(
                      isAr ? 'الوجبات المشمولة:' : 'Included Meals:',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Meals list
                    if (mealsList.isEmpty)
                      Text(
                        isAr ? 'لا توجد وجبات مدرجة' : 'No included meals listed',
                        style: GoogleFonts.cairo(
                          color: Colors.white38,
                          fontSize: 13,
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: mealsList.length,
                        itemBuilder: (context, index) {
                          final meal = mealsList[index];
                          final actualMeal = meal['meal'] ?? meal;
                          final mealName = actualMeal['name']?.toString() ?? actualMeal['title']?.toString() ?? '';
                          final mealImage = actualMeal['image_url']?.toString() ?? actualMeal['image']?.toString() ?? '';
                          
                          final pivot = meal['pivot'];
                          final String mealQty = (pivot != null 
                              ? (pivot['quantity'] ?? pivot['qty'] ?? pivot['meal_quantity'])?.toString() 
                              : null) ?? meal['quantity']?.toString() ?? meal['qty']?.toString() ?? '1';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2640).withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: Row(
                              children: [
                                if (mealImage.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      mealImage,
                                      width: 45,
                                      height: 45,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Colors.white.withOpacity(0.05),
                                        width: 45,
                                        height: 45,
                                        child: const Icon(Icons.fastfood, color: Colors.grey, size: 20),
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    width: 45,
                                    height: 45,
                                    child: const Icon(Icons.fastfood, color: Colors.grey, size: 20),
                                  ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    mealName,
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'x$mealQty',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFFE58B29),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 20),

                    // Actions section
                    Row(
                      children: [
                        // Quantity selector
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2640).withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, color: Colors.white),
                                onPressed: selectedQty > 1
                                    ? () => setSheetState(() => selectedQty--)
                                    : null,
                              ),
                              Text(
                                '$selectedQty',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, color: Colors.white),
                                onPressed: () => setSheetState(() => selectedQty++),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),

                        // Add to cart button
                        Expanded(
                          child: InkWell(
                            onTap: isAdding
                                ? null
                                : () async {
                                    final cartItem = CartItem(
                                      mealId: '',
                                      name: title,
                                      price: comboPrice,
                                      imageUrl: imageUrl,
                                      quantity: selectedQty,
                                      offerId: offerId,
                                      type: 'combo_offer',
                                      includedMeals: mealsList,
                                      restaurantId: offer['restaurant_id']?.toString() ?? offer['restaurant']?['id']?.toString() ?? '',
                                      restaurantName: offer['restaurant']?['name']?.toString() ?? '',
                                      restaurantAddress: offer['restaurant']?['address']?.toString() ?? '',
                                    );
                                    setSheetState(() => isAdding = true);
                                    try {
                                      final restaurant = offer['restaurant'] as Map<String, dynamic>?;
                                      await context.read<CartProvider>().addItem(cartItem, restaurant: restaurant);
                                      if (context.mounted) {
                                        Navigator.pop(sheetCtx);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              isAr ? 'تم إضافة العرض إلى السلة بنجاح' : 'Combo Offer added to cart successfully',
                                              style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
                                            ),
                                            backgroundColor: Colors.green.shade700,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        if (e.toString().contains('DIFFERENT_RESTAURANT')) {
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              backgroundColor: const Color(0xFF1E1E2C),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                              title: Text(isAr ? 'تنبيه' : 'Alert', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                                              content: Text(
                                                isAr 
                                                  ? 'لا يمكنك إضافة عناصر من مطاعم مختلفة. هل تريد تفريغ السلة؟' 
                                                  : 'You cannot add items from different restaurants. Do you want to clear your cart?',
                                                style: GoogleFonts.cairo(color: Colors.white70),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx),
                                                  child: Text(isAr ? 'إلغاء' : 'Cancel', style: GoogleFonts.cairo(color: Colors.grey)),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    Navigator.pop(ctx); // Close dialog
                                                    await context.read<CartProvider>().clearCart();
                                                    final restaurant = offer['restaurant'] as Map<String, dynamic>?;
                                                    await context.read<CartProvider>().addItem(cartItem, restaurant: restaurant);
                                                    if (context.mounted) {
                                                      Navigator.pop(sheetCtx); // Close the bottom sheet too
                                                    }
                                                  },
                                                  child: Text(isAr ? 'تفريغ وإضافة' : 'Clear & Add', style: GoogleFonts.cairo(color: const Color(0xFFD32F2F), fontWeight: FontWeight.bold)),
                                                ),
                                              ],
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                e.toString(),
                                                style: GoogleFonts.cairo(color: Colors.white),
                                              ),
                                              backgroundColor: Colors.red.shade700,
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      }
                                    } finally {
                                      setSheetState(() => isAdding = false);
                                    }
                                  },
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD32F2F),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFD32F2F).withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: isAdding
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        isAr ? 'إضافة العرض إلى السلة' : 'Add Offer to Cart',
                                        style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ),
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
    );
  }

  Widget _buildPromoBanner() {
    return Consumer<OffersProvider>(
      builder: (context, offersProvider, _) {
        // ── Loading state: shimmer skeleton ──────────────────────────────
        if (offersProvider.isLoading ||
            offersProvider.status == OffersStatus.initial) {
          return _buildOfferShimmer();
        }

        // ── Error or empty: show nothing gracefully ──────────────────────
        if (offersProvider.hasError || offersProvider.offers.isEmpty) {
          return const SizedBox.shrink();
        }

        // ── Loaded: dynamic PageView ─────────────────────────────────────
        final offers = offersProvider.offers;
        return SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (int index) {
              setState(() => _currentPage = index);
            },
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index] as Map<String, dynamic>;
              final accentColor = Color(
                _offerColors[index % _offerColors.length],
              );
              final imageUrl =
                  (offer['image_url'] as String?) ??
                  (offer['image'] as String?) ??
                  '';
              final title = (offer['title'] as String?) ?? '';
              final description =
                  (offer['description'] as String?) ??
                  (offer['subtitle'] as String?) ??
                  '';
              final comboPrice = (offer['combo_price']?.toString()) ?? '';
              final discount = comboPrice.isNotEmpty ? '$comboPrice ر.ي' : '';

              return GestureDetector(
                onTap: () => _showComboOfferDetails(context, offer),
                child: Container(
                  margin: const EdgeInsets.only(left: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background image
                        imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 180,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFF2A2547),
                                  child: const Center(
                                    child: Icon(
                                      Icons.wifi_off,
                                      color: Colors.grey,
                                      size: 30,
                                    ),
                                  ),
                                ),
                              )
                            : Container(color: const Color(0xFF2A2547)),

                        // Dark overlay
                        Container(color: Colors.black.withOpacity(0.6)),

                        // Text content
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Restaurant Badge
                              if (offer['restaurant'] != null)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        radius: 10,
                                        backgroundColor: Colors.white12,
                                        backgroundImage: offer['restaurant']['image_url'] != null ? NetworkImage(offer['restaurant']['image_url'].toString()) : null,
                                        child: offer['restaurant']['image_url'] == null ? const Icon(Icons.storefront, size: 12, color: Colors.white70) : null,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        offer['restaurant']['name']?.toString() ?? '',
                                        style: GoogleFonts.cairo(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              Text(
                                title,
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                description,
                                style: GoogleFonts.cairo(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Discount badge
                        if (discount.isNotEmpty)
                          Positioned(
                            top: 15,
                            left: 15,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                discount,
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
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildOfferShimmer() {
    return SizedBox(
      height: 180,
      child: Shimmer.fromColors(
        baseColor: const Color(0xFF1E1A34),
        highlightColor: const Color(0xFF2A2640),
        child: PageView.builder(
          controller: PageController(viewportFraction: 0.93),
          itemCount: 3,
          itemBuilder: (_, __) => Container(
            margin: const EdgeInsets.only(left: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final restaurantsAsyncValue = ref.watch(restaurantProvider);

    return restaurantsAsyncValue.when(
      data: (allRestaurants) {
        final displayedRestaurants =
            (_selectedCategoryFilter.isEmpty ||
                _selectedCategoryFilter == "all")
            ? allRestaurants
            : allRestaurants.where((r) {
                final searchVal = _selectedCategoryFilter
                    .toString()
                    .trim()
                    .toLowerCase();
                return r.tags.any(
                  (tag) =>
                      tag.toString().trim().toLowerCase().contains(searchVal),
                );
              }).toList();

        if (displayedRestaurants.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                "no_restaurants_found".tr(),
                style: GoogleFonts.cairo(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
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
                  color: isDark
                      ? const Color(0xFF1E1A34).withOpacity(0.5)
                      : Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.05),
                  ),
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
                          "${parsedDistance.toStringAsFixed(1)} ${"km".tr()}",
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  restaurant.name.isNotEmpty
                                      ? restaurant.name
                                      : "name_not_available".tr(),
                                  style: GoogleFonts.cairo(
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: restaurant.isOpen
                                      ? const Color(0xFFED922A).withOpacity(0.2)
                                      : Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: restaurant.isOpen
                                        ? const Color(0xFFED922A)
                                        : Colors.red,
                                  ),
                                ),
                                child: Text(
                                  restaurant.isOpen
                                      ? "open".tr()
                                      : "closed".tr(),
                                  style: GoogleFonts.cairo(
                                    color: restaurant.isOpen
                                        ? const Color(0xFFED922A)
                                        : Colors.red,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            "${"restaurant_label".tr()} ${restaurant.name}",
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
                                      color: isDark
                                          ? Colors.black.withOpacity(0.3)
                                          : Colors.black.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.1)
                                            : Colors.black.withOpacity(0.05),
                                      ),
                                    ),
                                    child: Text(
                                      tag,
                                      style: GoogleFonts.cairo(
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black87,
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
            "error_loading_restaurants".tr(),
            style: GoogleFonts.cairo(
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
