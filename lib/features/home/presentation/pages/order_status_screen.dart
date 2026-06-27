import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart';

import '../../../../core/widgets/custom_background.dart';
import '../../../../core/widgets/global_exit_wrapper.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

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
        return 'e_wallet'.tr();
      case 'balance':
        return 'account_balance'.tr();
      case 'cash':
      default:
        return 'cash'.tr();
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
        'not_available'.tr();
  }

  /// Restaurant address with fallback.
  String get _restaurantAddress {
    return orderData['restaurant']?['address']?.toString() ??
        orderData['restaurant_address']?.toString() ??
        'not_available'.tr();
  }

  /// Delivery / customer address with fallback.
  String get _deliveryAddress {
    return orderData['delivery_address']?.toString() ??
        orderData['address']?.toString() ??
        'not_available'.tr();
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

  /// Delivery fee (server field: "delivery_fee"). Defaults to 0.0.
  double get _deliveryFee =>
      double.tryParse(orderData['delivery_fee']?.toString() ?? '') ?? 0.0;

  /// Additions (e.g. extra items or addons).
  double get _additions =>
      double.tryParse(orderData['additions']?.toString() ?? '') ?? 0.0;

  /// Discount.
  double get _discount =>
      double.tryParse(orderData['discount']?.toString() ?? '') ?? 0.0;

  /// VAT / Tax.
  double get _vatTax =>
      double.tryParse(orderData['vat_tax']?.toString() ?? orderData['tax']?.toString() ?? '') ?? 0.0;

  /// Subtotal – use explicit field if present, else derive from total − fee.
  double get _subtotal {
    final explicit = double.tryParse(orderData['subtotal']?.toString() ?? '');
    if (explicit != null) return explicit;
    final derived = _total - _deliveryFee + _discount - _additions - _vatTax;
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
                          _buildSectionTitle("general_info".tr()),
                          _buildGeneralInfoCard(),
                          const SizedBox(height: 20),
                          _buildSectionTitle("item_info".tr()),
                          _buildItemInfoCard(context),
                          const SizedBox(height: 20),
                          _buildSectionTitle("delivery_man_details".tr()),
                          _buildDeliveryGuyCard(),
                          const SizedBox(height: 20),
                          _buildSectionTitle("delivery_details".tr()),
                          _buildDeliveryDetailsCard(),
                          const SizedBox(height: 20),
                          _buildSectionTitle("restaurant_details".tr()),
                          _buildRestaurantDetailsCard(),
                          const SizedBox(height: 20),
                          _buildSectionTitle("payment_method_label".tr()),
                          _buildPaymentMethodCard(),
                          const SizedBox(height: 20),
                          _buildSectionTitle("order_summary".tr()),
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
            "order_details_title".tr(),
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
          "food_delivered_in".tr(),
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
          "delivery_time_estimate".tr(),
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
          _buildInfoRow("order_id".tr(), _orderId),

          // Date + Time
          _buildInfoRow(
            "order_date".tr(),
            _dateString,
            trailing: Text(
              _timeString,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
            ),
          ),

          // Payment method badge
          _buildInfoRow(
            "payment_method_label".tr(),
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
            "number_of_items_label".tr(namedArgs: {'count': itemCount.toString()}),
            Row(
              children: [
                Text(
                  (orderData['status']?.toString() ?? 'pending').tr(),
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(width: 5),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: (orderData['status'] == 'completed' || orderData['status'] == 'delivered') 
                        ? Colors.green 
                        : const Color(0xFFE58B29),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),

          _buildInfoRow("cutlery".tr(), "no".tr()),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. Item Info Card — maps over JSON order items (not CartItem models)
  // ===========================================================================
  Widget _buildItemInfoCard(BuildContext context) {
    final items = _items;

    if (items.isEmpty) {
      return _buildCard(
        child: Center(
          child: Text(
            "no_meals".tr(),
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
              meal?['name']?.toString() ?? item['name']?.toString() ?? 'meal_placeholder'.tr();
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
                            context.locale.languageCode == 'ar'
                                ? "الكمية: $quantity"
                                : "Qty: $quantity",
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
                                " " + "currency".tr(),
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
                    "assigning_delivery_man".tr(),
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "notified_when_assigned".tr(),
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
        driver['name']?.toString() ?? 'delivery_man'.tr();
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
                      "from_store".tr(),
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
                      "to_label".tr(),
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
              image: orderData['restaurant']?['image_url'] != null
                  ? DecorationImage(
                      image: NetworkImage(orderData['restaurant']['image_url']),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: orderData['restaurant']?['image_url'] == null 
                ? const Icon(Icons.restaurant, color: Colors.white54)
                : null,
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
    final isCash = _paymentLabel == 'cash'.tr();
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
          _buildSummaryRow("item_price".tr(), _subtotal.toStringAsFixed(0)),
          _buildSummaryRow("additions".tr(), _additions.toStringAsFixed(0)),
          Divider(color: Colors.white.withOpacity(0.1), height: 20),
          _buildSummaryRow("subtotal".tr(), _subtotal.toStringAsFixed(0)),
          _buildSummaryRow("discount".tr(), _discount.toStringAsFixed(0), isNegative: true),
          _buildSummaryRow("vat_tax".tr(), _vatTax.toStringAsFixed(0)),
          _buildSummaryRow("delivery_fee_label".tr(), _deliveryFee.toStringAsFixed(0)),
          Divider(color: Colors.white.withOpacity(0.1), height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "grand_total".tr(),
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
                      "currency".tr(),
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
              "free".tr(),
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
                  " " + "currency".tr(),
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
          "message_to_quiek".tr(),
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
              "track_order".tr(),
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
