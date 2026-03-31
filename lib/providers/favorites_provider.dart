import 'package:flutter/material.dart';

class FavoritesProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _favRestaurants = [];
  final List<Map<String, dynamic>> _favMeals = [];

  List<Map<String, dynamic>> get favRestaurants => _favRestaurants;
  List<Map<String, dynamic>> get favMeals => _favMeals;

  // ---- المطاعم ----

  void toggleRestaurant(Map<String, dynamic> restaurant) {
    final id = restaurant['id']?.toString() ?? restaurant['name']?.toString() ?? '';
    final index = _favRestaurants.indexWhere(
      (r) => (r['id']?.toString() ?? r['name']?.toString() ?? '') == id,
    );
    if (index >= 0) {
      _favRestaurants.removeAt(index);
    } else {
      _favRestaurants.add(restaurant);
    }
    notifyListeners();
  }

  bool isRestaurantFav(String id) {
    return _favRestaurants.any(
      (r) => (r['id']?.toString() ?? r['name']?.toString() ?? '') == id,
    );
  }

  // ---- الوجبات ----

  void toggleMeal(Map<String, dynamic> meal) {
    final id = meal['id']?.toString() ?? meal['name']?.toString() ?? '';
    final index = _favMeals.indexWhere(
      (m) => (m['id']?.toString() ?? m['name']?.toString() ?? '') == id,
    );
    if (index >= 0) {
      _favMeals.removeAt(index);
    } else {
      _favMeals.add(meal);
    }
    notifyListeners();
  }

  bool isMealFav(String id) {
    return _favMeals.any(
      (m) => (m['id']?.toString() ?? m['name']?.toString() ?? '') == id,
    );
  }
}
