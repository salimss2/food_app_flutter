import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../models/restaurant_model.dart';
import '../../../../providers/cart_provider.dart';

class MealOptionsBottomSheet extends StatefulWidget {
  final Meal meal;

  const MealOptionsBottomSheet({Key? key, required this.meal}) : super(key: key);

  @override
  State<MealOptionsBottomSheet> createState() => _MealOptionsBottomSheetState();
}

class _MealOptionsBottomSheetState extends State<MealOptionsBottomSheet> {
  final List<MealOption> _selectedOptions = [];
  int _quantity = 1;

  double get _basePrice {
    final now = DateTime.now();
    final bool isPromoActive = widget.meal.priceAfterDiscount != null &&
        widget.meal.priceAfterDiscount! > 0 &&
        widget.meal.priceAfterDiscount! < widget.meal.price &&
        (widget.meal.discountStart == null || widget.meal.discountStart!.isBefore(now)) &&
        (widget.meal.discountEnd == null || widget.meal.discountEnd!.isAfter(now));

    return isPromoActive
        ? widget.meal.priceAfterDiscount!
        : (widget.meal.offers.isNotEmpty && widget.meal.offers.first.discountPrice != null
            ? widget.meal.offers.first.discountPrice!
            : widget.meal.price);
  }

  double get _totalPrice {
    double total = _basePrice;
    for (var option in _selectedOptions) {
      total += option.price;
    }
    return total * _quantity;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: context.locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF140C36).withOpacity(0.85) : Colors.white.withOpacity(0.9),
              border: Border(top: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.meal.name.isNotEmpty ? widget.meal.name : 'meal_placeholder'.tr(),
                              style: GoogleFonts.cairo(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "options_and_addons".tr(),
                              style: GoogleFonts.cairo(
                                color: isDark ? Colors.white54 : Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black87),
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                ),
                Divider(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
                
                // Options List
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      children: (widget.meal.options ?? []).map((option) {
                        final bool isSelected = _selectedOptions.contains(option);
                        return Theme(
                          data: ThemeData(unselectedWidgetColor: isDark ? Colors.white54 : Colors.black54),
                          child: CheckboxListTile(
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedOptions.add(option);
                                } else {
                                  _selectedOptions.remove(option);
                                }
                              });
                            },
                            activeColor: const Color(0xFF0F55E8),
                            checkColor: Colors.white,
                            title: Text(
                              option.name,
                              style: GoogleFonts.cairo(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 15,
                              ),
                            ),
                            secondary: Text(
                              option.price > 0 
                                ? "+${option.price.toStringAsFixed(0)} ${'currency'.tr()}"
                                : "free".tr(),
                              style: GoogleFonts.cairo(
                                color: option.price > 0 ? const Color(0xFFFF5555) : Colors.green,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Footer (Add to Cart button)
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1A34).withOpacity(0.9) : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Quantity selector
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.add, color: isDark ? Colors.white : Colors.black87),
                              onPressed: () => setState(() => _quantity++),
                            ),
                            Text(
                              _quantity.toString(),
                              style: GoogleFonts.poppins(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.remove, color: isDark ? Colors.white : Colors.black87),
                              onPressed: () {
                                if (_quantity > 1) setState(() => _quantity--);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      
                      // Add to Cart Button
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
                                color: const Color(0xFF0F55E8).withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
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
                                          : 'fast_food'.tr(),
                                      price: (_totalPrice / _quantity),
                                      imageUrl: widget.meal.imageUrl ??
                                          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&q=80',
                                      quantity: _quantity,
                                      selectedOptions: _selectedOptions,
                                    ),
                                  );

                                  if (mounted) {
                                    context.pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "added_to_cart_success".tr(),
                                          style: GoogleFonts.cairo(color: Colors.white),
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'failed_to_add'.tr() + ': ${e.toString()}',
                                          style: GoogleFonts.cairo(color: Colors.white),
                                        ),
                                        backgroundColor: Colors.red.shade700,
                                      ),
                                    );
                                  }
                                }
                              },
                              borderRadius: BorderRadius.circular(15),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "add".tr(),
                                      style: GoogleFonts.cairo(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "${_totalPrice.toStringAsFixed(2)} ${'currency'.tr()}",
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        height: 1.2,
                                      ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
