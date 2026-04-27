$file = "e:\Customer App\customer_app\lib\features\home\presentation\pages\restaurant_detail_screen.dart"
$lines = Get-Content $file -Encoding UTF8

# Lines before the function (1..729)
$before = $lines[0..728]

# Lines after the function (1055..end)
$after = $lines[1055..($lines.Length - 1)]

$newFunction = @'
  Widget _buildMenuItemCard(dynamic meal, int mealIndex) {
    final List<dynamic> options =
        meal['options'] ??
        (mealIndex % 3 == 0
            ? [
                {'name': 'عادي', 'price': meal['price']},
                {'name': 'شيدر', 'price': (meal['price'] ?? 0) + 500},
              ]
            : []);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      height: 110,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2640).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          // --- 1. الصورة وأيقونة المفضلة ---
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: Image.network(
                  meal['imageUrl'] ??
                      'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&q=80',
                  width: 110,
                  height: 110,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 110,
                      height: 110,
                      color: const Color(0xFF1E1A34),
                      child: const Center(
                        child: Icon(
                          Icons.fastfood,
                          color: Colors.white24,
                          size: 36,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Consumer<FavoritesProvider>(
                  builder: (context, fav, _) {
                    final mId =
                        meal['id']?.toString() ??
                        meal['name']?.toString() ??
                        '';
                    final isFav = fav.isMealFav(mId);
                    return GestureDetector(
                      onTap: () =>
                          fav.toggleMeal(Map<String, dynamic>.from(meal)),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: const Color(0xFFFF416C),
                          size: 16,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delivery_dining,
                    color: Colors.red,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),

          // --- 2. النصوص (المنتصف) ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal['name'] ?? 'وجبة',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meal['description'] ?? 'تفاصيل الوجبة غير متوفرة',
                    style: GoogleFonts.cairo(
                      color: Colors.white54,
                      fontSize: 10,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

          // --- 3. السعر والزر (اليسار) ---
          IntrinsicWidth(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${meal['price']} ر.ي",
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Consumer<CartProvider>(
                    builder: (context, cart, _) {
                      final mealId =
                          meal['id']?.toString() ??
                          meal['name']?.toString() ??
                          '';
                      final idx = cart.items.indexWhere(
                        (item) => item.id == mealId,
                      );
                      final cartItem = idx >= 0 ? cart.items[idx] : null;

                      if (options.isNotEmpty && cartItem == null) {
                        return GestureDetector(
                          onTap: () =>
                              _showOptionsBottomSheet(context, meal, options),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFED922A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'عرض الخيارات',
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }

                      if (cartItem == null) {
                        return GestureDetector(
                          onTap: () async {
                            final double price =
                                double.tryParse(
                                  (meal['price']?.toString() ?? '0')
                                      .replaceAll(RegExp(r'[^0-9.]'), ''),
                                ) ??
                                0.0;
                            try {
                              await Provider.of<CartProvider>(
                                context,
                                listen: false,
                              ).addItem(
                                CartItem(
                                  mealId: mealId,
                                  name: meal['name']?.toString() ?? 'وجبة',
                                  imageUrl:
                                      meal['imageUrl']?.toString() ??
                                      'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&q=80',
                                  price: price,
                                  quantity: 1,
                                  addons: [],
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'تمت إضافة ${meal['name']} للسلة بنجاح 🛒',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                  backgroundColor: Colors.green.shade700,
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
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
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 237, 42, 42),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'أضف للسلة',
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }

                      return Container(
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => Provider.of<CartProvider>(
                                context,
                                listen: false,
                              ).incrementQuantity(cartItem.id),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                            Text(
                              cartItem.quantity.toString(),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Provider.of<CartProvider>(
                                context,
                                listen: false,
                              ).decrementQuantity(cartItem.id),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Icon(
                                  Icons.remove,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
'@

$newLines = $newFunction -split "`n"

$result = $before + $newLines + $after
[System.IO.File]::WriteAllLines($file, $result, [System.Text.UTF8Encoding]::new($false))
Write-Host "Done! Lines written: $($result.Length)"
