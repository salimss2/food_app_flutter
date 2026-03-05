import 'dart:ui'; // <-- هام جداً لتأثير الزجاج
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart'; // <-- استيراد go_router

import '../../../../core/widgets/custom_background.dart';
import '../widgets/home_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  // ===========================================================================
  // قائمة الأقسام 
  // ===========================================================================
  final List<Map<String, String>> _categories = [
    {"name": "وجبات", "image": "assets/images/burger.png"}, 
    {"name": "دجاج", "image": "assets/images/chicken.png"},
    {"name": "رز", "image": "assets/images/rice.png"}, 
    {"name": "المعجنات", "image": "assets/images/pizzaicon.png"}, 
    {"name": "ايسكريم", "image": "assets/images/icecream.png"}, 
    {"name": "عصائر", "image": "assets/images/juice.png"}, 
    {"name": "حلويات", "image": "assets/images/cake.png"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const HomeDrawer(),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomBackground(
          child: Stack(
            children: [
              // --- محتوى الصفحة القابل للتمرير ---
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 120),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        _buildHeader(),
                        const SizedBox(height: 20),
                        _buildSearchBar(),
                        const SizedBox(height: 25),
                        
                        // قسم الأقسام
                        _buildSectionTitle("الأقسام", showSeeAll: false),
                        const SizedBox(height: 15),
                        _buildCategoriesList(), 
                        const SizedBox(height: 25),
                        
                        // العروض
                        _buildPromoBanner(),
                        const SizedBox(height: 25),
                        
                        // قسم جميع المطاعم
                        _buildSectionTitle(
                          "جميع المطاعم", 
                          showSeeAll: true,
                          onSeeAllTap: () {
                            context.go('/restaurants');
                          }
                        ),
                        const SizedBox(height: 15),
                        _buildRestaurantList(),
                      ],
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
                  border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
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
                                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            child: GridView.builder(
                              physics: const BouncingScrollPhysics(),
                              shrinkWrap: true,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3, 
                                childAspectRatio: 0.8, 
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 15,
                              ),
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                return _buildCategoryItem(
                                  title: _categories[index]["name"]!,
                                  child: Image.asset(
                                    _categories[index]["image"]!,
                                    fit: BoxFit.contain,
                                  ),
                                  onTap: () {
                                    Navigator.pop(context); // إغلاق النافذة المنبثقة
                                    
                                    // --- التعديل هنا داخل النافذة المنبثقة أيضاً ---
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
                  title: _categories[index]["name"]!,
                  child: Image.asset(
                    _categories[index]["image"]!,
                    fit: BoxFit.contain,
                  ),
                  onTap: () {
                    // --- التعديل الأهم هنا لربط قسم الوجبات بالصفحة ---
                    if (_categories[index]["name"] == "وجبات") {
                      context.push('/meals-list');
                    }
                    // يمكنك لاحقاً إضافة else if لبقية الأقسام
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
  Widget _buildSectionTitle(String title, {bool showSeeAll = false, VoidCallback? onSeeAllTap}) {
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
            borderRadius: BorderRadius.circular(5),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Text(
                "الكل",
                style: GoogleFonts.cairo(
                  color: Colors.white54, 
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
                 border: Border.all(color: Colors.white.withOpacity(0.7), width: 1),
               ),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   _navItem(selectedIcon: Icons.manage_search, unselectedIcon: Icons.manage_search_outlined, label: "البحث", index: 1),
                   _navItem(selectedIcon: Icons.shopping_cart, unselectedIcon: Icons.shopping_cart_outlined, label: "السلة", index: 2),
                   _navItem(selectedIcon: Icons.home, unselectedIcon: Icons.home_outlined, label: "الرئيسية", index: 0),
                   _navItem(selectedIcon: Icons.receipt, unselectedIcon: Icons.receipt_outlined, label: "طلباتي", index: 3),
                   _navItem(selectedIcon: Icons.person, unselectedIcon: Icons.person_outline, label: "حسابي", index: 4),
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
                    colors: [Color(0xFF0F55E8), Color.fromARGB(255, 130, 87, 199)],
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
        IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
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
                const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
              ],
            ),
          ],
        ),
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
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A34).withOpacity(0.60),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        style: GoogleFonts.cairo(color: Colors.white),
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: "عن ماذا تبحث؟",
          hintStyle: GoogleFonts.cairo(color: Colors.white54),
          prefixIcon: const Icon(Icons.search, color: Colors.white54),
          suffixIcon: const Icon(Icons.qr_code_scanner, color: Colors.white54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildPromoBanner() {
    final promos = [
      {
        "title": "30% خصم",
        "desc": "اكتشف خصومات في مطاعمك المحلية المفضلة",
        "image": "assets/images/Pasta.png",
        "color1": const Color(0xFF140C36),
        "color2": const Color(0xFF3E1F75),
      },
      {
        "title": "توصيل مجاني",
        "desc": "احصل على توصيل مجاني لطلبك الأول",
        "image": "assets/images/burger.png",
        "color1": const Color(0xFF360C0C),
        "color2": const Color(0xFF751F1F),
      },
       {
        "title": "اشتر 1 واحصل على 1",
        "desc": "عرض خاص على جميع الحلويات اليوم",
        "image": "assets/images/cake.png",
        "color1": const Color(0xFF362D0C),
        "color2": const Color(0xFF755C1F),
      },
    ];

    return SizedBox(
      height: 170,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.9),
        itemCount: promos.length,
        itemBuilder: (context, index) {
          final promo = promos[index];
          return Container(
            margin: const EdgeInsets.only(left: 10),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [promo["color1"] as Color, promo["color2"] as Color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        promo["title"] as String,
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        promo["desc"] as String,
                        style: GoogleFonts.cairo(
                          color: Colors.white70,
                          fontSize: 11,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 100,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F55E8), Color(0xFF5D12D2)],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            "اطلب الآن",
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Image.asset(
                    promo["image"] as String,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRestaurantList() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 4,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            context.push('/restaurant-detail');
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0C0C26).withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                   Colors.white.withOpacity(0.05),
                   Colors.transparent,
                ],
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.favorite_border, color: Colors.white54),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "مذاقي السياحي",
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "أمام المملكة مول",
                        style: GoogleFonts.cairo(color: Colors.white54, fontSize: 12),
                      ),
                      Row(
                        children: const [
                          Icon(Icons.star, color: Colors.amber, size: 18),
                          Icon(Icons.star, color: Colors.amber, size: 18),
                          Icon(Icons.star, color: Colors.amber, size: 18),
                          Icon(Icons.star, color: Colors.amber, size: 18),
                          Icon(Icons.star, color: Colors.amber, size: 18),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Container(
                  width:  90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber.withOpacity(0.5)),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/dish.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}