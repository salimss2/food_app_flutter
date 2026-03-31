import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/custom_background.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  int _selectedCategoryIndex = 1;
  int _selectedTabIndex = 0;

  final List<Map<String, dynamic>> _categories = [
    {"name": "كل التصنيفات", "icon": Icons.list_alt},
    {"name": "الكل", "icon": Icons.grid_view_rounded},
    {"name": "المطاعم", "icon": Icons.fastfood_outlined},
    {"name": "خضروات وفواكه", "icon": Icons.apple_outlined},
    {"name": "عسل وتمور", "icon": Icons.hive_outlined},
  ];

  final List<String> _tabs = ["الكل", "الاقرب", "الجديدة", "المفضلة"];

  final List<Map<String, dynamic>> _searchResults = [
    {
      "name": "ملك المضغوط",
      "address": "المساكن شارع الشيخ باناحه",
      "distance": "0.50 كيلو",
      "rating": 5,
      "isOpen": true,
      "tags": ["المطاعم", "المطاعم الأسرع"],
      "logo": "assets/images/group.jpg",
    },
    {
      "name": "مطعم ومطبخ سعيد الحامدي",
      "address": "الشرج جوار محطة الشاطئ",
      "distance": "8.77 كيلو",
      "rating": 4,
      "isOpen": true,
      "tags": ["المطاعم"],
      "logo": "assets/images/group.jpg",
    },
    {
      "name": "كافيه قرين وود",
      "address": "المنصه المكلا بارك",
      "distance": "1.18 كيلو",
      "rating": 5,
      "isOpen": true,
      "tags": ["المطاعم"],
      "logo": "assets/images/group.jpg",
    },
    {
      "name": "كافيه قرين وود",
      "address": "المنصه المكلا بارك",
      "distance": "1.18 كيلو",
      "rating": 5,
      "isOpen": true,
      "tags": ["المطاعم"],
      "logo": "assets/images/group.jpg",
    },
    {
      "name": "كافيه قرين وود",
      "address": "المنصه المكلا بارك",
      "distance": "1.18 كيلو",
      "rating": 5,
      "isOpen": true,
      "tags": ["المطاعم"],
      "logo": "assets/images/group.jpg",
    },
    {
      "name": "كافيه قرين وود",
      "address": "المنصه المكلا بارك",
      "distance": "1.18 كيلو",
      "rating": 5,
      "isOpen": true,
      "tags": ["المطاعم"],
      "logo": "assets/images/group.jpg",
    },
    {
      "name": "كافيه قرين وود",
      "address": "المنصه المكلا بارك",
      "distance": "1.18 كيلو",
      "rating": 5,
      "isOpen": true,
      "tags": ["المطاعم"],
      "logo": "assets/images/group.jpg",
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomBackground(
          child: SafeArea(
            child: Column(
              children: [
                // 1. شريط البحث العلوي
                _buildSearchHeader(context),

                // 2. شريط التصنيفات (أيقونات)
                _buildCategoriesBar(),

                // 3. شريط التبويبات (نصوص)
                _buildTabsBar(),

                const SizedBox(height: 10),

                // 4. قائمة النتائج
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      return _buildSearchResultCard(_searchResults[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. شريط البحث العلوي
  // ===========================================================================
  Widget _buildSearchHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1A34).withOpacity(0.60),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true, // يفتح الكيبورد تلقائياً
                style: GoogleFonts.cairo(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "ابحث عن...",
                  hintStyle: GoogleFonts.cairo(color: Colors.white54),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 12,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white54,
                      size: 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. شريط التصنيفات الأفقي (الأيقونات)
  // ===========================================================================
  Widget _buildCategoriesBar() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: Container(
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF0F55E8).withOpacity(
                        0.3,
                      ) // لون التحديد الأزرق بدلاً من الأحمر
                    : const Color(0xFF1E1A34).withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0F55E8)
                      : Colors.white.withOpacity(0.05),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _categories[index]["icon"],
                    color: isSelected ? Colors.white : Colors.white54,
                    size: 28,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _categories[index]["name"],
                    style: GoogleFonts.cairo(
                      color: isSelected ? Colors.white : Colors.white54,
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
  // 3. شريط التبويبات (النصوص)
  // ===========================================================================
  Widget _buildTabsBar() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _tabs.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedTabIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected
                        ? const Color(0xFF0F55E8)
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  _tabs[index],
                  style: GoogleFonts.cairo(
                    color: isSelected ? Colors.white : Colors.white54,
                    fontSize: 16,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 4. كرت نتيجة البحث المخصص
  // ===========================================================================
  Widget _buildSearchResultCard(Map<String, dynamic> result) {
    return Container(
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
          // --- اليمين: اللوجو والتقييم والمسافة ---
          Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: AssetImage(result["logo"]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result["distance"],
                style: GoogleFonts.cairo(color: Colors.white70, fontSize: 11),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    Icons.star,
                    color: index < result["rating"]
                        ? Colors.amber
                        : Colors.white24,
                    size: 10,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),

          // --- الوسط: التفاصيل (الاسم، العنوان، التاجات) ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result["name"],
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  result["address"],
                  style: GoogleFonts.cairo(color: Colors.white54, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: (result["tags"] as List<String>)
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
                            tag,
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

          // --- اليسار: حالة المطعم والمفضلة ---
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (result["isOpen"])
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFE69B35,
                    ).withOpacity(0.2), // برتقالي شفاف
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
              const Icon(
                Icons.favorite_border,
                color: Color(0xFFFF5555),
                size: 22,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
