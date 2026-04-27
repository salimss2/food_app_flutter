import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/api/dio_client.dart';
import '../core/api/endpoints.dart';

class OrderProvider extends ChangeNotifier {
  final Dio _dio = DioClient().dio;

  List<dynamic> _orders = [];
  bool isLoading = false;

  // Holds the last error message so the UI can display it.
  String? lastError;

  List<dynamic> get orders => _orders;

  // ---------------------------------------------------------------------------
  // Fetch Order History  — GET /api/v1/orders
  // ---------------------------------------------------------------------------
  Future<void> fetchOrders() async {
    isLoading = true;
    lastError = null;
    notifyListeners();

    try {
      final response = await _dio.get(Endpoints.orders);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final ordersData = data['data'] ?? data['orders'] ?? data;
        _orders = List<dynamic>.from(ordersData);
      }
    } on DioException catch (e) {
      lastError = e.response?.data?['message']?.toString() ?? e.message;
      debugPrint('DioException in fetchOrders:');
      debugPrint('  Status : ${e.response?.statusCode}');
      debugPrint('  Data   : ${e.response?.data}');
    } catch (e) {
      lastError = e.toString();
      debugPrint('Error in fetchOrders: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Place Order  — POST /api/v1/orders
  // The backend reads the authenticated user's cart; no body is required.
  // Returns a tuple: (success, errorMessage)
  // ---------------------------------------------------------------------------
  // ---------------------------------------------------------------------------
  // Place Order  — POST /api/v1/orders
  // The backend reads the authenticated user's cart; no body is required.
  // Returns a record: (success, errorMessage, orderData)
  // ---------------------------------------------------------------------------
  Future<(bool, String?, Map<String, dynamic>?)> placeOrder({
    DateTime? scheduledAt,
    String? paymentMethod,
    String? receiptNumber,
    File? receiptImage,
  }) async {
    isLoading = true;
    lastError = null;
    notifyListeners();

    try {
      // DioClient already attaches the Authorization: Bearer <token> header.
      final Map<String, dynamic> fields = {};
      
      if (scheduledAt != null) {
        fields['scheduled_at'] = scheduledAt.toIso8601String();
      }
      if (paymentMethod != null) {
        fields['payment_method'] = paymentMethod;
      }
      if (receiptNumber != null) {
        fields['receipt_number'] = receiptNumber;
      }
      
      dynamic payload;
      
      if (receiptImage != null) {
        fields['receipt_image'] = await MultipartFile.fromFile(
          receiptImage.path,
          filename: receiptImage.path.split('/').last,
        );
        payload = FormData.fromMap(fields);
      } else if (fields.isNotEmpty) {
        payload = fields;
      }
          
      final response = await _dio.post(Endpoints.placeOrder, data: payload);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        // The API returns {'orders': [{...}]} - extract the first element safely
        final ordersList = data['orders'] as List?;
        final orderData = (ordersList != null && ordersList.isNotEmpty)
            ? ordersList[0] as Map<String, dynamic>
            : (data['order'] as Map<String, dynamic>? ?? {});

        // Refresh the order history in the background.
        await fetchOrders();
        return (true, null, orderData);
      }

      // Unexpected 2xx that isn't 200/201
      final msg = response.data?['message']?.toString() ?? 'حدث خطأ غير متوقع';
      lastError = msg;
      return (false, msg, null);
    } on DioException catch (e) {
      final serverMsg = e.response?.data?['message']?.toString();
      final msg = serverMsg ?? e.message ?? 'تعذّر الاتصال بالخادم';
      lastError = msg;

      debugPrint('DioException in placeOrder:');
      debugPrint('  Status : ${e.response?.statusCode}');
      debugPrint('  Data   : ${e.response?.data}');

      return (false, msg, null);
    } catch (e) {
      final msg = e.toString();
      lastError = msg;
      debugPrint('Error in placeOrder: $e');
      return (false, msg, null);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
