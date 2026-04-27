import 'package:flutter/material.dart';
import '../core/api/dio_client.dart';
import '../core/api/endpoints.dart';

class FavoritesProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _favRestaurants = [];
  List<Map<String, dynamic>> _favMeals = [];

  List<Map<String, dynamic>> get favRestaurants => _favRestaurants;
  List<Map<String, dynamic>> get favMeals => _favMeals;

  final _dio = DioClient().dio;

  Future<void> fetchFavorites() async {
    try {
      final response = await _dio.get(Endpoints.getFavorites);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'] ?? response.data;
        if (data['restaurants'] != null) {
          _favRestaurants = List<Map<String, dynamic>>.from(
            data['restaurants'],
          );
        }
        if (data['meals'] != null) {
          _favMeals = List<Map<String, dynamic>>.from(data['meals']);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching favorites: $e');
    }
  }

  // ---- المطاعم ----

  Future<void> toggleRestaurant(Map<String, dynamic> restaurant) async {
    final id =
        restaurant['id']?.toString() ?? restaurant['name']?.toString() ?? '';
    final index = _favRestaurants.indexWhere(
      (r) => (r['id']?.toString() ?? r['name']?.toString() ?? '') == id,
    );

    final bool isAdded = index < 0;

    // Optimistic UI update
    if (isAdded) {
      _favRestaurants.add(restaurant);
    } else {
      _favRestaurants.removeAt(index);
    }
    notifyListeners();

    try {
      final response = await _dio.post(
        Endpoints.toggleRestaurantFav,
        data: {'restaurant_id': restaurant['id']},
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to toggle restaurant favorite');
      }
    } catch (e) {
      // Revert local change
      if (isAdded) {
        _favRestaurants.removeWhere(
          (r) => (r['id']?.toString() ?? r['name']?.toString() ?? '') == id,
        );
      } else {
        _favRestaurants.insert(index, restaurant);
      }
      notifyListeners();
      throw Exception('Failed to update favorite status');
    }
  }

  bool isRestaurantFav(String id) {
    return _favRestaurants.any(
      (r) => (r['id']?.toString() ?? r['name']?.toString() ?? '') == id,
    );
  }

  // ---- الوجبات ----

  Future<void> toggleMeal(Map<String, dynamic> meal) async {
    final id = meal['id']?.toString() ?? meal['name']?.toString() ?? '';
    final index = _favMeals.indexWhere(
      (m) => (m['id']?.toString() ?? m['name']?.toString() ?? '') == id,
    );

    final bool isAdded = index < 0;

    // Optimistic UI update
    if (isAdded) {
      _favMeals.add(meal);
    } else {
      _favMeals.removeAt(index);
    }
    notifyListeners();

    try {
      final response = await _dio.post(
        Endpoints.toggleMealFav,
        data: {'meal_id': meal['id']},
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to toggle meal favorite');
      }
    } catch (e) {
      // Revert local change
      if (isAdded) {
        _favMeals.removeWhere(
          (m) => (m['id']?.toString() ?? m['name']?.toString() ?? '') == id,
        );
      } else {
        _favMeals.insert(index, meal);
      }
      notifyListeners();
      throw Exception('Failed to update favorite status');
    }
  }

  bool isMealFav(String id) {
    return _favMeals.any(
      (m) => (m['id']?.toString() ?? m['name']?.toString() ?? '') == id,
    );
  }
}
