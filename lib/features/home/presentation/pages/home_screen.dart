import 'dart:ui'; // <-- هام جداً لتأثير الزجاج
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
                // زيادة المسافة السفلية لضمان عدم تغطية الشريط للمحتوى الأخير
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
                        _buildSectionTitle("الأقسام", showSeeAll: true),
                        const SizedBox(height: 15),
                        _buildCategoriesList(),
                        const SizedBox(height: 25),
                        _buildPromoBanner(),
                        const SizedBox(height: 25),
                        _buildSectionTitle("جميع المطاعم", showSeeAll: true),
                        const SizedBox(height: 15),
                        _buildRestaurantList(),
                      ],
                    ),
                  ),
                ),
              ),

              // --- شريط التنقل السفلي العائم (المعدل) ---
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
  // التعديلات الجديدة على الـ NavBar ليكون مطابقاً للسكرين شوت
  // ===========================================================================

  Widget _buildFloatingNavBar() {
    // استخدام ClipRRect لقص تأثير التمويه داخل الحواف الدائرية
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30), // هوامش خارجية
      child: Container(
        height: 75, // زيادة الارتفاع قليلاً ليناسب شكل الكبسولة
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35), // حواف دائرية كبيرة (شكل كبسولة)
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
           // تطبيق التمويه الحقيقي على الخلفية
           child: BackdropFilter(
             filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // قوة التمويه
             child: Container(
               padding: const EdgeInsets.symmetric(horizontal: 15),
               decoration: BoxDecoration(
                 // لون الخلفية الداكن والشفاف
                 color: const Color(0xFF1E1A34).withOpacity(0.1),
                 borderRadius: BorderRadius.circular(35),
                 // إطار رفيع جداً وشفاف
                 border: Border.all(color: Colors.white.withOpacity(0.7), width: 1),
               ),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   // نمرر الأيقونة المعبأة (Selected) والمفرغة (Unselected)
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

  // ودجت العنصر الواحد في الشريط (المعدل)
  Widget _navItem({
    required IconData selectedIcon,   // الأيقونة المعبأة
    required IconData unselectedIcon, // الأيقونة المفرغة
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      // استخدام Container شفاف لتوسيع منطقة الضغط
      child: Container(
        color: Colors.transparent, 
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // منطق الأيقونة: إذا تم الاختيار، نعرض الأيقونة المعبأة مع تدرج لوني
            if (isSelected)
              ShaderMask(
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    colors: [Color(0xFF0F55E8), Color.fromARGB(255, 130, 87, 199)], // ألوان البراند
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ).createShader(bounds);
                },
                child: Icon(
                  selectedIcon, // استخدام الأيقونة المعبأة
                  color: Colors.white, // يجب أن يكون اللون أبيض ليعمل الـ ShaderMask
                  size: 26,
                ),
              )
            else
              // إذا لم يتم الاختيار، نعرض الأيقونة المفرغة باللون الرمادي
              Icon(
                unselectedIcon, // استخدام الأيقونة المفرغة
                color: Colors.white54,
                size: 26,
              ),
        
            const SizedBox(height: 4),
            
            // منطق النص
            Text(
              label,
              style: GoogleFonts.cairo(
                // النص المختار يأخذ لوناً أزرق صريحاً (التدرج على النصوص الصغيرة لا يبدو جيداً)
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
  // بقية الودجت (الهيدر، البحث، القوائم) كما هي بدون تغيير
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

  Widget _buildSectionTitle(String title, {bool showSeeAll = false}) {
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
          Text(
            "الكل",
            style: GoogleFonts.cairo(color: Colors.white54, fontSize: 12),
          ),
      ],
    );
  }

  Widget _buildCategoriesList() {
    final categories = [
      {"name": "برجر", "image": "assets/images/burger.png"},
      {"name": "حلى", "image": "assets/images/cake.png"},
      {"name": "دجاج", "image": "assets/images/chicken.png"},
      {"name": "بيتزا", "image": "assets/images/pizzaicon.png"},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: categories.map((cat) {
        return Column(
          children: [
            Container(
              width: 65,
              height: 65,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1A34).withOpacity(0.60),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Image.asset(
                cat["image"]!,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              cat["name"]!,
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 18),
            ),
          ],
        );
      }).toList(),
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
        return Container(
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
        );
      },
    );
  }
}