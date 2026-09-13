import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
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
import '../../../../models/offer_model.dart';
import '../../../../providers/cart_provider.dart';
import '../../../../providers/restaurant_provider.dart';
import '../../../../models/restaurant_model.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/api/endpoints.dart';
import '../widgets/home_drawer.dart';
import '../../../../core/widgets/modern_settings_sheet.dart';
import '../../../../core/widgets/shared_bottom_nav_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/utils/image_url_helper.dart';

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
    _fetchCategories();
    // Check if location is already set before showing the dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowLocationDialog();
      context.read<OffersProvider>().fetchBanners();
    });
  }

  @override
  void dispose() {
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
                  child: const SharedBottomNavBar(selectedIndex: 0),
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

  void _showComboOfferDetailsSheet(BuildContext context, OfferModel offer) {
    final String? imageUrl = offer.bannerImage;
    final String title = offer.title.isNotEmpty ? offer.title : 'عرض مميز';
    final String description = offer.description ?? '';
    final double? offerPrice = offer.offerPrice;
    final double? originalPrice = offer.originalPrice;
    final double? discountPercentage = offer.discountPercentage;
    final double effectivePrice = offerPrice ?? originalPrice ?? 0.0;

    final String clickAction = offer.clickAction.toLowerCase();
    final String type = offer.type.toLowerCase();
    final bool isDirectCart = (clickAction == 'cart' ||
        clickAction == 'direct_cart' ||
        type == 'direct_cart');
    final bool isCoupon = (clickAction == 'coupon');
    final bool isRestaurant = !isDirectCart && !isCoupon;

    // Safely extract restaurant ID
    final int? resId = offer.restaurantId ??
        (offer.restaurant != null
            ? int.tryParse(offer.restaurant!['id']?.toString() ?? '')
            : null) ??
        (offer.meal != null
            ? int.tryParse(offer.meal!['restaurant_id']?.toString() ?? '')
            : null);

    int? discountPercent;
    if (discountPercentage != null && discountPercentage > 0) {
      discountPercent = discountPercentage.round();
    } else if (originalPrice != null &&
        originalPrice > 0 &&
        offerPrice != null &&
        offerPrice < originalPrice) {
      discountPercent =
          (((originalPrice - offerPrice) / originalPrice) * 100).round();
    }

    bool isAdding = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1A34).withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
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
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 45,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Restaurant Badge (if present)
                    if (offer.restaurant != null) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 11,
                              backgroundColor: Colors.white12,
                              backgroundImage:
                                  offer.restaurant!['image_url'] != null
                                      ? CachedNetworkImageProvider(
                                          ImageUrlHelper.normalize(
                                            offer.restaurant!['image_url']
                                                .toString(),
                                          ),
                                        )
                                      : null,
                              child: offer.restaurant!['image_url'] == null
                                  ? const Icon(
                                      Icons.storefront,
                                      size: 13,
                                      color: Colors.white70,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              offer.restaurant!['name']?.toString() ?? '',
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Header Image
                    if (imageUrl != null && imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: CachedNetworkImage(
                          imageUrl: ImageUrlHelper.normalize(imageUrl),
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: const Color(0xFF2A2547),
                            width: double.infinity,
                            height: 200,
                            child: const Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFED922A),
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFF2A2547),
                            width: double.infinity,
                            height: 200,
                            child: const Center(
                              child: Icon(
                                Icons.fastfood,
                                color: Colors.grey,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Description
                    if (description.isNotEmpty) ...[
                      Text(
                        description,
                        style: GoogleFonts.cairo(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Price Row (Hidden if restaurant action and price is null/0)
                    if (effectivePrice > 0) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '${effectivePrice.toStringAsFixed(0)} ر.ي',
                            style: GoogleFonts.cairo(
                              color: const Color(0xFFED922A),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (originalPrice != null &&
                              offerPrice != null &&
                              originalPrice > offerPrice) ...[
                            Text(
                              '${originalPrice.toStringAsFixed(0)} ر.ي',
                              style: GoogleFonts.cairo(
                                color: Colors.white38,
                                fontSize: 16,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          if (discountPercent != null && discountPercent > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFED922A).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                      const Color(0xFFED922A).withOpacity(0.5),
                                ),
                              ),
                              child: Text(
                                '$discountPercent% خصم',
                                style: GoogleFonts.cairo(
                                  color: const Color(0xFFED922A),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ] else ...[
                      const SizedBox(height: 8),
                    ],

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFED922A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 4,
                          shadowColor: const Color(0xFFED922A).withOpacity(0.4),
                        ),
                        onPressed: isAdding
                            ? null
                            : () async {
                                if (isRestaurant) {
                                  Navigator.pop(sheetContext);
                                  if (resId != null && resId > 0) {
                                    final Map<String, dynamic> restaurantMap = {
                                      'id': resId,
                                      if (offer.restaurant != null)
                                        ...offer.restaurant!,
                                    };
                                    context.push(
                                      '/restaurant-detail',
                                      extra: restaurantMap,
                                    );
                                  } else {
                                    context.go('/restaurants');
                                  }
                                } else if (isCoupon) {
                                  final code = (offer.couponCode != null &&
                                          offer.couponCode!.isNotEmpty)
                                      ? offer.couponCode!
                                      : offer.title;
                                  Clipboard.setData(ClipboardData(text: code));
                                  Navigator.pop(sheetContext);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'تم نسخ كود الخصم ($code) بنجاح',
                                        style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      backgroundColor: const Color(0xFFED922A),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                } else {
                                  // Cart Action
                                  setSheetState(() => isAdding = true);
                                  try {
                                    final mealId = offer.mealId?.toString() ??
                                        offer.id.toString();
                                    final double targetPrice =
                                        (offer.offerPrice != null &&
                                                offer.offerPrice! > 0)
                                            ? offer.offerPrice!
                                            : (offer.originalPrice ??
                                                effectivePrice);

                                    final cartItem = CartItem(
                                      mealId: mealId,
                                      offerId: offer.id.toString(),
                                      name: offer.title.isNotEmpty
                                          ? offer.title
                                          : 'عرض خاص',
                                      price: targetPrice > 0
                                          ? targetPrice
                                          : effectivePrice,
                                      unitPrice: targetPrice > 0
                                          ? targetPrice
                                          : effectivePrice,
                                      originalPrice: offer.originalPrice,
                                      imageUrl: offer.bannerImage ?? '',
                                      quantity: 1,
                                      restaurantId: resId?.toString() ??
                                          offer.restaurantId?.toString() ??
                                          '',
                                      type: offer.mealId != null
                                          ? 'meal'
                                          : 'combo_offer',
                                    );

                                    await sheetContext
                                        .read<CartProvider>()
                                        .addItem(
                                          cartItem,
                                          restaurant: resId != null
                                              ? {
                                                  'id': resId,
                                                  if (offer.restaurant != null)
                                                    ...offer.restaurant!,
                                                }
                                              : null,
                                          priceOverride: targetPrice > 0
                                              ? targetPrice
                                              : null,
                                        );

                                    if (sheetContext.mounted) {
                                      Navigator.pop(sheetContext);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'تمت إضافة العرض إلى السلة بنجاح',
                                            style: GoogleFonts.cairo(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          backgroundColor: Colors.green,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (sheetContext.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            e.toString().replaceAll(
                                                'Exception: ', ''),
                                            style: GoogleFonts.cairo(
                                              color: Colors.white,
                                            ),
                                          ),
                                          backgroundColor: Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (sheetContext.mounted) {
                                      setSheetState(() => isAdding = false);
                                    }
                                  }
                                }
                              },
                        child: isAdding
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isRestaurant
                                        ? Icons.storefront_outlined
                                        : isCoupon
                                            ? Icons.copy_rounded
                                            : Icons.shopping_bag_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isRestaurant
                                        ? 'الذهاب للمطعم'
                                        : isCoupon
                                            ? 'نسخ كود الخصم'
                                            : 'إضافة للسلة',
                                    style: GoogleFonts.cairo(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
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

  void _handleBannerTap(BuildContext context, OfferModel offer) {
    _showComboOfferDetailsSheet(context, offer);
  }

  Widget _buildPromoBanner() {
    return Consumer<OffersProvider>(
      builder: (context, offersProvider, _) {
        // ── Loading state: shimmer skeleton ──────────────────────────────
        if (offersProvider.isLoading ||
            offersProvider.status == OffersStatus.initial) {
          return _buildOfferShimmer();
        }

        // ── Temporary Diagnostic: Error state ────────────────────────────
        if (offersProvider.hasError) {
          return Container(
            height: 100,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.redAccent),
            ),
            child: Center(
              child: Text(
                'API Error: ${offersProvider.errorMessage}\n(Check Console for 🛑 logs)',
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // ── Temporary Diagnostic: Empty state ────────────────────────────
        if (offersProvider.banners.isEmpty) {
          return Container(
            height: 100,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orangeAccent),
            ),
            child: const Center(
              child: Text(
                'No Active Banners Found (offers list is empty)\n(Check Console for 🛑 logs)',
                style: TextStyle(color: Colors.orangeAccent, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // ── Loaded: dynamic CarouselSlider with OfferModel ───────────────
        final banners = offersProvider.banners;
        return CarouselSlider(
          options: CarouselOptions(
            height: 180,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            enlargeCenterPage: true,
            viewportFraction: 0.93,
          ),
          items: banners.asMap().entries.map((entry) {
            final int index = entry.key;
            final OfferModel offer = entry.value;
            final accentColor = Color(
              _offerColors[index % _offerColors.length],
            );
            final String? imageUrl = offer.bannerImage;
            final String title = offer.title;
            final String description = offer.description ?? '';
            final double? offerPrice = offer.offerPrice;
            final double? originalPrice = offer.originalPrice;
            final double? discountPercentage = offer.discountPercentage;

            String discountBadge = '';
            if (discountPercentage != null && discountPercentage > 0) {
              discountBadge = '${discountPercentage.round()}% خصم';
            } else if (offerPrice != null && offerPrice > 0) {
              discountBadge = '${offerPrice.toStringAsFixed(0)} ر.ي';
            }

            return GestureDetector(
              onTap: () => _handleBannerTap(context, offer),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background image with CachedNetworkImage & Shimmer Fallback
                      imageUrl != null && imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: ImageUrlHelper.normalize(imageUrl),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 180,
                              placeholder: (context, url) => Shimmer.fromColors(
                                baseColor: const Color(0xFF1E1A34),
                                highlightColor: const Color(0xFF2A2640),
                                child: Container(
                                  color: const Color(0xFF2A2547),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: const Color(0xFF2A2547),
                                child: const Center(
                                  child: Icon(
                                    Icons.fastfood,
                                    color: Colors.grey,
                                    size: 36,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF2A2547), Color(0xFF1E1A34)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),

                      // Dark gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.8),
                              Colors.black.withOpacity(0.35),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),

                      // Text content
                      Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Restaurant Badge
                            if (offer.restaurant != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 9,
                                      backgroundColor: Colors.white12,
                                      backgroundImage:
                                          offer.restaurant!['image_url'] != null
                                              ? CachedNetworkImageProvider(
                                                  ImageUrlHelper.normalize(
                                                    offer.restaurant!['image_url'].toString(),
                                                  ),
                                                )
                                              : null,
                                      child: offer.restaurant!['image_url'] == null
                                          ? const Icon(
                                              Icons.storefront,
                                              size: 11,
                                              color: Colors.white70,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      offer.restaurant!['name']?.toString() ?? '',
                                      style: GoogleFonts.cairo(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            if (title.isNotEmpty)
                              Text(
                                title,
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (description.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                description,
                                style: GoogleFonts.cairo(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (originalPrice != null && offerPrice != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '${offerPrice.toStringAsFixed(0)} ر.ي',
                                    style: GoogleFonts.cairo(
                                      color: const Color(0xFFFF5555),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${originalPrice.toStringAsFixed(0)} ر.ي',
                                    style: GoogleFonts.cairo(
                                      color: Colors.white38,
                                      fontSize: 11,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Discount badge
                      if (discountBadge.isNotEmpty)
                        Positioned(
                          top: 14,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              discountBadge,
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 12,
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
          }).toList(),
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
        child: CarouselSlider.builder(
          options: CarouselOptions(
            height: 180,
            viewportFraction: 0.93,
            enlargeCenterPage: true,
          ),
          itemCount: 3,
          itemBuilder: (_, __, ___) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
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
                          child: CachedNetworkImage(
                            imageUrl: ImageUrlHelper.normalize(
                              restaurant.imageUrl ??
                                  'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=500&q=80',
                            ),
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) {
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
