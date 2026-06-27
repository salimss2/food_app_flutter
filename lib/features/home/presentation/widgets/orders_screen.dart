import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/custom_background.dart';
import 'package:provider/provider.dart';
import '../../../../providers/order_provider.dart';
import '../../../../providers/cart_provider.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/api/endpoints.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<dynamic> _currentOrders = [];
  List<dynamic> _pastOrders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final response = await DioClient().dio.get(Endpoints.orders);
      if (response.statusCode == 200 && response.data['data'] != null) {
        final orders = response.data['data'] as List;
        if (mounted) {
          setState(() {
            _currentOrders = orders.where((o) {
              final status = o['status']?.toString().toLowerCase() ?? '';
              return status == 'pending' ||
                  status == 'preparing' ||
                  status == 'out_for_delivery' ||
                  status == 'pending_driver_acceptance' ||
                  status == 'driver_assigned';
            }).toList();

            _pastOrders = orders.where((o) {
              final status = o['status']?.toString().toLowerCase() ?? '';
              return status == 'delivered' ||
                  status == 'cancelled' ||
                  status == 'completed';
            }).toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = "Failed to load orders";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Error loading orders";
          _isLoading = false;
        });
      }
    }
  }

  // دالة إضافة الطلب للسلة
  Future<void> _reorderItems(Map<String, dynamic> rawOrder) async {
    final cartProvider = context.read<CartProvider>();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'order_items_added_success'.tr(
            namedArgs: {'orderId': "#ORD-${rawOrder['id']}"},
          ),
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0F55E8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      await cartProvider.clearCart();
      final items = rawOrder['items'] as List<dynamic>? ?? [];
      for (var item in items) {
        final cartItem = CartItem(
          mealId: item['meal_id']?.toString() ?? item['offer_id']?.toString() ?? item['id']?.toString() ?? '',
          name:
              item['meal_name'] ?? item['meal']?['name'] ?? item['offer']?['title'] ?? item['name'] ?? 'عنصر غير معروف',
          price:
              double.tryParse(
                item['price']?.toString() ??
                    item['meal']?['price']?.toString() ??
                    item['offer']?['price']?.toString() ??
                    '0',
              ) ??
              0.0,
          imageUrl:
              item['image_url'] ??
              item['meal']?['image_url'] ??
              item['offer']?['image_url'] ??
              item['image'] ??
              '',
          quantity: int.tryParse(item['quantity']?.toString() ?? '1') ?? 1,
        );
        await cartProvider.addItem(cartItem);
      }
      if (mounted) {
        context.push('/cart');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error reordering".tr(), style: GoogleFonts.cairo()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Never allow the default system pop on this root-tab screen.
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (didPop)
          return; // Already handled — shouldn't happen with canPop:false
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
                          "my_orders_title".tr(),
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

                  // --- 2 & 3. الطلبات الحالية والسابقة في قائمة واحدة قابلة للتمرير ---
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFED922A),
                            ),
                          )
                        : _errorMessage != null
                        ? Center(
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.cairo(color: Colors.red),
                            ),
                          )
                        : ListView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 30),
                            children: [
                              // الطلبات الحالية
                              if (_currentOrders.isNotEmpty) ...[
                                _buildSectionTitle("current_order_title".tr()),
                                const SizedBox(height: 10),
                                ..._currentOrders.map((order) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: _buildActiveOrderCard(
                                      context,
                                      order,
                                    ),
                                  );
                                }).toList(),
                                const SizedBox(height: 20),
                              ],

                              // الطلبات السابقة
                              _buildSectionTitle("previous_orders_title".tr()),
                              const SizedBox(height: 10),
                              if (_pastOrders.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 40,
                                    ),
                                    child: Text(
                                      "no_previous_orders".tr(),
                                      style: GoogleFonts.cairo(
                                        color: Colors.white54,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ..._pastOrders.map((order) {
                                  final mappedOrder = {
                                    "id": "#ORD-${order['id']}",
                                    "restaurantName":
                                        order['restaurant']?['name'] ??
                                        "dummy_restaurant_4".tr(),
                                    "restaurantLogo":
                                        order['restaurant']?['image_url'],
                                    "date": order['created_at'] != null
                                        ? order['created_at'].toString().split(
                                            'T',
                                          )[0]
                                        : "date_not_available".tr(),
                                    "status": order['status'] ?? "completed",
                                    "totalPrice":
                                        "${order['total_amount'] ?? order['total'] ?? 0} " +
                                        "currency".tr(),
                                    "items":
                                        (order['items'] as List?)
                                            ?.map(
                                              (i) =>
                                                  "${i['quantity']}x ${i['meal_name'] ?? i['meal']?['name'] ?? i['offer']?['title'] ?? 'عنصر غير معروف'}",
                                            )
                                            .join(", ") ??
                                        "",
                                    "rawOrder": order,
                                  };
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: _buildOrderCard(mappedOrder),
                                  );
                                }).toList(),
                            ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          color: isDark ? Colors.white70 : Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActiveOrderCard(
    BuildContext context,
    Map<String, dynamic> order,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = (order['status'] ?? "pending").toString();
    final restaurantName =
        order['restaurant']?['name'] ?? "dummy_restaurant_4".tr();
    final orderId = "#ORD-${order['id']}";
    final restaurantLogo = order['restaurant']?['image_url'];
    final totalPrice =
        "${order['total_amount'] ?? order['total'] ?? 0} ${"currency".tr()}";
    final date = order['created_at'] != null
        ? order['created_at'].toString().split('T')[0]
        : "date_not_available".tr();
    final itemsList =
        (order['items'] as List?)
            ?.map(
              (i) =>
                  "${i['quantity']}x ${i['meal_name'] ?? i['meal']?['name'] ?? i['offer']?['title'] ?? 'عنصر غير معروف'}",
            )
            .join(", ") ??
        "";

    return GestureDetector(
      onTap: () => context.push('/order-status', extra: order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2A2640).withOpacity(0.5)
                    : Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFE58B29).withOpacity(0.5),
                ),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(0xFFE58B29).withOpacity(0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Restaurant Logo
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? Colors.white12 : Colors.black12,
                          image: restaurantLogo != null
                              ? DecorationImage(
                                  image: NetworkImage(restaurantLogo),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: restaurantLogo == null
                            ? Icon(
                                Icons.restaurant,
                                color: isDark ? Colors.white54 : Colors.black54,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              restaurantName,
                              style: GoogleFonts.cairo(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              date,
                              style: GoogleFonts.cairo(
                                color: isDark ? Colors.white54 : Colors.black54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFFE58B29).withOpacity(0.2)
                              : const Color(0xFFE58B29).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE58B29)),
                        ),
                        child: Text(
                          status.tr(),
                          style: GoogleFonts.cairo(
                            color: const Color(0xFFE58B29),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.05),
                      height: 1,
                    ),
                  ),

                  Text(
                    "order_items_label".tr(),
                    style: GoogleFonts.cairo(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    itemsList,
                    style: GoogleFonts.cairo(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.05),
                      height: 1,
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            orderId,
                            style: GoogleFonts.poppins(
                              color: isDark ? Colors.white38 : Colors.black38,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            totalPrice,
                            style: GoogleFonts.poppins(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F55E8).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "view_details".tr(),
                          style: GoogleFonts.cairo(
                            color: const Color(0xFF0F55E8),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
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
    );
  }

  // ===========================================================================
  // بطاقة الطلب (Order Card)
  // ===========================================================================
  Widget _buildOrderCard(Map<String, dynamic> order) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isCompleted =
        order["status"] == "completed" || order["status"] == "delivered";

    return GestureDetector(
      onTap: () => context.push('/order-status', extra: order["rawOrder"]),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E1A34).withOpacity(0.5)
                    : Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.05),
                ),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
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
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.1),
                          ),
                          color: isDark ? Colors.white12 : Colors.black12,
                          image:
                              order["restaurantLogo"] != null &&
                                  order["restaurantLogo"].toString().startsWith(
                                    'http',
                                  )
                              ? DecorationImage(
                                  image: NetworkImage(order["restaurantLogo"]),
                                  fit: BoxFit.cover,
                                )
                              : const DecorationImage(
                                  image: AssetImage('assets/images/group.jpg'),
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
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              order["date"],
                              style: GoogleFonts.cairo(
                                color: isDark ? Colors.white54 : Colors.black54,
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
                              ? (isDark
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.green.withOpacity(0.1))
                              : (isDark
                                    ? Colors.red.withOpacity(0.2)
                                    : Colors.red.withOpacity(0.1)),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCompleted
                                ? Colors.green.withOpacity(0.5)
                                : Colors.red.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          order["status"].toString().tr(),
                          style: GoogleFonts.cairo(
                            color: isCompleted
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.05),
                      height: 1,
                    ),
                  ),

                  // --- الجزء الأوسط: تفاصيل الوجبات ---
                  Text(
                    "order_items_label".tr(),
                    style: GoogleFonts.cairo(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order["items"],
                    style: GoogleFonts.cairo(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.05),
                      height: 1,
                    ),
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
                              color: isDark ? Colors.white38 : Colors.black38,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            order["totalPrice"],
                            style: GoogleFonts.poppins(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      // زر "إعادة الطلب"
                      GestureDetector(
                        onTap: () => _reorderItems(order["rawOrder"]),
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
                              const Icon(
                                Icons.refresh,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "reorder".tr(),
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
            ),
          ),
        ),
      ),
    );
  }
}
