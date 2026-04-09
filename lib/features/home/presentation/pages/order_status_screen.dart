import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/custom_background.dart';
import '../../../../core/widgets/global_exit_wrapper.dart';
import '../../../../providers/cart_provider.dart';

class OrderStatusScreen extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const OrderStatusScreen({super.key, required this.orderData});

  @override
  Widget build(BuildContext context) {
    return GlobalExitWrapper(
      child: Scaffold(
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: CustomBackground(
            child: SafeArea(
              child: Column(
                children: [
                  _buildAppBar(context),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildHeader(
                            orderData['orderId']?.toString() ?? '#------',
                          ),
                          const SizedBox(height: 25),
                          _buildSectionTitle("معلومات عامة"),
                          _buildGeneralInfoCard(orderData),
                          const SizedBox(height: 20),
                          _buildSectionTitle("معلومات العنصر"),
                          _buildItemInfoCard(orderData),
                          const SizedBox(height: 20),
                          _buildSectionTitle("تفاصيل رجل التسليم"),
                          _buildDeliveryGuyCard(),
                          const SizedBox(height: 20),
                          _buildSectionTitle("تفاصيل التسليم"),
                          _buildDeliveryDetailsCard(),
                          const SizedBox(height: 20),
                          _buildSectionTitle("تفاصيل المطعم"),
                          _buildRestaurantDetailsCard(),
                          const SizedBox(height: 20),
                          _buildSectionTitle("طريقة الدفع"),
                          _buildPaymentMethodCard(),
                          const SizedBox(height: 20),
                          _buildSectionTitle("ملخص الطلب"),
                          _buildOrderSummaryCard(orderData),
                          const SizedBox(height: 20),
                          _buildSupportMessageButton(),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomAction(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // App Bar
  // ===========================================================================
  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.go('/home'),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Text(
            "تفاصيل الطلب",
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 40), // For balance
        ],
      ),
    );
  }

  // ===========================================================================
  // Helper Methods
  // ===========================================================================
  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2640).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 5),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          title,
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, dynamic value, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14),
          ),
          if (trailing != null)
            trailing
          else if (value is String)
            Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            value,
        ],
      ),
    );
  }

  // ===========================================================================
  // Sections
  // ===========================================================================
  Widget _buildHeader(String orderId) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFE58B29).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
            const Icon(Icons.room_service, size: 70, color: Color(0xFFE58B29)),
          ],
        ),
        const SizedBox(height: 15),
        Text(
          "سيتم تسليم طعامك في الداخل",
          style: GoogleFonts.cairo(color: Colors.white54, fontSize: 14),
        ),
        const SizedBox(height: 5),
        Text(
          orderId,
          style: GoogleFonts.poppins(
            color: const Color(0xFFE58B29),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "5 - 1 دقيقة",
          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildGeneralInfoCard(Map<String, dynamic> orderData) {
    final String orderId = orderData['orderId']?.toString() ?? '#------';
    final List<CartItem> items =
        (orderData['items'] as List?)?.cast<CartItem>() ?? [];
    return _buildCard(
      child: Column(
        children: [
          _buildInfoRow("رقم الطلب", orderId),
          _buildInfoRow(
            "تاريخ الطلب",
            "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
            trailing: Text(
              "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}",
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
            ),
          ),
          _buildInfoRow(
            "توصيل",
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF416C).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "الدفع عند الاستلام",
                style: GoogleFonts.cairo(
                  color: const Color(0xFFFF416C),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          _buildInfoRow(
            "عدد المنتجات: ${items.length}",
            Row(
              children: [
                Text(
                  "مؤكد",
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(width: 5),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          _buildInfoRow("أدوات المائدة:", "لا"),
        ],
      ),
    );
  }

  Widget _buildItemInfoCard(Map<String, dynamic> orderData) {
    final List<CartItem> items =
        (orderData['items'] as List?)?.cast<CartItem>() ?? [];

    if (items.isEmpty) {
      return _buildCard(
        child: Center(
          child: Text(
            "لا توجد وجبات",
            style: GoogleFonts.cairo(color: Colors.white54, fontSize: 14),
          ),
        ),
      );
    }

    return _buildCard(
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Item image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    item.imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.fastfood,
                        color: Colors.orangeAccent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "كمية: ${item.quantity}",
                            style: GoogleFonts.cairo(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                "${(item.price * item.quantity).toStringAsFixed(0)}",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                " ر.ي",
                                style: GoogleFonts.cairo(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDeliveryGuyCard() {
    return _buildCard(
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white12,
            child: Icon(Icons.person, color: Colors.white54),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "فهمي لبيب",
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "103 فوه",
                  style: GoogleFonts.cairo(color: Colors.white54, fontSize: 12),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 14),
                    const Icon(Icons.star, color: Colors.orange, size: 14),
                    const Icon(Icons.star, color: Colors.orange, size: 14),
                    const Icon(Icons.star, color: Colors.orange, size: 14),
                    const Icon(Icons.star_half, color: Colors.orange, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      "(0)",
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE58B29).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: Color(0xFFE58B29),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F55E8).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phone,
                  color: Color(0xFF0F55E8),
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryDetailsCard() {
    return _buildCard(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F55E8).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.store,
                  color: Color(0xFF0F55E8),
                  size: 18,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "من المتجر",
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "فوة المتضررين تحت فندق تاج المكلا",
                      style: GoogleFonts.cairo(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 17, top: 5, bottom: 5),
            child: Container(height: 20, width: 1, color: Colors.white24),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF416C).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xFFFF416C),
                  size: 18,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ل",
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "G5M6+2P7, Al Mukalla, Yemen",
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantDetailsCard() {
    return _buildCard(
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(10),
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
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "فوة المتضررين تحت فندق تاج المكلا",
                  style: GoogleFonts.cairo(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE58B29).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              color: Color(0xFFE58B29),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    return _buildCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.money, color: Colors.greenAccent, size: 24),
              const SizedBox(width: 10),
              Text(
                "نقدي",
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard(Map<String, dynamic> orderData) {
    final double subtotal = (orderData['subtotal'] as num?)?.toDouble() ?? 0.0;
    final double deliveryFee =
        (orderData['deliveryFee'] as num?)?.toDouble() ?? 500.0;
    final double grandTotal =
        (orderData['total'] as num?)?.toDouble() ?? subtotal + deliveryFee;

    return _buildCard(
      child: Column(
        children: [
          _buildSummaryRow("سعر السلعة", "${subtotal.toInt()}"),
          _buildSummaryRow("إضافات", "0"),
          Divider(color: Colors.white.withOpacity(0.1), height: 20),
          _buildSummaryRow("المجموع الفرعي", "${subtotal.toInt()}"),
          _buildSummaryRow("تخفيض", "0", isNegative: true),
          _buildSummaryRow("ضريبة القيمة المضافة/الضريبة", "0"),
          _buildSummaryRow("رسوم التوصيل", "${deliveryFee.toInt()}"),
          Divider(color: Colors.white.withOpacity(0.1), height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "المبلغ الإجمالي",
                style: GoogleFonts.cairo(
                  color: const Color(0xFFFF416C),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${grandTotal.toInt()}",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFFF416C),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2.0),
                    child: Text(
                      "ر.ي",
                      style: GoogleFonts.cairo(
                        color: const Color(0xFFFF416C),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String title,
    String value, {
    bool isFree = false,
    bool isNegative = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13),
          ),
          if (isFree)
            Text(
              "حر",
              style: GoogleFonts.cairo(
                color: const Color(0xFFFF416C),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            Row(
              children: [
                if (isNegative)
                  Text(
                    "- ",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                Text(
                  value,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                ),
                Text(
                  " ر.ي",
                  style: GoogleFonts.cairo(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSupportMessageButton() {
    return Center(
      child: TextButton.icon(
        onPressed: () {},
        icon: const Icon(
          Icons.headset_mic_outlined,
          color: Color(0xFF0F55E8),
          size: 20,
        ),
        label: Text(
          "رسالة إلى Quiek",
          style: GoogleFonts.cairo(
            color: const Color(0xFF0F55E8),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 15,
      ).copyWith(bottom: 25),
      decoration: BoxDecoration(
        color: const Color(0xFF140C36).withOpacity(0.95),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: InkWell(
        onTap: () => context.push('/order-tracking', extra: orderData),
        child: Container(
          height: 55,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFD32F2F),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: Text(
              "تابع الطلب",
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
