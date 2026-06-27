import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Consumer, Provider;
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

import '../../../../core/widgets/custom_background.dart';
import '../../../../providers/cart_provider.dart';

import '../../../../providers/restaurant_provider.dart';
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final asyncRestaurants = ref.read(restaurantProvider);

      List<Map<String, dynamic>> mappedRestaurants = [];

      asyncRestaurants.whenData((restaurants) {
        for (var r in restaurants) {
          mappedRestaurants.add({
            'id': r.id,
            'name': r.name,
            'menu': [
              ...r.meals.map(
                (m) => {
                  'id': m.id, 
                  'name': m.name, 
                  'imageUrl': m.imageUrl,
                  'price': m.price,
                  'price_after_discount': m.priceAfterDiscount,
                  'discount_type': m.discountType,
                  'discount_value': m.discountValue,
                  'discount_start': m.discountStart?.toIso8601String(),
                  'discount_end': m.discountEnd?.toIso8601String(),
                },
              ),
              ...r.menus
                  .expand((menu) => menu.meals)
                  .map(
                    (m) => {
                      'id': m.id, 
                      'name': m.name, 
                      'imageUrl': m.imageUrl,
                      'price': m.price,
                      'price_after_discount': m.priceAfterDiscount,
                      'discount_type': m.discountType,
                      'discount_value': m.discountValue,
                      'discount_start': m.discountStart?.toIso8601String(),
                      'discount_end': m.discountEnd?.toIso8601String(),
                    },
                  ),
            ],
          });
        }
      });

      context.read<CartProvider>().fetchCart(allRestaurants: mappedRestaurants);
    });
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
                // 1. AppBar
                _buildAppBar(context),

                // 2. Body (List and Summary)
                Expanded(
                  child: Consumer<CartProvider>(
                    builder: (context, cart, _) {
                      if (cart.isLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFED922A),
                          ),
                        );
                      }

                      if (cart.items.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.shopping_cart_outlined,
                                color: Colors.white24,
                                size: 80,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "cart_empty".tr(),
                                style: GoogleFonts.cairo(
                                  color: Colors.white54,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "cart_empty_subtitle".tr(),
                                style: GoogleFonts.cairo(
                                  color: Colors.white38,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: [
                          // 3. Cart Items List
                          Expanded(
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              itemCount: cart.items.length,
                              itemBuilder: (context, index) {
                                final item = cart.items[index];
                                return _buildCartItemTile(context, item, cart);
                              },
                            ),
                          ),

                          // 4. Order Summary Section
                          _buildOrderSummary(context, cart),
                        ],
                      );
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
  // AppBar
  // ===========================================================================
  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          GestureDetector(
            onTap: () => context.pop(),
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
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Title
          Text(
            "cart_title".tr(),
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Clear Cart Button
          GestureDetector(
            onTap: () {
              Provider.of<CartProvider>(context, listen: false).clearCart();
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5555).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF5555).withOpacity(0.5),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.delete_outline,
                      color: Color(0xFFFF5555),
                      size: 20,
                    ),
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
  // Cart Item Tile
  // ===========================================================================
  Widget _buildCartItemTile(
    BuildContext context,
    CartItem item,
    CartProvider cart,
  ) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        cart.removeItem(item.id);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFF5555).withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        child: const Icon(Icons.delete, color: Colors.white, size: 30),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2640).withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: item.imageUrl.isNotEmpty
                  ? Image.network(
                      item.imageUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 100,
                          height: 100,
                          color: Colors.white12,
                          child: const Icon(Icons.fastfood, color: Colors.white54),
                        );
                      },
                    )
                  : Container(
                      width: 100,
                      height: 100,
                      color: Colors.white12,
                      child: const Icon(Icons.fastfood, color: Colors.white54),
                    ),
            ),
            const SizedBox(width: 12),

            // Name & Price
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.variantName != null 
                                ? '${item.name} (${item.variantName})'
                                : (item.name.isNotEmpty 
                                    ? item.name 
                                    : (item.type == 'combo_offer' ? 'combo_offer'.tr() : 'meal'.tr())),
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!item.isRestaurantOpen)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.5),
                              ),
                            ),
                            child: Text(
                              "closed".tr(),
                              style: GoogleFonts.cairo(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        if (item.originalPrice != null && item.originalPrice! > item.price) ...[
                          Text(
                            "${item.originalPrice!.toStringAsFixed(0)}",
                            style: GoogleFonts.cairo(
                              color: Colors.white38,
                              fontSize: 11,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          "${item.price.toStringAsFixed(0)} ${'currency'.tr()}",
                          style: GoogleFonts.cairo(
                            color: (item.originalPrice != null && item.originalPrice! > item.price)
                                ? const Color(0xFFFF5555)
                                : Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (item.addons.isNotEmpty)
                      Text(
                        item.addons.join(" • "),
                        style: GoogleFonts.cairo(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),

            // Quantity Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () => cart.incrementQuantity(item.id),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.add, color: Colors.white, size: 18),
                      ),
                    ),
                    Text(
                      item.quantity.toString(),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => cart.decrementQuantity(item.id),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.remove,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
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

  // ===========================================================================
  // Order Summary & Checkout Button
  // ===========================================================================
  Widget _buildOrderSummary(BuildContext context, CartProvider cart) {
    const double deliveryFee = 0.0; // Dynamic fee is calculated on Checkout Screen
    final double subtotal = cart.totalPrice;
    final double grandTotal = subtotal + deliveryFee;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF140C36).withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "subtotal".tr(),
                style: GoogleFonts.cairo(color: Colors.white54, fontSize: 14),
              ),
              Text(
                "${subtotal.toStringAsFixed(0)} ${'currency'.tr()}",
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Delivery
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "delivery".tr(),
                style: GoogleFonts.cairo(color: Colors.white54, fontSize: 14),
              ),
              Text(
                "calculated_at_checkout".tr(),
                style: GoogleFonts.cairo(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Divider(color: Colors.white.withOpacity(0.1), height: 1),
          ),

          // Grand Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "grand_total".tr(),
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "${grandTotal.toStringAsFixed(0)} ${'currency'.tr()}",
                style: GoogleFonts.poppins(
                  color: const Color(0xFF0F55E8),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Action Button
          Container(
            width: double.infinity,
            height: 55,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F55E8), Color(0xFF5D12D2)],
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F55E8).withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  final closedItems = cart.items.where((item) => !item.isRestaurantOpen).toList();
                  if (closedItems.isNotEmpty) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1E1A34),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        title: Text(
                          "warning".tr(),
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: Text(
                          "restaurant_closed_error".tr(),
                          style: GoogleFonts.cairo(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              "close".tr(),
                              style: GoogleFonts.cairo(color: const Color(0xFF0F55E8)),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    context.push('/checkout');
                  }
                },
                borderRadius: BorderRadius.circular(15),
                child: Center(
                  child: Text(
                    "proceed_to_checkout".tr(),
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
