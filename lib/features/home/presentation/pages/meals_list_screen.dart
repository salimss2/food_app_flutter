import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/custom_background.dart';

class MealsListScreen extends StatefulWidget {
  const MealsListScreen({super.key});

  @override
  State<MealsListScreen> createState() => _MealsListScreenState();
}

class _MealsListScreenState extends State<MealsListScreen> {
  // بيانات وهمية مستوحاة من السكرين شوت
  final List<Map<String, dynamic>> _meals = [
    {
      "restaurant": "بيت الشاورما",
      "name": "شاورما ناشفل",
      "time": "30 دقيقة",
      "distance": "2.2 كم",
      "isFreeDelivery": true,
      "oldPrice": "38.66",
      "newPrice": "29.00",
      "image": "assets/images/burger.png", // استبدلها بصورة الوجبة
      "logo": "assets/images/group.jpg",   // استبدلها بشعار المطعم
    },
    {
      "restaurant": "بيت الشاورما",
      "name": "عربي دجاج وشاورما دجاج ساندويش",
      "time": "30 دقيقة",
      "distance": "2.2 كم",
      "isFreeDelivery": true,
      "oldPrice": "48.30",
      "newPrice": "28.98",
      "image": "assets/images/chicken.png",
      "logo": "assets/images/group.jpg",
    },
    {
      "restaurant": "اللاهب",
      "name": "وجبة ساندوتش تويستر",
      "time": "25 دقيقة",
      "distance": "4 كم",
      "isFreeDelivery": true,
      "oldPrice": "35.70",
      "newPrice": "24.99",
      "image": "assets/images/dish.png",
      "logo": "assets/images/group.jpg",
    },
    {
      "restaurant": "الطازج",
      "name": "وجبة ساندويتش كباب سنغل",
      "time": "15 دقيقة",
      "distance": "1.8 كم",
      "isFreeDelivery": true,
      "oldPrice": "25.70",
      "newPrice": "20.56",
      "image": "assets/images/pizzaicon.png",
      "logo": "assets/images/group.jpg",
    },
  ];

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
              SliverToBoxAdapter(
                child: _buildTopBanner(context),
              ),

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
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // عمودين
                    childAspectRatio: 0.58, // نسبة الطول للعرض لتناسب النصوص الكثيرة
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildMealCard(_meals[index]);
                    },
                    childCount: _meals.length,
                  ),
                ),
              ),

              // مسافة سفلية إضافية
              const SliverToBoxAdapter(
                child: SizedBox(height: 40),
              ),
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
              image: AssetImage('assets/images/Pasta.png'), // ضع هنا صورة البانر الإعلاني
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
                  const Color(0xFF140C36).withOpacity(0.9), // لون الخلفية الداكنة
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
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
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
                    style: GoogleFonts.cairo(color: Colors.white70, fontSize: 16),
                  ),
                  Text(
                    "19 ر.ي",
                    style: GoogleFonts.cairo(
                      color: const Color(0xFFFF5555), // لون أحمر أو برتقالي للفت الانتباه
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
        style: GoogleFonts.cairo(color: Colors.white),
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: "ابحث عن مطعم أو وجبة",
          hintStyle: GoogleFonts.cairo(color: Colors.white54, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.white54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. كرت الوجبة (Glassmorphism Style)
  // ===========================================================================
  Widget _buildMealCard(Map<String, dynamic> meal) {
    return GestureDetector(
      onTap: () {
        // --- التعديل هنا: الانتقال إلى صفحة تفاصيل الوجبة ---
        context.push('/meal-detail'); 
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    color: Colors.white.withOpacity(0.05),
                    child: Image.asset(
                      meal['image'],
                      fit: BoxFit.cover,
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
                      image: DecorationImage(
                        image: AssetImage(meal['logo']),
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
                    // اسم المطعم
                    Text(
                      meal['restaurant'],
                      style: GoogleFonts.cairo(color: Colors.white54, fontSize: 10, height: 1.2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    
                    // اسم الوجبة
                    Text(
                      meal['name'],
                      style: GoogleFonts.cairo(
                        color: Colors.white, 
                        fontSize: 13, 
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),

                    // الوقت والمسافة
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, color: Colors.white54, size: 10),
                        const SizedBox(width: 2),
                        Text(
                          meal['time'],
                          style: GoogleFonts.cairo(color: Colors.white54, fontSize: 10),
                        ),
                        const SizedBox(width: 5),
                        Text("|", style: TextStyle(color: Colors.white24, fontSize: 10)),
                        const SizedBox(width: 5),
                        Text(
                          meal['distance'],
                          style: GoogleFonts.cairo(color: Colors.white54, fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // التوصيل المجاني
                    if (meal['isFreeDelivery'])
                      Row(
                        children: [
                          const Icon(Icons.delivery_dining, color: Colors.cyanAccent, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            "توصيل مجاني",
                            style: GoogleFonts.cairo(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold),
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
                        Text(
                          "${meal['oldPrice']} ر.ي",
                          style: GoogleFonts.poppins(
                            color: Colors.white38,
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        // السعر الجديد
                        Text(
                          "${meal['newPrice']} ر.ي",
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFFF5555), // لون مميز للسعر المخفض
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