import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/custom_background.dart';
import '../../../../providers/restaurant_provider.dart';
import '../../../../models/restaurant_model.dart';

class MealsListScreen extends ConsumerStatefulWidget {
  const MealsListScreen({super.key});

  @override
  ConsumerState<MealsListScreen> createState() => _MealsListScreenState();
}

class _MealsListScreenState extends ConsumerState<MealsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Meal> allMeals = [];
  List<Meal> displayedMeals = [];
  bool isLoadingMeals = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchMeals();
  }

  void fetchMeals() {
    try {
      final asyncRestaurants = ref.read(restaurantProvider);

      List<Meal> tempMeals = [];
      
      asyncRestaurants.whenData((restaurants) {
        for (var restaurant in restaurants) {
          tempMeals.addAll(restaurant.meals); // From top-level meals
          for (var menu in restaurant.menus) {
            tempMeals.addAll(menu.meals); // From inner menus
          }
        }
      });

      setState(() {
        allMeals = tempMeals;
        displayedMeals = List.from(allMeals);
        isLoadingMeals = false;
      });
    } catch (e) {
      setState(() {
        isLoadingMeals = false;
      });
    }
  }

  void _filterMeals(String query) {
    if (query.isEmpty) {
      setState(() {
        displayedMeals = List.from(allMeals);
      });
    } else {
      setState(() {
        displayedMeals = allMeals.where((meal) {
          final name = meal.name.toLowerCase();
          return name.contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomBackground(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. البانر العلوي (Hero Banner)
              SliverToBoxAdapter(child: _buildTopBanner(context)),

              // 2. شريط البحث
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
                  child: _buildSearchBar(),
                ),
              ),

              // 3. شبكة الوجبات (Grid View)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: isLoadingMeals
                    ? const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(top: 50.0),
                          child: Center(
                            child: CircularProgressIndicator(color: Colors.red),
                          ),
                        ),
                      )
                    : displayedMeals.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 50.0),
                          child: Center(
                            child: Text(
                              "لا توجد وجبات مطابقة لبحثك 🍽️",
                              style: GoogleFonts.cairo(
                                color: Colors.white54,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      )
                    : SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2, // عمودين
                              childAspectRatio:
                                  0.58, // نسبة الطول للعرض لتناسب النصوص الكثيرة
                              crossAxisSpacing: 15,
                              mainAxisSpacing: 15,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return _buildMealCard(displayedMeals[index]);
                        }, childCount: displayedMeals.length),
                      ),
              ),

              // مسافة سفلية إضافية
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. البانر العلوي
  // ===========================================================================
  Widget _buildTopBanner(BuildContext context) {
    return Stack(
      children: [
        // صورة البانر (الوجبات ابتداءً من 19 ريال)
        Container(
          height: 220,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                'assets/images/Pasta.png',
              ), // ضع هنا صورة البانر الإعلاني
              fit: BoxFit.cover,
            ),
          ),
          // تدرج لوني لدمج الصورة مع الخلفية الداكنة
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  const Color(
                    0xFF140C36,
                  ).withOpacity(0.9), // لون الخلفية الداكنة
                ],
                stops: const [0.3, 1.0],
              ),
            ),
          ),
        ),

        // زر الرجوع الشفاف
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => context.pop(), // الرجوع باستخدام go_router
              ),
            ),
          ),
        ),

        // نص البانر فوق الصورة
        Positioned(
          bottom: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "وجبات",
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              Row(
                children: [
                  Text(
                    "ابتداءً من ",
                    style: GoogleFonts.cairo(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "19 ر.ي",
                    style: GoogleFonts.cairo(
                      color: const Color(
                        0xFFFF5555,
                      ), // لون أحمر أو برتقالي للفت الانتباه
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. شريط البحث
  // ===========================================================================
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A34).withOpacity(0.60),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterMeals,
        style: GoogleFonts.cairo(color: Colors.white),
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: "ابحث عن مطعم أو وجبة",
          hintStyle: GoogleFonts.cairo(color: Colors.white54, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.white54),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close, color: Colors.white54, size: 20),
            onPressed: () {
              _searchController.clear();
              _filterMeals('');
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. كرت الوجبة (Glassmorphism Style)
  // ===========================================================================
  Widget _buildMealCard(Meal meal) {
    final String name = meal.name.isNotEmpty ? meal.name : 'وجبة';
    final String image =
        meal.imageUrl ??
        'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&q=80';
    
    // Check for offers
    final bool hasOffers = meal.offers.isNotEmpty;
    final double price = hasOffers && meal.offers.first.discountPrice != null 
        ? meal.offers.first.discountPrice! 
        : meal.price;
        
    final double? oldPrice = hasOffers ? meal.price : null;
    
    final String category = "وجبات سريعة";

    return GestureDetector(
      onTap: () {
        context.push('/meal-detail', extra: meal);
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1A34).withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- الجزء العلوي: الصورة والشعار ---
            Stack(
              clipBehavior: Clip.none,
              children: [
                // صورة الوجبة
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    color: Colors.white.withOpacity(0.05),
                    child: Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[850],
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
                ),
                // شعار المطعم (دائري فوق الصورة)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/group.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // --- الجزء السفلي: التفاصيل ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // اسم المطعم أو التصنيف
                    Text(
                      category.isNotEmpty ? category : "وجبات سريعة",
                      style: GoogleFonts.cairo(
                        color: Colors.white54,
                        fontSize: 10,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),

                    // اسم الوجبة
                    Text(
                      name,
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),

                    // الوقت والمسافة
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          color: Colors.white54,
                          size: 10,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          "30 دقيقة",
                          style: GoogleFonts.cairo(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          "|",
                          style: TextStyle(color: Colors.white24, fontSize: 10),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "2.5 كم",
                          style: GoogleFonts.cairo(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // التوصيل المجاني
                    Row(
                      children: [
                        const Icon(
                          Icons.delivery_dining,
                          color: Colors.cyanAccent,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "توصيل مجاني",
                          style: GoogleFonts.cairo(
                            color: Colors.cyanAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),
                    Divider(color: Colors.white.withOpacity(0.05), height: 1),
                    const SizedBox(height: 6),

                    // الأسعار
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // السعر القديم (مشطوب)
                        if (oldPrice != null)
                          Text(
                            "${oldPrice.toStringAsFixed(0)} ر.ي",
                            style: GoogleFonts.poppins(
                              color: Colors.white38,
                              fontSize: 11,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        // السعر الجديد
                        Text(
                          "${price.toStringAsFixed(0)} ر.ي",
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFFF5555),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
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
    );
  }
}
