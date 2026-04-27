import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/restaurant_model.dart';
import '../core/api/dio_client.dart';
import '../core/api/endpoints.dart';

class RestaurantNotifier extends AsyncNotifier<List<Restaurant>> {
  @override
  FutureOr<List<Restaurant>> build() async {
    return _fetchRestaurantsFromApi();
  }

  Future<List<Restaurant>> _fetchRestaurantsFromApi() async {
    final dio = DioClient().dio;
    final response = await dio.get(Endpoints.getRestaurants);
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data;
      final List<dynamic> restaurantsData = data is List 
          ? data 
          : (data['data'] ?? data['restaurants'] ?? []);

      return restaurantsData.map((json) => Restaurant.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load restaurants: ${response.statusCode}');
    }
  }

  Future<void> refreshRestaurants() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchRestaurantsFromApi());
  }
}

final restaurantProvider = AsyncNotifierProvider<RestaurantNotifier, List<Restaurant>>(() {
  return RestaurantNotifier();
});
