import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/custom_background.dart';
import '../../../../core/widgets/global_exit_wrapper.dart';

class OrderStatusScreen extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const OrderStatusScreen({super.key, required this.orderData});

  // ---------------------------------------------------------------------------
  // Helpers: parse the order JSON safely
  // ---------------------------------------------------------------------------

  /// Order ID as a display string e.g. "#1042"
  String get _orderId {
    final raw = orderData['id']?.toString() ?? orderData['order_id']?.toString();
    return raw != null ? '#$raw' : '#------';
  }

  /// Parsed creation date – falls back to now if the field is absent/malformed.
  DateTime get _createdAt {
    final raw = orderData['created_at']?.toString();
    if (raw == null) return DateTime.now();
    return DateTime.tryParse(raw) ?? DateTime.now();
  }

  /// Human-readable date string: "19/04/2026"
  String get _dateString {
    final d = _createdAt;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  /// Human-readable time string: "18:05"
  String get _timeString {
    final d = _createdAt;
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  /// Payment method label in Arabic.
  String get _paymentLabel {
    final raw = orderData['payment_method']?.toString();
    switch (raw) {
      case 'wallet':
        return 'محفظة إلكترونية';
      case 'balance':
        return 'رصيد الحساب';
      case 'cash':
      default:
        return 'نقدي';
    }
  }

  /// Raw items list – each element is a Map (OrderItem JSON from Laravel).
  List<Map<String, dynamic>> get _items {
    final raw = orderData['items'] ?? orderData['order_items'];
    if (raw is! List) return [];
    return raw
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  /// Restaurant name with fallback.
  String get _restaurantName {
    return orderData['restaurant']?['name']?.toString() ??
        orderData['restaurant_name']?.toString() ??
        'غير متوفر';
  }

  /// Restaurant address with fallback.
  String get _restaurantAddress {
    return orderData['restaurant']?['address']?.toString() ??
        orderData['restaurant_address']?.toString() ??
        'غير متوفر';
  }

  /// Delivery / customer address with fallback.
  String get _deliveryAddress {
    return orderData['delivery_address']?.toString() ??
        orderData['address']?.toString() ??
        'غير متوفر';
  }

  /// Driver map, or null if not yet assigned.
  Map<String, dynamic>? get _driver {
    final d = orderData['driver'];
    if (d is Map<String, dynamic>) return d;
    return null;
  }

  /// Grand total (server field: "total").
  double get _total =>
      double.tryParse(orderData['total']?.toString() ?? '') ??
      double.tryParse(orderData['total_amount']?.toString() ?? '') ??
      0.0;

  /// Delivery fee (server field: "delivery_fee"). Defaults to 500.
  double get _deliveryFee =>
      double.tryParse(orderData['delivery_fee']?.toString() ?? '') ?? 500.0;

  /// Subtotal – use explicit field if present, else derive from total − fee.
  double get _subtotal {
    final explicit = double.tryParse(orderData['subtotal']?.toString() ?? '');
    if (explicit != null) return explicit;
    final derived = _total - _deliveryFee;
    return derived > 0 ? derived : _total;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
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
                          _buildHeader(),
                          const SizedBox(height: 25),
                          _buildSectionTitle("معلومات عامة"),
                          _buildGeneralInfoCard(),
                          const SizedBox(height: 20),
                          _buildSectionTitle("معلومات العنصر"),
                          _buildItemInfoCard(),
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
                          _buildOrderSummaryCard(),
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
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  // ===========================================================================
  // Helper Widgets
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
  // 1. Header
  // ===========================================================================
  Widget _buildHeader() {
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
        // Dynamic order ID
        Text(
          _orderId,
          style: GoogleFonts.poppins(
            color: const Color(0xFFE58B29),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "30 - 45 دقيقة",
          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14),
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. General Info Card
  // ===========================================================================
  Widget _buildGeneralInfoCard() {
    final itemCount = _items.length;

    return _buildCard(
      child: Column(
        children: [
          // Order ID
          _buildInfoRow("رقم الطلب", _orderId),

          // Date + Time
          _buildInfoRow(
            "تاريخ الطلب",
            _dateString,
            trailing: Text(
              _timeString,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
            ),
          ),

          // Payment method badge
          _buildInfoRow(
            "طريقة الدفع",
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF416C).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _paymentLabel,
                style: GoogleFonts.cairo(
                  color: const Color(0xFFFF416C),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Item count + status
          _buildInfoRow(
            "عدد المنتجات: $itemCount",
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

  // ===========================================================================
  // 3. Item Info Card — maps over JSON order items (not CartItem models)
  // ===========================================================================
  Widget _buildItemInfoCard() {
    final items = _items;

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
          // Safely extract fields from the JSON item
          final meal = item['meal'] as Map<String, dynamic>?;
          final String name =
              meal?['name']?.toString() ?? item['name']?.toString() ?? 'وجبة';
          final String? imageUrl =
              meal?['image_url']?.toString() ?? item['image_url']?.toString();
          final int quantity =
              int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;

          // Prefer item-level price (unit price), fallback to meal price
          final double unitPrice =
              double.tryParse(item['price']?.toString() ?? '') ??
              double.tryParse(meal?['price']?.toString() ?? '') ??
              0.0;
          // subtotal field from backend
          final double subtotal =
              double.tryParse(item['subtotal']?.toString() ?? '') ??
              (unitPrice * quantity);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Item image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildImageFallback(),
                        )
                      : _buildImageFallback(),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
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
                            "كمية: $quantity",
                            style: GoogleFonts.cairo(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                subtotal.toStringAsFixed(0),
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

  Widget _buildImageFallback() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.fastfood, color: Colors.orangeAccent),
    );
  }

  // ===========================================================================
  // 4. Delivery Guy Card — shows a waiting state if driver is null
  // ===========================================================================
  Widget _buildDeliveryGuyCard() {
    final driver = _driver;

    if (driver == null) {
      // New order — driver not yet assigned
      return _buildCard(
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFE58B29).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Color(0xFFE58B29),
                    strokeWidth: 2.5,
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
                    "جاري تعيين مندوب التوصيل...",
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "سيتم إعلامك عند تعيين المندوب",
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
      );
    }

    // Driver assigned — show real data
    final String driverName =
        driver['name']?.toString() ?? 'مندوب التوصيل';
    final String driverVehicle =
        driver['vehicle']?.toString() ?? driver['phone']?.toString() ?? '';
    final double driverRating =
        double.tryParse(driver['rating']?.toString() ?? '') ?? 0.0;
    final int fullStars = driverRating.floor().clamp(0, 5);
    final bool hasHalf = (driverRating - fullStars) >= 0.5;

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
                  driverName,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (driverVehicle.isNotEmpty)
                  Text(
                    driverVehicle,
                    style:
                        GoogleFonts.cairo(color: Colors.white54, fontSize: 12),
                  ),
                Row(
                  children: [
                    ...List.generate(
                      fullStars,
                      (_) => const Icon(Icons.star,
                          color: Colors.orange, size: 14),
                    ),
                    if (hasHalf)
                      const Icon(Icons.star_half,
                          color: Colors.orange, size: 14),
                    ...List.generate(
                      (5 - fullStars - (hasHalf ? 1 : 0)).clamp(0, 5),
                      (_) => const Icon(Icons.star_border,
                          color: Colors.orange, size: 14),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "(${driverRating.toStringAsFixed(1)})",
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

  // ===========================================================================
  // 5. Delivery Details Card
  // ===========================================================================
  Widget _buildDeliveryDetailsCard() {
    return _buildCard(
      child: Column(
        children: [
          // FROM: restaurant
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
                      _restaurantAddress,
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

          // TO: customer address
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
                      "إلى",
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _deliveryAddress,
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
        ],
      ),
    );
  }

  // ===========================================================================
  // 6. Restaurant Details Card
  // ===========================================================================
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
                  _restaurantName,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _restaurantAddress,
                  style:
                      GoogleFonts.cairo(color: Colors.white54, fontSize: 12),
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

  // ===========================================================================
  // 7. Payment Method Card
  // ===========================================================================
  Widget _buildPaymentMethodCard() {
    final isCash = _paymentLabel == 'نقدي';
    return _buildCard(
      child: Row(
        children: [
          Icon(
            isCash ? Icons.money : Icons.account_balance_wallet_outlined,
            color: Colors.greenAccent,
            size: 24,
          ),
          const SizedBox(width: 10),
          Text(
            _paymentLabel,
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 8. Order Summary Card
  // ===========================================================================
  Widget _buildOrderSummaryCard() {
    return _buildCard(
      child: Column(
        children: [
          _buildSummaryRow("سعر السلعة", _subtotal.toStringAsFixed(0)),
          _buildSummaryRow("إضافات", "0"),
          Divider(color: Colors.white.withOpacity(0.1), height: 20),
          _buildSummaryRow("المجموع الفرعي", _subtotal.toStringAsFixed(0)),
          _buildSummaryRow("تخفيض", "0", isNegative: true),
          _buildSummaryRow("ضريبة القيمة المضافة/الضريبة", "0"),
          _buildSummaryRow("رسوم التوصيل", _deliveryFee.toStringAsFixed(0)),
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
                    _total.toStringAsFixed(0),
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
                    style:
                        GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                  ),
                Text(
                  value,
                  style:
                      GoogleFonts.poppins(color: Colors.white, fontSize: 13),
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

  // ===========================================================================
  // Support Button
  // ===========================================================================
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

  // ===========================================================================
  // Bottom Action
  // ===========================================================================
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
