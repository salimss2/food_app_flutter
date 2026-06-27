import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/dio_client.dart';
import '../../../../core/api/endpoints.dart';
import '../../../../core/widgets/custom_background.dart';
import '../../../../models/restaurant_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────
const _kPrimaryBlue = Color(0xFF0F55E8);
const _kOrange = Color(0xFFE69B35);
const _kDarkCard = Color(0xFF1E1A34);

// ─────────────────────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────────────────────
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  // ── State ─────────────────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchingMeals = true;
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  String _errorMessage = '';
  Timer? _debounce;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ── API ───────────────────────────────────────────────────────────────────
  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = '';
        _isLoading = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 600), () => _doSearch(query));
  }

  Future<void> _doSearch(String query) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await DioClient().dio.get(
        Endpoints.search,
        queryParameters: {
          'query': query.trim(),
          'type': _isSearchingMeals ? 'meals' : 'restaurants',
        },
      );

      if (!mounted) return;

      final data = response.data;
      List<dynamic> results = [];

      if (data is Map && data.containsKey('data')) {
        results = data['data'] as List<dynamic>? ?? [];
      } else if (data is List) {
        results = data;
      }

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'حدث خطأ أثناء البحث. تحقق من الاتصال.';
      });
    }
  }

  void _switchTab(bool toMeals) {
    if (_isSearchingMeals == toMeals) return;
    setState(() {
      _isSearchingMeals = toMeals;
      _searchResults = [];
      _errorMessage = '';
    });
    final q = _searchController.text.trim();
    if (q.isNotEmpty) _doSearch(q);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomBackground(
          child: SafeArea(
            child: Column(
              children: [
                _buildSearchHeader(isDark),
                const SizedBox(height: 8),
                _buildToggleBar(isDark),
                const SizedBox(height: 12),
                Expanded(child: _buildBody(isDark)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 1. Search Header
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSearchHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      child: Row(
        children: [
          // Back button
          _GlassIconButton(
            isDark: isDark,
            icon: Icons.arrow_forward_ios_rounded,
            onTap: () => context.pop(),
          ),
          const SizedBox(width: 10),
          // Search field
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: isDark
                    ? _kDarkCard.withOpacity(0.60)
                    : Colors.white.withOpacity(0.65),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.10)
                      : Colors.black.withOpacity(0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                onSubmitted: (v) {
                  _debounce?.cancel();
                  if (v.trim().isNotEmpty) _doSearch(v);
                },
                textDirection: TextDirection.rtl,
                style: GoogleFonts.cairo(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'ابحث عن وجبة أو مطعم…',
                  hintStyle: GoogleFonts.cairo(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: isDark ? Colors.white38 : Colors.black38,
                    size: 22,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: isDark ? Colors.white54 : Colors.black45,
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults = [];
                              _errorMessage = '';
                            });
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. Toggle Bar (Meals / Restaurants)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildToggleBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: isDark
              ? _kDarkCard.withOpacity(0.50)
              : Colors.white.withOpacity(0.50),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.07),
          ),
        ),
        child: Row(
          children: [
            _ToggleButton(
              label: 'الوجبات',
              isActive: _isSearchingMeals,
              isDark: isDark,
              onTap: () => _switchTab(true),
              icon: Icons.restaurant_menu_rounded,
            ),
            _ToggleButton(
              label: 'المطاعم',
              isActive: !_isSearchingMeals,
              isDark: isDark,
              onTap: () => _switchTab(false),
              icon: Icons.store_rounded,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. Body (loading / error / results / empty)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _kPrimaryBlue),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return _buildEmptyState(
        isDark: isDark,
        icon: Icons.wifi_off_rounded,
        title: 'خطأ في الاتصال',
        subtitle: _errorMessage,
        iconColor: Colors.redAccent,
      );
    }

    if (_searchController.text.trim().isEmpty) {
      return _buildEmptyState(
        isDark: isDark,
        icon: Icons.search_rounded,
        title: 'ابدأ بالبحث',
        subtitle: _isSearchingMeals
            ? 'اكتب اسم الوجبة التي تبحث عنها'
            : 'اكتب اسم المطعم الذي تبحث عنه',
        iconColor: _kPrimaryBlue.withOpacity(0.7),
      );
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState(
        isDark: isDark,
        icon: Icons.search_off_rounded,
        title: 'لا توجد نتائج',
        subtitle: 'لم يتم العثور على نتائج لـ "${_searchController.text}"',
        iconColor: _kOrange.withOpacity(0.8),
      );
    }

    return _isSearchingMeals
        ? _buildMealsResults(isDark)
        : _buildRestaurantsResults(isDark);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4-A. Meals Results — grouped by restaurant
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMealsResults(bool isDark) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final group = _searchResults[index] as Map<String, dynamic>;
        final restaurant = group['restaurant'] as Map<String, dynamic>? ?? {};
        final products = group['products'] as List<dynamic>? ?? [];
        return _buildMealGroup(isDark, restaurant, products);
      },
    );
  }

  Widget _buildMealGroup(
    bool isDark,
    Map<String, dynamic> restaurant,
    List<dynamic> products,
  ) {
    final name = restaurant['name']?.toString() ?? 'مطعم';
    final logo = restaurant['logo']?.toString() ?? restaurant['image']?.toString();
    final restaurantId = restaurant['id']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: isDark
            ? _kDarkCard.withOpacity(0.45)
            : Colors.white.withOpacity(0.60),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.07)
              : Colors.black.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Restaurant Header ──────────────────────────────────────────
          GestureDetector(
            onTap: () => context.push('/restaurant-detail', extra: restaurant),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                children: [
                  // Logo
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: _kDarkCard,
                      border: Border.all(
                        color: _kPrimaryBlue.withOpacity(0.3),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: logo != null
                          ? Image.network(
                              logo,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.store_rounded,
                                color: Colors.white54,
                                size: 22,
                              ),
                            )
                          : const Icon(
                              Icons.store_rounded,
                              color: Colors.white54,
                              size: 22,
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Name
                  Expanded(
                    child: Text(
                      name,
                      style: GoogleFonts.cairo(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Arrow
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 14,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ],
              ),
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Divider(
              height: 1,
              color: isDark
                  ? Colors.white.withOpacity(0.07)
                  : Colors.black.withOpacity(0.06),
            ),
          ),

          const SizedBox(height: 10),

          // ── Horizontal Products List ───────────────────────────────────
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: products.length,
              itemBuilder: (context, i) {
                final product = products[i] as Map<String, dynamic>;
                return _buildProductCard(isDark, product, restaurant);
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    bool isDark,
    Map<String, dynamic> product,
    Map<String, dynamic> restaurant,
  ) {
    final name = product['name']?.toString() ?? '';
    final price = product['price']?.toString() ?? '0';
    final image = product['image_url']?.toString() ??
        product['image']?.toString() ??
        product['imageUrl']?.toString();

    return GestureDetector(
      onTap: () => context.push('/meal-detail', extra: {
        'meal': product,
        'restaurant': restaurant,
      }),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(left: 10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withOpacity(0.30)
              : Colors.white.withOpacity(0.70),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : Colors.black.withOpacity(0.06),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: image != null
                  ? Image.network(
                      image,
                      width: double.infinity,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _productImagePlaceholder(),
                    )
                  : _productImagePlaceholder(),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.cairo(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _kOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _kOrange.withOpacity(0.4),
                        ),
                      ),
                      child: Text(
                        '$price ر.ي',
                        style: GoogleFonts.cairo(
                          color: _kOrange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
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
  }

  Widget _productImagePlaceholder() => Container(
        width: double.infinity,
        height: 80,
        color: _kDarkCard,
        child: const Icon(
          Icons.fastfood_rounded,
          color: Colors.white24,
          size: 28,
        ),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // 4-B. Restaurants Results — vertical list
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildRestaurantsResults(bool isDark) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final r = _searchResults[index] as Map<String, dynamic>;
        return _buildRestaurantCard(isDark, r);
      },
    );
  }

  Widget _buildRestaurantCard(bool isDark, Map<String, dynamic> r) {
    final name = r['name']?.toString() ?? 'مطعم';
    final address = r['address']?.toString() ?? '';
    final logo = r['logo']?.toString() ?? r['image']?.toString();
    final rating = double.tryParse(r['rating']?.toString() ?? '0') ?? 0.0;
    final isOpen = r['is_open'] == true ||
        r['is_open'] == 1 ||
        r['status']?.toString().toLowerCase() == 'open';
    final tags = (r['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

    return GestureDetector(
      onTap: () => context.push('/restaurant-detail', extra: r),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? _kDarkCard.withOpacity(0.50)
              : Colors.white.withOpacity(0.65),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : Colors.black.withOpacity(0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Logo
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: _kDarkCard,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: logo != null
                    ? Image.network(
                        logo,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.store_rounded,
                          color: Colors.white38,
                          size: 28,
                        ),
                      )
                    : const Icon(
                        Icons.store_rounded,
                        color: Colors.white38,
                        size: 28,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Details
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
                  if (address.isNotEmpty)
                    Text(
                      address,
                      style: GoogleFonts.cairo(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 6),
                  // Stars
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: i < rating.round() ? Colors.amber : Colors.white24,
                      ),
                    ),
                  ),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 5,
                      children: tags
                          .take(3)
                          .map(
                            (t) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.black.withOpacity(0.3)
                                    : Colors.black.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                t,
                                style: GoogleFonts.cairo(
                                  color: isDark ? Colors.white60 : Colors.black54,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            // Open badge
            if (isOpen)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kOrange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kOrange.withOpacity(0.4)),
                ),
                child: Text(
                  'مفتوح',
                  style: GoogleFonts.cairo(
                    color: _kOrange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5. Empty / Info State
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildEmptyState({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withOpacity(0.10),
                border: Border.all(color: iconColor.withOpacity(0.25), width: 1.5),
              ),
              child: Icon(icon, size: 40, color: iconColor),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.cairo(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                color: isDark ? Colors.white54 : Colors.black45,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────────────────────────────────────
class _ToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isActive
                ? _kPrimaryBlue
                : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: _kPrimaryBlue.withOpacity(0.40),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isActive
                      ? Colors.white
                      : (isDark ? Colors.white54 : Colors.black45),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    color: isActive
                        ? Colors.white
                        : (isDark ? Colors.white54 : Colors.black54),
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({
    required this.isDark,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark
              ? _kDarkCard.withOpacity(0.55)
              : Colors.white.withOpacity(0.65),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.10)
                : Colors.black.withOpacity(0.08),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}
