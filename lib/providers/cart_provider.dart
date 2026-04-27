import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/api/dio_client.dart';
import '../core/api/endpoints.dart';

class CartItem {
  final String id;
  final String mealId;
  final String name;
  final double price;
  final String imageUrl;
  int quantity;
  final List<String> addons;

  CartItem({
    this.id = '',
    required this.mealId,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.quantity = 1,
    this.addons = const [],
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id']?.toString() ?? '',
      mealId: json['meal_id']?.toString() ?? '',
      name: json['meal']?['name'] ?? json['name'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? json['meal']?['price']?.toString() ?? json['subtotal']?.toString() ?? '0') ?? 0.0,
      imageUrl: json['meal']?['image_url'] ?? json['image_url'] ?? '',
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      addons: (json['addons'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}

class CartProvider extends ChangeNotifier {
  final Dio _dio = DioClient().dio;
  
  List<CartItem> _items = [];
  double _totalAmount = 0.0;
  bool isLoading = false;
  
  // Track loading state for specific meals to avoid global loading flicker
  final Set<String> _loadingItemIds = {};

  List<Map<String, dynamic>>? _cachedRestaurants;

  void setCachedRestaurants(List<Map<String, dynamic>> restaurants) {
    _cachedRestaurants = restaurants;
  }

  List<CartItem> get items => _items;
  double get totalPrice => _totalAmount;

  bool isItemLoading(String mealId) => _loadingItemIds.contains(mealId);

  CartItem? getItemByMealId(String mealId) {
    try {
      return _items.firstWhere((item) => item.mealId == mealId);
    } catch (_) {
      return null;
    }
  }

  int getQuantityByMealId(String mealId) {
    return getItemByMealId(mealId)?.quantity ?? 0;
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
        
        final cartItems = cartData['cart_items'] ?? cartData['items'] ?? data['items'] ?? [];
        
        _items = (cartItems as List).map((item) {
          String mealName = item['meal']?['name'] ?? item['name'] ?? 'وجبة غير معروفة';
          String mealImage = item['meal']?['image_url'] ?? item['image_url'] ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&q=80';
          
          if (_cachedRestaurants != null) {
            final String mealId = item['meal_id']?.toString() ?? '';
            for (var r in _cachedRestaurants!) {
              for (var m in (r['menu'] ?? [])) {
                if (m['id'].toString() == mealId || m['name'].toString() == mealId) {
                  mealName = m['name'] ?? mealName;
                  mealImage = m['imageUrl'] ?? mealImage;
                  break;
                }
              }
            }
          }
          
          final cartItem = CartItem.fromJson(item);
          return CartItem(
            id: cartItem.id,
            mealId: cartItem.mealId,
            quantity: cartItem.quantity,
            price: cartItem.price,
            addons: cartItem.addons,
            name: mealName,
            imageUrl: mealImage,
          );
        }).toList();
            
        _totalAmount = double.tryParse(cartData['total']?.toString() ?? '0') ?? 0.0;
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

  Future<void> addItem(CartItem item) async {
    _loadingItemIds.add(item.mealId);
    notifyListeners();

    try {
      await _dio.post(Endpoints.addToCart, data: {
        "meal_id": item.mealId,
        "quantity": item.quantity,
      });
      await fetchCart();
    } on DioException catch (e) {
      debugPrint('API Error in addItem: $e');
      throw Exception(e.response?.data['message'] ?? e.message);
    } catch (e) {
      debugPrint('API Error in addItem: $e');
      throw Exception(e.toString());
    } finally {
      _loadingItemIds.remove(item.mealId);
      notifyListeners();
    }
  }

  Future<void> removeItem(String id) async {
    final item = _items.firstWhere((element) => element.id == id, orElse: () => CartItem(mealId: '', name: '', price: 0, imageUrl: ''));
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
      final mealId = _items[index].mealId;
      final newQuantity = _items[index].quantity + 1;
      await _updateItemQuantity(id, mealId, newQuantity);
    }
  }

  Future<void> decrementQuantity(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      final mealId = _items[index].mealId;
      final newQuantity = _items[index].quantity - 1;
      if (newQuantity > 0) {
        await _updateItemQuantity(id, mealId, newQuantity);
      } else {
        await removeItem(id);
      }
    }
  }

  Future<void> _updateItemQuantity(String id, String mealId, int quantity) async {
    _loadingItemIds.add(mealId);
    notifyListeners();

    try {
      await _dio.put('${Endpoints.updateCartItem}/$id', data: {
        "quantity": quantity,
      });
      await fetchCart();
    } on DioException catch (e) {
      debugPrint('API Error in _updateItemQuantity: $e');
    } catch (e) {
      debugPrint('API Error in _updateItemQuantity: $e');
    } finally {
      _loadingItemIds.remove(mealId);
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
}
