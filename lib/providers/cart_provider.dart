import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/api/dio_client.dart';
import '../core/api/endpoints.dart';

class CartItem {
  final String id;
  final String mealId;
  final String? offerId;
  final int? variantId;
  final String? variantName;
  final String type;
  final List<dynamic>? includedMeals;
  final String name;
  final double price;
  final double? originalPrice;
  final String imageUrl;
  int quantity;
  final List<String> addons;
  final bool isRestaurantOpen;
  final double restaurantLat;
  final double restaurantLng;
  final String restaurantId;
  final String restaurantName;
  final String restaurantAddress;

  CartItem({
    this.id = '',
    required this.mealId,
    this.offerId,
    this.variantId,
    this.variantName,
    this.type = 'meal',
    this.includedMeals,
    required this.name,
    required this.price,
    this.originalPrice,
    required this.imageUrl,
    this.quantity = 1,
    this.addons = const [],
    this.isRestaurantOpen = true,
    this.restaurantLat = 0.0,
    this.restaurantLng = 0.0,
    this.restaurantId = '',
    this.restaurantName = '',
    this.restaurantAddress = '',
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    var restaurantData = json['meal']?['restaurant'] ?? json['restaurant'];
    bool isRestOpen = true; // Default to true if missing (Safety Net)
    double restLat = 0.0;
    double restLng = 0.0;
    String restId = '';
    String restName = '';
    String restAddress = '';

    if (restaurantData != null) {
      isRestOpen =
          restaurantData['is_open'] == true ||
          restaurantData['is_open'] == 1 ||
          restaurantData['is_open'] == '1' ||
          restaurantData['status']?.toString().toLowerCase() == 'open';

      restLat =
          double.tryParse(
            restaurantData['latitude']?.toString() ??
                restaurantData['lat']?.toString() ??
                '0',
          ) ??
          0.0;
      restLng =
          double.tryParse(
            restaurantData['longitude']?.toString() ??
                restaurantData['lng']?.toString() ??
                '0',
          ) ??
          0.0;
      restId = restaurantData['id']?.toString() ?? '';
      restName = restaurantData['name']?.toString() ?? '';
      restAddress = restaurantData['address']?.toString() ?? '';
    }

    final double basePrice =
        double.tryParse(
          json['price']?.toString() ??
              json['meal']?['price']?.toString() ??
              json['subtotal']?.toString() ??
              '0',
        ) ??
        0.0;

    // Parse discount properties safely
    final double? priceAfterDiscount = double.tryParse(
      json['price_after_discount']?.toString() ??
          json['meal']?['price_after_discount']?.toString() ??
          '',
    );

    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    final DateTime? discountStart = parseDateTime(
      json['discount_start'] ?? json['meal']?['discount_start'],
    );
    final DateTime? discountEnd = parseDateTime(
      json['discount_end'] ?? json['meal']?['discount_end'],
    );

    final now = DateTime.now();
    final bool isPromoActive =
        priceAfterDiscount != null &&
        priceAfterDiscount > 0 &&
        priceAfterDiscount < basePrice &&
        (discountStart == null || discountStart.isBefore(now)) &&
        (discountEnd == null || discountEnd.isAfter(now));

    final double effectivePrice = isPromoActive
        ? priceAfterDiscount
        : basePrice;
    final double? originalPrice = isPromoActive ? basePrice : null;

    final String itemType = json['type']?.toString() ?? 'meal';
    final String? parsedOfferId = json['offer_id']?.toString() ?? json['offer']?['id']?.toString();
    final int? parsedVariantId = json['variant_id'] != null ? int.tryParse(json['variant_id'].toString()) : null;
    final String? parsedVariantName = json['variant_name']?.toString() ?? json['variant']?['name']?.toString();
    
    List<dynamic>? parsedMeals;
    final rawMeals = json['included_meals'] ?? json['meals'] ?? json['offer']?['meals'] ?? json['offer']?['included_meals'];
    if (rawMeals is List) {
      parsedMeals = rawMeals;
    } else if (rawMeals is String && rawMeals.isNotEmpty) {
      try {
        final parsed = jsonDecode(rawMeals);
        if (parsed is List) {
          parsedMeals = parsed;
        }
      } catch (_) {}
    }

    final String parsedName = json['offer']?['title'] ??
        json['offer']?['name'] ??
        json['meal']?['name'] ??
        json['name'] ??
        json['title'] ??
        '';

    final String parsedImageUrl = json['offer']?['image_url'] ??
        json['offer']?['image'] ??
        json['meal']?['image_url'] ??
        json['meal']?['image'] ??
        json['image_url'] ??
        json['image'] ??
        '';

    return CartItem(
      id: json['id']?.toString() ?? '',
      mealId:
          json['meal_id']?.toString() ?? json['meal']?['id']?.toString() ?? '',
      offerId: parsedOfferId,
      variantId: parsedVariantId,
      variantName: parsedVariantName,
      type: itemType,
      includedMeals: parsedMeals,
      name: parsedName,
      price: effectivePrice,
      originalPrice: originalPrice,
      imageUrl: parsedImageUrl,
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      addons:
          (json['addons'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      isRestaurantOpen: isRestOpen,
      restaurantLat: restLat,
      restaurantLng: restLng,
      restaurantId: restId,
      restaurantName: restName,
      restaurantAddress: restAddress,
    );
  }
}

class CartProvider extends ChangeNotifier {
  final Dio _dio = DioClient().dio;

  List<CartItem> _items = [];
  double _totalAmount = 0.0;
  bool isLoading = false;

  String? _appliedCouponCode;
  double _discountAmount = 0.0;
  String? _couponDiscountType;
  double _couponDiscountValue = 0.0;

  String? get appliedCouponCode => _appliedCouponCode;
  double get discountAmount => _discountAmount;

  // Track loading state for specific meals to avoid global loading flicker
  final Set<String> _loadingItemIds = {};

  List<Map<String, dynamic>>? _cachedRestaurants;

  void setCachedRestaurants(List<Map<String, dynamic>> restaurants) {
    _cachedRestaurants = restaurants;
  }

  List<CartItem> get items => _items;
  double get totalPrice => _totalAmount;

  bool isItemLoading(String mealId, {int? variantId}) {
    final trackId = variantId != null ? '${mealId}_$variantId' : mealId;
    return _loadingItemIds.contains(trackId);
  }

  CartItem? getItemByMealId(String mealId, {int? variantId}) {
    try {
      return _items.firstWhere((item) => item.mealId == mealId && item.variantId == variantId);
    } catch (_) {
      return null;
    }
  }

  int getQuantityByMealId(String mealId, {int? variantId}) {
    return getItemByMealId(mealId, variantId: variantId)?.quantity ?? 0;
  }

  Future<void> fetchCart({List<Map<String, dynamic>>? allRestaurants}) async {
    if (allRestaurants != null) {
      _cachedRestaurants = allRestaurants;
    }

    isLoading = true;
    notifyListeners();

    try {
      final response = await _dio.get(Endpoints.getCart);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final cartData = data['data'] ?? data['cart'] ?? data;

        final cartItems =
            cartData['cart_items'] ?? cartData['items'] ?? data['items'] ?? [];

        _items = (cartItems as List).map((item) {
          final cartItem = CartItem.fromJson(item);
          String mealName = cartItem.name;
          String mealImage = cartItem.imageUrl;
          double itemPrice = cartItem.price;
          double? originalPrice = cartItem.originalPrice;

          if (cartItem.type != 'combo_offer' && _cachedRestaurants != null) {
            final String mealId = cartItem.mealId;
            for (var r in _cachedRestaurants!) {
              for (var m in (r['menu'] ?? [])) {
                if (m['id'].toString() == mealId ||
                    m['name'].toString() == mealId) {
                  mealName = mealName.isEmpty
                      ? (m['name'] ?? mealName)
                      : mealName;
                  mealImage = mealImage.isEmpty
                      ? (m['imageUrl'] ?? mealImage)
                      : mealImage;

                  final double basePrice = m['price'] != null
                      ? double.tryParse(m['price'].toString()) ?? cartItem.price
                      : cartItem.price;
                  final double? priceAfterDiscount =
                      m['price_after_discount'] != null
                      ? double.tryParse(m['price_after_discount'].toString())
                      : null;

                  DateTime? parseDateTime(dynamic value) {
                    if (value == null) return null;
                    try {
                      return DateTime.parse(value.toString());
                    } catch (_) {
                      return null;
                    }
                  }

                  final DateTime? discountStart = parseDateTime(
                    m['discount_start'],
                  );
                  final DateTime? discountEnd = parseDateTime(
                    m['discount_end'],
                  );

                  final now = DateTime.now();
                  final bool isPromoActive =
                      priceAfterDiscount != null &&
                      priceAfterDiscount > 0 &&
                      priceAfterDiscount < basePrice &&
                      (discountStart == null || discountStart.isBefore(now)) &&
                      (discountEnd == null || discountEnd.isAfter(now));

                  if (isPromoActive) {
                    itemPrice = priceAfterDiscount;
                    originalPrice = basePrice;
                  }
                  break;
                }
              }
            }
          }

          return CartItem(
            id: cartItem.id,
            mealId: cartItem.mealId,
            offerId: cartItem.offerId,
            variantId: cartItem.variantId,
            variantName: cartItem.variantName,
            type: cartItem.type,
            includedMeals: cartItem.includedMeals,
            quantity: cartItem.quantity,
            price: itemPrice,
            originalPrice: originalPrice,
            addons: cartItem.addons,
            name: mealName,
            imageUrl: mealImage,
            isRestaurantOpen: cartItem.isRestaurantOpen,
            restaurantLat: cartItem.restaurantLat,
            restaurantLng: cartItem.restaurantLng,
            restaurantId: cartItem.restaurantId,
          );
        }).toList();

        _totalAmount = _items.fold(
          0.0,
          (sum, item) => sum + (item.price * item.quantity),
        );
        if (_items.isEmpty) {
          _appliedCouponCode = null;
          _discountAmount = 0.0;
          _couponDiscountType = null;
          _couponDiscountValue = 0.0;
        } else {
          _recalculateDiscount();
        }
      }
    } on DioException catch (e) {
      debugPrint('API Error in fetchCart: $e');
    } catch (e) {
      debugPrint('API Error in fetchCart: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Map<String, dynamic>? _restaurant;
  Map<String, dynamic>? get restaurant => _restaurant;

  Future<void> addItem(CartItem item, {Map<String, dynamic>? restaurant}) async {
    if (restaurant != null) {
      final currentRestId = _restaurant?['id']?.toString() ?? (_items.isNotEmpty ? _items.first.restaurantId : null);
      if (_items.isEmpty) {
        _restaurant = restaurant;
      } else if (currentRestId != null && currentRestId.isNotEmpty && currentRestId != restaurant['id'].toString()) {
        throw Exception('DIFFERENT_RESTAURANT');
      }
    }

    final String trackId = item.type == 'combo_offer' 
        ? (item.offerId ?? item.id) 
        : (item.variantId != null ? '${item.mealId}_${item.variantId}' : item.mealId);
    _loadingItemIds.add(trackId);
    notifyListeners();

    try {
      final data = item.type == 'combo_offer' 
          ? {"offer_id": item.offerId, "quantity": item.quantity}
          : {
              "meal_id": item.mealId, 
              "quantity": item.quantity,
              if (item.variantId != null) "variant_id": item.variantId
            };

      await _dio.post(
        Endpoints.addToCart,
        data: data,
      );
      await fetchCart();
    } on DioException catch (e) {
      debugPrint('API Error in addItem: $e');
      throw Exception(e.response?.data['message'] ?? e.message);
    } catch (e) {
      debugPrint('API Error in addItem: $e');
      throw Exception(e.toString());
    } finally {
      _loadingItemIds.remove(trackId);
      notifyListeners();
    }
  }

  Future<void> removeItem(String id) async {
    final item = _items.firstWhere(
      (element) => element.id == id,
      orElse: () => CartItem(mealId: '', name: '', price: 0, imageUrl: ''),
    );
    if (item.mealId.isNotEmpty) _loadingItemIds.add(item.mealId);
    notifyListeners();

    try {
      await _dio.delete('${Endpoints.removeFromCart}/$id');
      await fetchCart();
    } on DioException catch (e) {
      debugPrint('API Error in removeItem: $e');
    } catch (e) {
      debugPrint('API Error in removeItem: $e');
    } finally {
      if (item.mealId.isNotEmpty) _loadingItemIds.remove(item.mealId);
      notifyListeners();
    }
  }

  Future<void> incrementQuantity(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      final trackId = _items[index].type == 'combo_offer' 
          ? (_items[index].offerId ?? id) 
          : (_items[index].variantId != null ? '${_items[index].mealId}_${_items[index].variantId}' : _items[index].mealId);
      final newQuantity = _items[index].quantity + 1;
      await _updateItemQuantity(id, trackId, newQuantity);
    }
  }

  Future<void> decrementQuantity(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      final trackId = _items[index].type == 'combo_offer' 
          ? (_items[index].offerId ?? id) 
          : (_items[index].variantId != null ? '${_items[index].mealId}_${_items[index].variantId}' : _items[index].mealId);
      final newQuantity = _items[index].quantity - 1;
      if (newQuantity > 0) {
        await _updateItemQuantity(id, trackId, newQuantity);
      } else {
        await removeItem(id);
      }
    }
  }

  Future<void> _updateItemQuantity(
    String id,
    String trackId,
    int quantity,
  ) async {
    if (trackId.isNotEmpty) _loadingItemIds.add(trackId);
    notifyListeners();

    try {
      await _dio.put(
        '${Endpoints.updateCartItem}/$id',
        data: {"quantity": quantity},
      );
      await fetchCart();
    } on DioException catch (e) {
      debugPrint('API Error in _updateItemQuantity: $e');
    } catch (e) {
      debugPrint('API Error in _updateItemQuantity: $e');
    } finally {
      if (trackId.isNotEmpty) _loadingItemIds.remove(trackId);
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    isLoading = true;
    notifyListeners();

    try {
      await _dio.delete(Endpoints.clearCart);
      await fetchCart();
    } on DioException catch (e) {
      debugPrint('API Error in clearCart: $e');
    } catch (e) {
      debugPrint('API Error in clearCart: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _recalculateDiscount() {
    if (_appliedCouponCode == null) {
      _discountAmount = 0.0;
      return;
    }
    if (_couponDiscountType == 'percentage' || _couponDiscountType == 'percent') {
      _discountAmount = _totalAmount * (_couponDiscountValue / 100);
    } else {
      _discountAmount = _couponDiscountValue;
    }
  }

  Future<(bool, String)> applyCoupon(String code) async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.post(
        Endpoints.applyCoupon,
        data: {
          "code": code,
          "subtotal": _totalAmount,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final couponData = data['data'] ?? data['coupon'] ?? data;
        
        final type = couponData['discount_type']?.toString().toLowerCase() ?? 
                     couponData['type']?.toString().toLowerCase();
        final valNum = couponData['discount_value'] ?? couponData['value'] ?? couponData['discount'];
        final double val = double.tryParse(valNum?.toString() ?? '0') ?? 0.0;

        _appliedCouponCode = code;
        _couponDiscountType = type;
        _couponDiscountValue = val;
        
        _recalculateDiscount();
        notifyListeners();
        return (true, data['message']?.toString() ?? 'تم تطبيق الكوبون بنجاح');
      }
      return (false, 'فشل تطبيق الكوبون');
    } on DioException catch (e) {
      debugPrint('API Error in applyCoupon: $e');
      final msg = e.response?.data?['message']?.toString() ?? e.message ?? 'حدث خطأ أثناء تطبيق الكوبون';
      return (false, msg);
    } catch (e) {
      debugPrint('Error in applyCoupon: $e');
      return (false, e.toString());
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void removeCoupon() {
    _appliedCouponCode = null;
    _discountAmount = 0.0;
    _couponDiscountType = null;
    _couponDiscountValue = 0.0;
    notifyListeners();
  }
}
