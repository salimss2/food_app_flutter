import 'package:flutter/material.dart';
import '../core/api/dio_client.dart';
import '../core/api/endpoints.dart';

enum OffersStatus { initial, loading, loaded, error }

class OffersProvider extends ChangeNotifier {
  List<dynamic> _offers = [];
  OffersStatus _status = OffersStatus.initial;
  String _errorMessage = '';

  List<dynamic> get offers => _offers;
  OffersStatus get status => _status;
  String get errorMessage => _errorMessage;

  bool get isLoading => _status == OffersStatus.loading;
  bool get hasError => _status == OffersStatus.error;
  bool get isLoaded => _status == OffersStatus.loaded;

  Future<void> fetchOffers() async {
    if (_status == OffersStatus.loading) return;

    _status = OffersStatus.loading;
    notifyListeners();

    try {
      final response = await DioClient().dio.get('${Endpoints.baseUrl}/v1/offers');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        // Support both { "data": [...] } and bare list responses
        if (data is List) {
          _offers = data;
        } else if (data is Map && data['data'] != null) {
          _offers = data['data'] as List<dynamic>;
        } else {
          _offers = [];
        }
        _status = OffersStatus.loaded;
      } else {
        _status = OffersStatus.error;
        _errorMessage = 'Failed to load offers';
      }
    } catch (e) {
      _status = OffersStatus.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }
}
