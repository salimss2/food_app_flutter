import 'package:flutter/material.dart';
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
  final List<ScheduledOrder> _orders = [];

  List<ScheduledOrder> get orders =>
      _orders.where((o) => o.status != 'cancelled').toList();

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

  void cancelOrder(String id) {
    final index = _orders.indexWhere((o) => o.id == id);
    if (index >= 0) {
      _orders[index].status = 'cancelled';
      notifyListeners();
    }
  }
}
