import 'package:flutter/material.dart';
import '../core/api/dio_client.dart';
import '../core/api/endpoints.dart';
import '../models/offer_model.dart';

enum OffersStatus { initial, loading, loaded, error }

class OffersProvider extends ChangeNotifier {
  final DioClient _dioClient = DioClient();

  List<OfferModel> _banners = [];
  OffersStatus _bannersStatus = OffersStatus.initial;
  String _errorMessage = '';

  // Restaurant Deals Map: restaurantId -> List<OfferModel>
  final Map<int, List<OfferModel>> _restaurantOffers = {};
  final Map<int, OffersStatus> _restaurantOffersStatus = {};

  List<OfferModel> get banners => _banners;
  List<OfferModel> get offers => _banners; // Backward compatibility
  OffersStatus get status => _bannersStatus;
  OffersStatus get bannersStatus => _bannersStatus;
  String get errorMessage => _errorMessage;

  bool get isLoading => _bannersStatus == OffersStatus.loading;
  bool get hasError => _bannersStatus == OffersStatus.error;
  bool get isLoaded => _bannersStatus == OffersStatus.loaded;

  List<OfferModel> getRestaurantOffers(int restaurantId) {
    return _restaurantOffers[restaurantId] ?? [];
  }

  OffersStatus getRestaurantOffersStatus(int restaurantId) {
    return _restaurantOffersStatus[restaurantId] ?? OffersStatus.initial;
  }

  bool isRestaurantOffersLoading(int restaurantId) {
    return _restaurantOffersStatus[restaurantId] == OffersStatus.loading;
  }

  Future<void> fetchBanners() async {
    debugPrint("🛑 [OffersProvider] fetchBanners() called");
    _bannersStatus = OffersStatus.loading;
    notifyListeners();

    try {
      dynamic response;
      try {
        debugPrint("🛑 [OffersProvider] Requesting offerBanners: ${Endpoints.offerBanners}");
        response = await _dioClient.dio.get(Endpoints.offerBanners);
        debugPrint("🛑 [OffersProvider] offerBanners statusCode: ${response.statusCode}");
      } catch (e) {
        debugPrint("🛑 [OffersProvider] offerBanners endpoint failed ($e), falling back to offers: ${Endpoints.offers}");
        response = await _dioClient.dio.get(Endpoints.offers);
        debugPrint("🛑 [OffersProvider] fallback offers statusCode: ${response.statusCode}");
      }

      debugPrint("🛑 OFFERS API RESPONSE CODE: ${response?.statusCode}");
      debugPrint("🛑 OFFERS API DATA: ${response?.data}");

      if (response != null && response.statusCode == 200 && response.data != null) {
        final data = response.data;
        List<dynamic> listData = [];

        if (data is List) {
          listData = data;
        } else if (data is Map && data['data'] != null) {
          listData = data['data'] is List ? data['data'] as List<dynamic> : [];
        } else if (data is Map && data['banners'] != null) {
          listData = data['banners'] is List ? data['banners'] as List<dynamic> : [];
        } else if (data is Map && data['offers'] != null) {
          listData = data['offers'] is List ? data['offers'] as List<dynamic> : [];
        }

        _banners = listData
            .map((item) => OfferModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        _bannersStatus = OffersStatus.loaded;
        debugPrint("🛑 [OffersProvider] Successfully parsed ${_banners.length} banners.");
      } else {
        _bannersStatus = OffersStatus.error;
        _errorMessage = 'Failed to load offers banners (Status: ${response?.statusCode})';
        debugPrint("🛑 OFFERS API ERROR: $_errorMessage");
      }
    } catch (e) {
      _bannersStatus = OffersStatus.error;
      _errorMessage = e.toString();
      debugPrint("🛑 OFFERS API ERROR: $e");
    }

    notifyListeners();
  }

  Future<void> fetchOffers() async {
    await fetchBanners();
  }

  Future<List<OfferModel>> fetchRestaurantOffers(int restaurantId) async {
    debugPrint("🛑 [OffersProvider] fetchRestaurantOffers($restaurantId) called");
    _restaurantOffersStatus[restaurantId] = OffersStatus.loading;
    notifyListeners();

    try {
      final endpoint = Endpoints.restaurantOffers(restaurantId);
      debugPrint("🛑 [OffersProvider] Requesting restaurantOffers: $endpoint");
      final response = await _dioClient.dio.get(endpoint);

      debugPrint("🛑 RESTAURANT OFFERS API RESPONSE CODE: ${response.statusCode}");
      debugPrint("🛑 RESTAURANT OFFERS API DATA: ${response.data}");

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        List<dynamic> listData = [];

        if (data is List) {
          listData = data;
        } else if (data is Map && data['data'] != null) {
          listData = data['data'] is List ? data['data'] as List<dynamic> : [];
        } else if (data is Map && data['offers'] != null) {
          listData = data['offers'] is List ? data['offers'] as List<dynamic> : [];
        }

        final offers = listData
            .map((item) => OfferModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();

        _restaurantOffers[restaurantId] = offers;
        _restaurantOffersStatus[restaurantId] = OffersStatus.loaded;
        debugPrint("🛑 [OffersProvider] Successfully parsed ${offers.length} offers for restaurant $restaurantId.");
        notifyListeners();
        return offers;
      } else {
        _restaurantOffersStatus[restaurantId] = OffersStatus.error;
        debugPrint("🛑 RESTAURANT OFFERS API ERROR: Status ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("🛑 RESTAURANT OFFERS API ERROR: $e");
      _restaurantOffersStatus[restaurantId] = OffersStatus.error;
    }

    notifyListeners();
    return _restaurantOffers[restaurantId] ?? [];
  }
}
