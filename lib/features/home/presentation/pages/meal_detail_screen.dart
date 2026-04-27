import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../providers/cart_provider.dart';
import '../../../../models/restaurant_model.dart';

import '../../../../core/widgets/custom_background.dart';

class MealDetailScreen extends StatefulWidget {
  final Meal meal;
  const MealDetailScreen({super.key, required this.meal});

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  int quantity = 1;
  late double _basePrice;
  bool isAddedToCart = false;

  Map<String, bool> addons = {
    'زيادة جبن (+500 ر.ي)': false,
    'بدون بصل': false,
    'مشروب غازي (+800 ر.ي)': false,
  };

  @override
  void initState() {
    super.initState();
    _basePrice = widget.meal.price;
  }

  double get _totalPrice {
    double total = _basePrice;
    if (addons['زيادة جبن (+500 ر.ي)'] == true) total += 500.0;
    if (addons['مشروب غازي (+800 ر.ي)'] == true) total += 800.0;
    return total * quantity;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomBackground(
          child: Stack(
            children: [
              // --- المحتوى القابل للتمرير ---
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 1. الصورة العلوية مع زر الرجوع
                  _buildSliverAppBar(context),

                  // 2. تفاصيل الوجبة الأساسية
                  SliverToBoxAdapter(
                    child: Transform.translate(
                      offset: const Offset(0, -30),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          children: [
                            const SizedBox(height: 40),
                            _buildMealHeaderCard(),
                            const SizedBox(height: 20),

                            // 3. أقسام الاختيارات
                            _buildOptionsSections(),

                            // مسافة سفلية لعدم تغطية شريط الإضافة
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // --- 4. شريط الإضافة للسلة السفلي (Sticky Bottom Bar) ---
              Align(
                alignment: Alignment.bottomCenter,
                child: _buildBottomCartBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. الصورة العلوية (Sliver App Bar)
  // ===========================================================================
  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280.0,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF140C36),
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.share_outlined,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {},
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              widget.meal.imageUrl ??
                  'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&q=80',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[850],
                child: const Icon(Icons.fastfood, color: Colors.grey, size: 60),
              ),
            ),
            // تدرج لوني لدمج الصورة مع الخلفية
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF140C36).withOpacity(0.9),
                  ],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. كرت تفاصيل الوجبة الأساسية
  // ===========================================================================
  Widget _buildMealHeaderCard() {
    final String name = widget.meal.name.isNotEmpty ? widget.meal.name : 'وجبة';
    final String category = 'وجبات سريعة';
    final String desc = widget.meal.description.isNotEmpty
        ? widget.meal.description
        : 'وصف للوجبة غير متوفر';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A34).withOpacity(0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category,
            style: GoogleFonts.cairo(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ),
              const Icon(
                Icons.favorite_border,
                color: Colors.white54,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // البادجات (توصيل مجاني، خصم)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5555).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFF5555).withOpacity(0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_offer,
                      color: Color(0xFFFF5555),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "30%",
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFFF5555),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.delivery_dining,
                      color: Colors.cyanAccent,
                      size: 14,
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
              ),
            ],
          ),

          const SizedBox(height: 15),
          Text(
            desc,
            style: GoogleFonts.cairo(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Divider(color: Colors.white.withOpacity(0.1), height: 1),
          ),

          // شريط المعلومات (سعرات، تنبيهات)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoBadge(
                Icons.local_fire_department_outlined,
                "437 سعرة حرارية",
              ),
              _buildInfoBadge(Icons.info_outline, "تنبيهات"),
              _buildInfoBadge(Icons.analytics_outlined, "الحقائق التغذوية"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.cairo(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }

  // ===========================================================================
  // 3. أقسام الاختيارات المخصصة
  // ===========================================================================
  Widget _buildOptionsSections() {
    return Column(
      children: [
        _buildSectionContainer(
          title: "الإضافات",
          subtitle: "خيارات متعددة",
          isRequired: false,
          children: addons.keys.map((String key) {
            return _buildCheckboxOption(
              label: key,
              price: "",
              value: addons[key]!,
              onChanged: (val) {
                setState(() {
                  addons[key] = val!;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- حاوية القسم الزجاجية ---
  Widget _buildSectionContainer({
    required String title,
    required String subtitle,
    required bool isRequired,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A34).withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس القسم
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.cairo(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (isRequired)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "مطلوب",
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.05), height: 1),

          // عناصر القسم
          ...children,
        ],
      ),
    );
  }

  // --- عنصر خيار شيك بوكس ---
  Widget _buildCheckboxOption({
    required String label,
    required String price,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Theme(
      data: ThemeData(unselectedWidgetColor: Colors.white54),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF0F55E8),
        checkColor: Colors.white,
        title: Text(
          label,
          style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
        ),
        secondary: Text(
          price,
          style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        dense: true,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  // ===========================================================================
  // 4. شريط الإضافة للسلة (Bottom Bar)
  // ===========================================================================
  Widget _buildBottomCartBar() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: const Color(0xFF140C36).withOpacity(0.85),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: !isAddedToCart
                  ? Row(
                      key: const ValueKey('add_to_cart_ui'),
                      children: [
                        // أزرار التحكم بالكمية
                        Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                ),
                                onPressed: () => setState(() => quantity++),
                              ),
                              Text(
                                quantity.toString(),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.remove,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  if (quantity > 1) setState(() => quantity--);
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 15),

                        // زر الإضافة للسلة مع السعر
                        Expanded(
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0F55E8), Color(0xFF5D12D2)],
                              ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF0F55E8,
                                  ).withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  List<String> selectedAddons = [];
                                  addons.forEach((key, value) {
                                    if (value) selectedAddons.add(key);
                                  });

                                  try {
                                    await Provider.of<CartProvider>(
                                      context,
                                      listen: false,
                                    ).addItem(
                                      CartItem(
                                        mealId: widget.meal.id.isNotEmpty
                                            ? widget.meal.id
                                            : DateTime.now().toString(),
                                        name: widget.meal.name.isNotEmpty
                                            ? widget.meal.name
                                            : 'وجبة سريعة',
                                        price: (_totalPrice / quantity),
                                        imageUrl: widget.meal.imageUrl ??
                                            'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&q=80',
                                        quantity: quantity,
                                        addons: selectedAddons,
                                      ),
                                    );

                                    setState(() {
                                      isAddedToCart = true;
                                    });
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'فشل الإضافة: ${e.toString()}',
                                          style: GoogleFonts.cairo(color: Colors.white),
                                        ),
                                        backgroundColor: Colors.red.shade700,
                                      ),
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(15),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "إضافة",
                                        style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          if (quantity ==
                                              1) // إظهار السعر القديم فقط إذا كانت الكمية 1
                                            Text(
                                              "${(_basePrice * 1.2).toStringAsFixed(0)} ر.ي",
                                              style: GoogleFonts.poppins(
                                                color: Colors.white54,
                                                fontSize: 10,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                height: 1,
                                              ),
                                            ),
                                          Text(
                                            "${_totalPrice.toStringAsFixed(2)} ر.ي",
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              height: 1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      key: const ValueKey('go_to_cart_ui'),
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "تمت الإضافة للسلة بنجاح",
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              context.push('/cart');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF140C36),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Text(
                              "الانتقال للسلة",
                              style: GoogleFonts.cairo(
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
        ),
      ),
    );
  }
}
