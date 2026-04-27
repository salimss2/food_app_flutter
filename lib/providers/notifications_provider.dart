import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/api/dio_client.dart';
import '../core/api/endpoints.dart';

class NotificationsProvider extends ChangeNotifier {
  final Dio _dio = DioClient().dio;

  List<Map<String, dynamic>> _notifications = [];
  bool isLoading = false;
  String? lastError;

  List<Map<String, dynamic>> get notifications => _notifications;

  Future<void> fetchNotifications() async {
    isLoading = true;
    lastError = null;
    notifyListeners();

    try {
      final response = await _dio.get(Endpoints.getNotifications);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final notificationsData = data['data'] ?? data['notifications'] ?? data;
        
        if (notificationsData is List) {
          _notifications = List<Map<String, dynamic>>.from(notificationsData);
        } else {
          _notifications = [];
        }
      }
    } on DioException catch (e) {
      lastError = e.response?.data?['message']?.toString() ?? e.message;
      debugPrint('DioException in fetchNotifications:');
      debugPrint('  Status : ${e.response?.statusCode}');
      debugPrint('  Data   : ${e.response?.data}');
    } catch (e) {
      lastError = e.toString();
      debugPrint('Error in fetchNotifications: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Add a new notification to the top of the list (Real-time sync)
  void addNotification(Map<String, dynamic> notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  // Mark notification as read
  Future<void> markAsRead(String id) async {
    // Optimistic UI update
    final index = _notifications.indexWhere((n) => n['id'].toString() == id);
    if (index != -1) {
      _notifications[index]['read_at'] = DateTime.now().toIso8601String();
      _notifications[index]['isRead'] = true;
      notifyListeners();
    }

    try {
      await _dio.post('${Endpoints.markNotificationAsRead}/$id/read');
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      // Revert optimistic update on failure
      if (index != -1) {
        _notifications[index]['read_at'] = null;
        _notifications[index]['isRead'] = false;
        notifyListeners();
      }
    }
  }
}
