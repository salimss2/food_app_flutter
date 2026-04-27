import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/custom_background.dart';
import 'package:provider/provider.dart';
import '../../../../providers/order_provider.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<OrderProvider>().fetchOrders());
  }

  // ===========================================================================
  // بيانات وهمية للطلبات السابقة
  // ===========================================================================
  final List<Map<String, dynamic>> _pastOrders = [
    {
      "id": "#ORD-8541",
      "restaurantName": "مذاقي السياحي",
      "restaurantLogo": "assets/images/group.jpg", // استبدلها بصورة مناسبة
      "date": "14 مارس 2026 | 02:30 م",
      "status": "مكتمل",
      "totalPrice": "8,500 ر.ي",
      "items": "1x بروست دجاج مذاقي, 1x بيبسي",
    },
    {
      "id": "#ORD-8210",
      "restaurantName": "ملك المضغوط",
      "restaurantLogo": "assets/images/group.jpg",
      "date": "10 مارس 2026 | 01:15 م",
      "status": "مكتمل",
      "totalPrice": "4,000 ر.ي",
      "items": "1x مضغوط دجاج",
    },
    {
      "id": "#ORD-7992",
      "restaurantName": "كافيه قرين وود",
      "restaurantLogo": "assets/images/group.jpg",
      "date": "05 مارس 2026 | 09:00 ص",
      "status": "ملغي",
      "totalPrice": "2,200 ر.ي",
      "items": "2x كابتشينو, 1x كرواسون",
    },
    {
      "id": "#ORD-7992",
      "restaurantName": "كافيه قرين وود",
      "restaurantLogo": "assets/images/group.jpg",
      "date": "05 مارس 2026 | 09:00 ص",
      "status": "ملغي",
      "totalPrice": "2,200 ر.ي",
      "items": "2x كابتشينو, 1x كرواسون",
    },
    {
      "id": "#ORD-7992",
      "restaurantName": "كافيه قرين وود",
      "restaurantLogo": "assets/images/group.jpg",
      "date": "05 مارس 2026 | 09:00 ص",
      "status": "ملغي",
      "totalPrice": "2,200 ر.ي",
      "items": "2x كابتشينو, 1x كرواسون",
    },
    {
      "id": "#ORD-7992",
      "restaurantName": "كافيه قرين وود",
      "restaurantLogo": "assets/images/group.jpg",
      "date": "05 مارس 2026 | 09:00 ص",
      "status": "ملغي",
      "totalPrice": "2,200 ر.ي",
      "items": "2x كابتشينو, 1x كرواسون",
    },
    {
      "id": "#ORD-7992",
      "restaurantName": "كافيه قرين وود",
      "restaurantLogo": "assets/images/group.jpg",
      "date": "05 مارس 2026 | 09:00 ص",
      "status": "ملغي",
      "totalPrice": "2,200 ر.ي",
      "items": "2x كابتشينو, 1x كرواسون",
    },
  ];

  // دالة محاكاة إضافة الطلب للسلة
  void _reorderItems(String orderId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تمت إضافة عناصر الطلب $orderId إلى السلة بنجاح!',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0F55E8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Never allow the default system pop on this root-tab screen.
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (didPop) return; // Already handled — shouldn't happen with canPop:false
        // Back button pressed → go back to Home, not exit the app.
        context.go('/home');
      },
      child: Scaffold(
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: CustomBackground(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. الهيدر (العنوان وزر الرجوع) ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    child: Row(
                      children: [
                        _buildBackButton(context),
                        const SizedBox(width: 15),
                        Text(
                          "طلباتي",
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // --- 2. الطلب الحالي ---
                  _buildSectionTitle("الطلب الحالي"),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: _buildActiveOrderCard(context),
                  ),

                  const SizedBox(height: 10),

                  // --- 3. قائمة الطلبات السابقة ---
                  _buildSectionTitle("الطلبات السابقة"),
                  const SizedBox(height: 5),
                  Expanded(
                    child: Consumer<OrderProvider>(
                      builder: (context, orderProv, _) {
                        if (orderProv.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(color: Color(0xFFED922A)),
                          );
                        }

                        if (orderProv.orders.isEmpty) {
                          return Center(
                            child: Text(
                              "لا توجد طلبات سابقة 📝",
                              style: GoogleFonts.cairo(
                                color: Colors.white54,
                                fontSize: 16,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          itemCount: orderProv.orders.length,
                          itemBuilder: (context, index) {
                            final order = orderProv.orders[index];
                            // Mapping backend order to UI structure
                            final mappedOrder = {
                              "id": "#ORD-${order['id']}",
                              "restaurantName": "مطعم وبروست العمودي", // Dynamic if available
                              "restaurantLogo": "assets/images/group.jpg",
                              "date": order['created_at'] != null 
                                  ? order['created_at'].toString().split('T')[0] 
                                  : "تاريخ غير متوفر",
                              "status": order['status'] ?? "مكتمل",
                              "totalPrice": "${order['total_amount'] ?? order['total'] ?? 0} ر.ي",
                              "items": "${order['items']?.length ?? 0} عناصر",
                            };
                            return _buildOrderCard(mappedOrder);
                          },
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
    );
  }

  // ===========================================================================
  // زر الرجوع الزجاجي
  // ===========================================================================
  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // This is a root-tab screen — always go to Home.
        context.go('/home');
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Center(
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // بطاقة الطلب الحالي (Active Order)
  // ===========================================================================
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          color: Colors.white70,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActiveOrderCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/order-status'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2640).withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE58B29).withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE58B29).withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Restaurant Logo Placeholder
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white12,
              ),
              child: const Icon(Icons.restaurant, color: Colors.white54),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "مطعم وبروست العمودي",
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "#100056",
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE58B29).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE58B29)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE58B29),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "قيد التجهيز",
                    style: GoogleFonts.cairo(
                      color: const Color(0xFFE58B29),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // بطاقة الطلب (Order Card)
  // ===========================================================================
  Widget _buildOrderCard(Map<String, dynamic> order) {
    bool isCompleted = order["status"] == "مكتمل";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A34).withOpacity(0.6), // خلفية زجاجية داكنة
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- الجزء العلوي: المطعم، التاريخ، الحالة ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // لوجو المطعم
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                  image: DecorationImage(
                    image: AssetImage(order["restaurantLogo"]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // بيانات المطعم والتاريخ
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order["restaurantName"],
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      order["date"],
                      style: GoogleFonts.cairo(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // شارة حالة الطلب (مكتمل / ملغي)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCompleted
                        ? Colors.green.withOpacity(0.5)
                        : Colors.red.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  order["status"],
                  style: GoogleFonts.cairo(
                    color: isCompleted ? Colors.greenAccent : Colors.redAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white.withOpacity(0.05), height: 1),
          ),

          // --- الجزء الأوسط: تفاصيل الوجبات ---
          Text(
            "عناصر الطلب:",
            style: GoogleFonts.cairo(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            order["items"],
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 13,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white.withOpacity(0.05), height: 1),
          ),

          // --- الجزء السفلي: الإجمالي وزر إعادة الطلب ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // رقم الطلب والسعر
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order["id"],
                    style: GoogleFonts.poppins(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    order["totalPrice"],
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // زر "إعادة الطلب"
              GestureDetector(
                onTap: () => _reorderItems(order["id"]),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F55E8), Color(0xFF5D12D2)],
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F55E8).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.refresh, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        "إعادة الطلب",
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
