import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/api/dio_client.dart';
import '../core/api/endpoints.dart';
import 'cart_provider.dart';

class ScheduledOrder {
  final String id;
  final List<CartItem> items;
  final double totalPrice;
  DateTime scheduledDateTime;
  String status; // 'pending', 'confirmed', 'cancelled'

  ScheduledOrder({
    required this.id,
    required this.items,
    required this.totalPrice,
    required this.scheduledDateTime,
    this.status = 'pending',
  });
}

class ScheduleProvider extends ChangeNotifier {
  final Dio _dio = DioClient().dio;

  final List<ScheduledOrder> _orders = [];
  List<Map<String, dynamic>> scheduledOrders = [];
  bool isLoading = false;
  String? lastError;

  Future<void> fetchScheduledOrders() async {
    isLoading = true;
    lastError = null;
    notifyListeners();

    try {
      final response = await _dio.get('${Endpoints.baseUrl}/v1/scheduled-orders');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['orders'] ?? [];
        scheduledOrders = List<Map<String, dynamic>>.from(data);
      } else {
        lastError = 'فشل جلب الطلبات المجدولة';
      }
    } on DioException catch (e) {
      lastError = e.response?.data?['message']?.toString() ?? e.message ?? 'تعذّر الاتصال بالخادم';
    } catch (e) {
      lastError = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  List<ScheduledOrder> get orders =>
      _orders.where((o) => o.status != 'cancelled').toList();

  // ---------------------------------------------------------------------------
  // Local list management (kept for offline / optimistic display)
  // ---------------------------------------------------------------------------

  void addScheduledOrder(ScheduledOrder order) {
    _orders.add(order);
    notifyListeners();
  }

  void updateSchedule(String id, DateTime newDateTime) {
    final index = _orders.indexWhere((o) => o.id == id);
    if (index >= 0) {
      _orders[index].scheduledDateTime = newDateTime;
      notifyListeners();
    }
  }

  Future<bool> cancelOrder(int id) async {
    try {
      final response = await _dio.delete('${Endpoints.baseUrl}/v1/scheduled-orders/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        scheduledOrders.removeWhere((o) => o['id'] == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error canceling order: $e');
    }
    return false;
  }

}
