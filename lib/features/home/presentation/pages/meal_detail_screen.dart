import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/custom_background.dart';

class MealDetailScreen extends StatefulWidget {
  const MealDetailScreen({super.key});

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  // --- إدارة حالة الصفحة (الكمية والأسعار والخيارات) ---
  int _quantity = 1;
  final double _basePrice = 24.99;
  final double _oldPrice = 35.70;

  // الخيارات المحددة (راديو)
  String _selectedSandwichOption = 'عادي';
  String _selectedDrinkOption = 'كوكا كولا';
  String _selectedFriesOption = 'بطاطس مبهر';

  // الخيارات المتعددة (شيك بوكس)
  final Map<String, bool> _selectedSauces = {
    'اللاهب صوص': false,
    'صوص الباربيكيو': false,
    'صوص رانش': false,
    'صوص جبن': false,
  };

  bool _addCheese = false;

  // دالة لحساب السعر الإجمالي (للتوضيح فقط، يمكنك تعديلها حسب منطق الباك اند)
  double get _totalPrice {
    double total = _basePrice;
    if (_addCheese) total += 2.0;
    // إضافة أسعار الصوصات إذا كانت محددة
    _selectedSauces.forEach((key, isSelected) {
      if (isSelected) total += 4.0;
    });
    return total * _quantity;
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
              icon: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
              onPressed: () {},
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/burger.png', // استبدل بصورة الوجبة
              fit: BoxFit.cover,
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
            "اللاهب",
            style: GoogleFonts.cairo(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  "وجبة ساندوتش تويستر",
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ),
              const Icon(Icons.favorite_border, color: Colors.white54, size: 24),
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
                  border: Border.all(color: const Color(0xFFFF5555).withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_offer, color: Color(0xFFFF5555), size: 12),
                    const SizedBox(width: 4),
                    Text("30%", style: GoogleFonts.poppins(color: const Color(0xFFFF5555), fontSize: 10, fontWeight: FontWeight.bold)),
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
                    const Icon(Icons.delivery_dining, color: Colors.cyanAccent, size: 14),
                    const SizedBox(width: 4),
                    Text("توصيل مجاني", style: GoogleFonts.cairo(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 15),
          Text(
            "ساندوتش صغير من خبز التورتيلا مع دجاج فيليه بخلطة اللاهب المقرمشة مع بطاطس ومشروب غازي من اختيارك",
            style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Divider(color: Colors.white.withOpacity(0.1), height: 1),
          ),
          
          // شريط المعلومات (سعرات، تنبيهات)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoBadge(Icons.local_fire_department_outlined, "437 سعرة حرارية"),
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
        // قسم 1: راديو (اختيار واحد مطلوب)
        _buildSectionContainer(
          title: "اختيارك من ساندوتش تويستر",
          subtitle: "اختيار واحد",
          isRequired: true,
          children: [
            _buildRadioOption("ساندوتش تويستر (عادي)", null, "عادي", _selectedSandwichOption, (val) => setState(() => _selectedSandwichOption = val!)),
            _buildRadioOption("ساندوتش تويستر (لاهب/حار)", null, "حار", _selectedSandwichOption, (val) => setState(() => _selectedSandwichOption = val!)),
            _buildRadioOption("ساندوتش تويستر عادي (مبهر)", "+ 2 ر.ي", "مبهر عادي", _selectedSandwichOption, (val) => setState(() => _selectedSandwichOption = val!)),
            _buildRadioOption("ساندوتش تويستر لاهب/حار (مبهر)", "+ 2 ر.ي", "مبهر حار", _selectedSandwichOption, (val) => setState(() => _selectedSandwichOption = val!)),
          ],
        ),

        const SizedBox(height: 20),

        // قسم 2: راديو (اختيار المشروب)
        _buildSectionContainer(
          title: "اختيار المشروب المجاني",
          subtitle: "اختيار واحد",
          isRequired: true,
          children: [
            _buildRadioOption("كوكا كولا", "105 سعرة", "كوكا كولا", _selectedDrinkOption, (val) => setState(() => _selectedDrinkOption = val!), isCalorie: true),
            _buildRadioOption("كوكا كولا لايت", "1 سعرة", "كوكا كولا لايت", _selectedDrinkOption, (val) => setState(() => _selectedDrinkOption = val!), isCalorie: true),
            _buildRadioOption("فانتا برتقال", "145 سعرة", "فانتا برتقال", _selectedDrinkOption, (val) => setState(() => _selectedDrinkOption = val!), isCalorie: true),
            _buildRadioOption("سبرايت", "118 سعرة", "سبرايت", _selectedDrinkOption, (val) => setState(() => _selectedDrinkOption = val!), isCalorie: true),
          ],
        ),

        const SizedBox(height: 20),

        // قسم 3: شيك بوكس (إضافات اختيارية)
        _buildSectionContainer(
          title: "إضافة صوصات",
          subtitle: "خيارات متعددة",
          isRequired: false,
          children: _selectedSauces.keys.map((String key) {
            return _buildCheckboxOption(
              label: key,
              price: "+ 4 ر.ي",
              value: _selectedSauces[key]!,
              onChanged: (val) {
                setState(() {
                  _selectedSauces[key] = val!;
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
                    Text(title, style: GoogleFonts.cairo(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(subtitle, style: GoogleFonts.cairo(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                if (isRequired)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text("مطلوب", style: GoogleFonts.cairo(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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

  // --- عنصر خيار راديو ---
  Widget _buildRadioOption(String label, String? trailingText, String value, String groupValue, ValueChanged<String?> onChanged, {bool isCalorie = false}) {
    return Theme(
      data: ThemeData(unselectedWidgetColor: Colors.white54),
      child: RadioListTile<String>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: const Color(0xFF0F55E8),
        title: Text(label, style: GoogleFonts.cairo(color: Colors.white, fontSize: 14)),
        secondary: trailingText != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isCalorie) const Icon(Icons.local_fire_department_outlined, color: Colors.white54, size: 14),
                  if (isCalorie) const SizedBox(width: 4),
                  Text(
                    trailingText,
                    style: GoogleFonts.cairo(color: isCalorie ? Colors.white54 : Colors.white70, fontSize: 12),
                  ),
                ],
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        dense: true,
      ),
    );
  }

  // --- عنصر خيار شيك بوكس ---
  Widget _buildCheckboxOption({required String label, required String price, required bool value, required ValueChanged<bool?> onChanged}) {
    return Theme(
      data: ThemeData(unselectedWidgetColor: Colors.white54),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF0F55E8),
        checkColor: Colors.white,
        title: Text(label, style: GoogleFonts.cairo(color: Colors.white, fontSize: 14)),
        secondary: Text(price, style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12)),
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
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, -5)),
            ],
          ),
          child: SafeArea(
            child: Row(
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
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: () => setState(() => _quantity++),
                      ),
                      Text(
                        _quantity.toString(),
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove, color: Colors.white),
                        onPressed: () {
                          if (_quantity > 1) setState(() => _quantity--);
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
                        BoxShadow(color: const Color(0xFF0F55E8).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // كود إضافة الوجبة للسلة
                          context.pop(); // العودة للخلف بعد الإضافة
                        },
                        borderRadius: BorderRadius.circular(15),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "إضافة",
                                style: GoogleFonts.cairo(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (_quantity == 1) // إظهار السعر القديم فقط إذا كانت الكمية 1
                                    Text(
                                      "$_oldPrice ر.ي",
                                      style: GoogleFonts.poppins(
                                        color: Colors.white54,
                                        fontSize: 10,
                                        decoration: TextDecoration.lineThrough,
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
            ),
          ),
        ),
      ),
    );
  }
}