import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/api/dio_client.dart';
import '../core/api/endpoints.dart';
import '../models/restaurant_model.dart';

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
  final double? unitPrice;
  final double? originalPrice;
  final String imageUrl;
  int quantity;
  final List<String> addons;
  final List<MealOption>? selectedOptions;
  final bool isRestaurantOpen;
  final double restaurantLat;
  final double restaurantLng;
  final String restaurantId;
  final String restaurantName;
  final String restaurantAddress;

  double get effectiveUnitPrice => unitPrice ?? price;
  double get totalUnitPrice => effectiveUnitPrice + (selectedOptions?.fold(0.0, (sum, option) => sum! + (option.price)) ?? 0);
  double get totalOriginalPrice => (originalPrice != null) ? originalPrice! + (selectedOptions?.fold(0.0, (sum, option) => sum! + (option.price)) ?? 0) : totalUnitPrice;

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
    this.unitPrice,
    this.originalPrice,
    required this.imageUrl,
    this.quantity = 1,
    this.addons = const [],
    this.selectedOptions,
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
    String restId = json['restaurant_id']?.toString() ?? json['meal']?['restaurant_id']?.toString() ?? '';
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
      if (restId.isEmpty) {
        restId = restaurantData['id']?.toString() ?? '';
      }
      restName = restaurantData['name']?.toString() ?? '';
      restAddress = restaurantData['address']?.toString() ?? '';
    }

    final double basePrice =
        double.tryParse(
          json['unit_price']?.toString() ??
              json['price']?.toString() ??
              json['meal']?['price']?.toString() ??
              json['subtotal']?.toString() ??
              '0',
        ) ??
        0.0;

    // Parse discount properties safely
    final double? priceAfterDiscount = double.tryParse(
      json['offer_price']?.toString() ??
          json['price_after_discount']?.toString() ??
          json['discount_price']?.toString() ??
          json['price_override']?.toString() ??
          json['meal']?['price_after_discount']?.toString() ??
          json['offer']?['offer_price']?.toString() ??
          json['offer']?['price']?.toString() ??
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

    final String itemType = json['type']?.toString() ?? 'meal';
    final String? parsedOfferId = json['offer_id']?.toString() ?? json['offer']?['id']?.toString();
    final int? parsedVariantId = json['variant_id'] != null ? int.tryParse(json['variant_id'].toString()) : null;
    final String? parsedVariantName = json['variant_name']?.toString() ?? json['variant']?['name']?.toString();

    final double effectivePrice = isPromoActive
        ? priceAfterDiscount
        : (priceAfterDiscount != null && priceAfterDiscount > 0 && (parsedOfferId != null || itemType == 'combo_offer' || itemType == 'offer')
            ? priceAfterDiscount
            : basePrice);
    final double? originalPrice = (isPromoActive || (priceAfterDiscount != null && priceAfterDiscount > 0 && priceAfterDiscount < basePrice))
        ? basePrice
        : double.tryParse(json['original_price']?.toString() ?? '');
    
    List<MealOption>? parsedSelectedOptions;
    if (json['options'] != null) {
      parsedSelectedOptions = (json['options'] as List)
          .map((e) => MealOption.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (json['selected_options'] != null) {
      parsedSelectedOptions = (json['selected_options'] as List)
          .map((e) => MealOption.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    
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
      unitPrice: effectivePrice,
      originalPrice: originalPrice,
      imageUrl: parsedImageUrl,
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      addons:
          (json['addons'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      selectedOptions: parsedSelectedOptions,
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

  // Memory cache of price overrides and original prices to ensure promotional meal prices are never lost across fetchCart
  final Map<String, double> _priceOverrides = {};
  final Map<String, double> _originalPrices = {};

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
          double itemPrice = cartItem.effectiveUnitPrice;
          double? originalPrice = cartItem.originalPrice;

          // Check if there is an explicit price override for this item
          final double? override = _priceOverrides[cartItem.id] ??
              _priceOverrides[cartItem.mealId] ??
              (cartItem.offerId != null ? _priceOverrides[cartItem.offerId!] : null);
          if (override != null && override > 0) {
            final double? orig = _originalPrices[cartItem.id] ??
                _originalPrices[cartItem.mealId] ??
                (cartItem.offerId != null ? _originalPrices[cartItem.offerId!] : null) ??
                (itemPrice > override ? itemPrice : originalPrice);
            itemPrice = override;
            originalPrice = orig;
          } else if (cartItem.type != 'combo_offer' && _cachedRestaurants != null) {
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
            unitPrice: itemPrice,
            originalPrice: originalPrice,
            addons: cartItem.addons,
            selectedOptions: cartItem.selectedOptions,
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
          (sum, item) => sum + (item.totalUnitPrice * item.quantity),
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

  Future<void> addItem(
    CartItem item, {
    Map<String, dynamic>? restaurant,
    double? priceOverride,
  }) async {
    final double effectivePrice = priceOverride ?? item.unitPrice ?? item.price;
    final double? origPrice = item.originalPrice ??
        ((priceOverride != null && priceOverride < item.price)
            ? item.price
            : null);

    if (restaurant != null) {
      final currentRestId = _restaurant?['id']?.toString() ?? (_items.isNotEmpty ? _items.first.restaurantId : null);
      if (_items.isEmpty) {
        _restaurant = restaurant;
      } else if (currentRestId != null && currentRestId.isNotEmpty && currentRestId != restaurant['id'].toString()) {
        throw Exception('DIFFERENT_RESTAURANT');
      }
    }

    String optionsHash = '';
    if (item.selectedOptions != null && item.selectedOptions!.isNotEmpty) {
      final optionIds = item.selectedOptions!.map((e) => e.id).toList()..sort();
      optionsHash = '_' + optionIds.join('_');
    }

    final String trackId = item.type == 'combo_offer' 
        ? (item.offerId ?? item.id) 
        : (item.variantId != null ? '${item.mealId}_${item.variantId}$optionsHash' : '${item.mealId}$optionsHash');
    _loadingItemIds.add(trackId);
    notifyListeners();

    // Cache the price override for this item/meal/offer
    if (priceOverride != null || (origPrice != null && effectivePrice < origPrice)) {
      if (item.id.isNotEmpty) _priceOverrides[item.id] = effectivePrice;
      if (item.mealId.isNotEmpty) _priceOverrides[item.mealId] = effectivePrice;
      if (item.offerId != null && item.offerId!.isNotEmpty) {
        _priceOverrides[item.offerId!] = effectivePrice;
      }
      _priceOverrides[trackId] = effectivePrice;

      if (origPrice != null) {
        if (item.id.isNotEmpty) _originalPrices[item.id] = origPrice;
        if (item.mealId.isNotEmpty) _originalPrices[item.mealId] = origPrice;
        if (item.offerId != null && item.offerId!.isNotEmpty) {
          _originalPrices[item.offerId!] = origPrice;
        }
        _originalPrices[trackId] = origPrice;
      }
    }

    try {
      final String? currentRestId = item.restaurantId.isNotEmpty 
          ? item.restaurantId 
          : restaurant?['id']?.toString() ?? _restaurant?['id']?.toString();
          
      final Map<String, dynamic> data = {
        if (item.mealId.isNotEmpty)
          "meal_id": int.tryParse(item.mealId) ?? item.mealId,
        "quantity": item.quantity,
        if (currentRestId != null && currentRestId.isNotEmpty) 
          "restaurant_id": int.tryParse(currentRestId) ?? currentRestId,
        if (item.variantId != null) "variant_id": item.variantId,
        if (item.selectedOptions != null && item.selectedOptions!.isNotEmpty)
          "option_ids": item.selectedOptions!.map((o) => o.id).toList(),
        if (effectivePrice > 0) "price": effectivePrice,
        if (effectivePrice > 0) "unit_price": effectivePrice,
        if (effectivePrice > 0) "price_override": effectivePrice,
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
    _priceOverrides.remove(id);
    _originalPrices.remove(id);
    if (item.mealId.isNotEmpty) {
      _loadingItemIds.add(item.mealId);
      _priceOverrides.remove(item.mealId);
      _originalPrices.remove(item.mealId);
    }
    if (item.offerId != null && item.offerId!.isNotEmpty) {
      _priceOverrides.remove(item.offerId!);
      _originalPrices.remove(item.offerId!);
    }
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
      String optionsHash = '';
      if (_items[index].selectedOptions != null && _items[index].selectedOptions!.isNotEmpty) {
        final optionIds = _items[index].selectedOptions!.map((e) => e.id).toList()..sort();
        optionsHash = '_' + optionIds.join('_');
      }
      final trackId = _items[index].type == 'combo_offer' 
          ? (_items[index].offerId ?? id) 
          : (_items[index].variantId != null ? '${_items[index].mealId}_${_items[index].variantId}$optionsHash' : '${_items[index].mealId}$optionsHash');
      final newQuantity = _items[index].quantity + 1;
      await _updateItemQuantity(id, trackId, newQuantity);
    }
  }

  Future<void> decrementQuantity(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      String optionsHash = '';
      if (_items[index].selectedOptions != null && _items[index].selectedOptions!.isNotEmpty) {
        final optionIds = _items[index].selectedOptions!.map((e) => e.id).toList()..sort();
        optionsHash = '_' + optionIds.join('_');
      }
      final trackId = _items[index].type == 'combo_offer' 
          ? (_items[index].offerId ?? id) 
          : (_items[index].variantId != null ? '${_items[index].mealId}_${_items[index].variantId}$optionsHash' : '${_items[index].mealId}$optionsHash');
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
    _priceOverrides.clear();
    _originalPrices.clear();
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

  Future<void> applyCoupon(String code, double subtotal, int restaurantId) async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.post(
        Endpoints.validateCoupon,
        data: {
          "code": code,
          "subtotal": subtotal,
          "restaurant_id": restaurantId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final couponData = data['data'] ?? data['coupon'] ?? data;

        final double? returnedDiscountAmount = double.tryParse(
          couponData['discount_amount']?.toString() ??
              couponData['discount']?.toString() ??
              data['discount_amount']?.toString() ??
              data['discount']?.toString() ??
              '',
        );

        final type = couponData['discount_type']?.toString().toLowerCase() ??
            couponData['type']?.toString().toLowerCase();
        final valNum = couponData['discount_value'] ??
            couponData['value'] ??
            couponData['discount'];
        final double val = double.tryParse(valNum?.toString() ?? '0') ?? 0.0;

        _appliedCouponCode = code;
        _couponDiscountType = type;
        _couponDiscountValue = val;

        if (returnedDiscountAmount != null && returnedDiscountAmount > 0) {
          _discountAmount = returnedDiscountAmount;
        } else {
          _recalculateDiscount();
        }
        notifyListeners();
        return;
      } else {
        final msg =
            response.data?['message']?.toString() ?? 'فشل تطبيق الكوبون';
        throw Exception(msg);
      }
    } on DioException catch (e) {
      debugPrint('API Error in applyCoupon: $e');
      String errorMessage = '';
      if (e.response?.data is Map) {
        final data = e.response!.data as Map<String, dynamic>;
        if (data['errors'] != null) {
          if (data['errors'] is Map) {
            final errorsMap = data['errors'] as Map;
            final firstKey = errorsMap.keys.firstOrNull;
            if (firstKey != null) {
              final val = errorsMap[firstKey];
              if (val is List && val.isNotEmpty) {
                errorMessage = val.first.toString();
              } else if (val is String) {
                errorMessage = val;
              }
            }
          } else if (data['errors'] is List &&
              (data['errors'] as List).isNotEmpty) {
            errorMessage = (data['errors'] as List).first.toString();
          } else if (data['errors'] is String) {
            errorMessage = data['errors'];
          }
        }
        if (errorMessage.isEmpty && data['message'] != null) {
          errorMessage = data['message'].toString();
        }
      }
      if (errorMessage.isEmpty) {
        errorMessage = e.message ?? 'حدث خطأ أثناء تطبيق الكوبون';
      }
      _appliedCouponCode = null;
      _discountAmount = 0.0;
      _couponDiscountType = null;
      _couponDiscountValue = 0.0;
      notifyListeners();
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('Error in applyCoupon: $e');
      _appliedCouponCode = null;
      _discountAmount = 0.0;
      _couponDiscountType = null;
      _couponDiscountValue = 0.0;
      notifyListeners();
      if (e is Exception) {
        rethrow;
      }
      throw Exception(e.toString());
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
