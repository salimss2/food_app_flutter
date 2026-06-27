import 'dart:async';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

import '../../../../core/api/dio_client.dart';
import '../../../../core/api/endpoints.dart';
import '../../../../core/widgets/custom_background.dart';

class OrderTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const OrderTrackingScreen({super.key, required this.orderData});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  // ── Route & address state ────────────────────────────────────────────────
  List<LatLng> routePoints = [];
  String storeAddress = "fetching_address".tr();
  String customerAddress = "fetching_address".tr();
  bool isLoadingRoute = true;

  // ── Live driver state ────────────────────────────────────────────────────
  LatLng? liveDriverPosition;
  Map<String, dynamic>? liveDriverInfo;
  String? orderStatus; // Added to store order status

  // ── Polling ──────────────────────────────────────────────────────────────
  Timer? _pollingTimer;

  // ── Keys ─────────────────────────────────────────────────────────────────
  final String locationIqKey = 'pk.93ec8bc5ca24f78b868563c6caec4660';

  // ── Dynamic coordinates extracted from orderData ─────────────────────────
  // ── Dynamic coordinates extracted from orderData ─────────────────────────
  double _restaurantLat = 14.5450;
  double _restaurantLng = 49.1200;
  double _customerLat = 14.5380;
  double _customerLng = 49.1280;

  @override
  void initState() {
    super.initState();

    // Safely extract coordinates with sane fallbacks initially
    _restaurantLat = _toDouble(widget.orderData['restaurant_lat']) ?? 14.5450;
    _restaurantLng = _toDouble(widget.orderData['restaurant_lng']) ?? 49.1200;
    _customerLat = _toDouble(widget.orderData['customer_lat']) ?? 14.5380;
    _customerLng = _toDouble(widget.orderData['customer_lng']) ?? 49.1280;
    orderStatus = widget.orderData['status']?.toString();

    // Seed liveDriverInfo from order data if a driver is already assigned
    final driver = widget.orderData['driver'];
    if (driver is Map<String, dynamic>) {
      liveDriverInfo = driver;
      final dLat = _toDouble(driver['lat'] ?? driver['driver_lat'] ?? driver['latitude']);
      final dLng = _toDouble(driver['lng'] ?? driver['driver_lng'] ?? driver['longitude']);
      if (dLat != null && dLng != null) {
        liveDriverPosition = LatLng(dLat, dLng);
      }
    }

    // Explicitly load freshest coordinates first before route path and address lookup
    _loadInitialTrackingData();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  double? _toDouble(dynamic value) {
    if (value == null) return null;
    try {
      return double.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  // ── Initial Live Tracking Fetch ───────────────────────────────────────────
  Future<void> _loadInitialTrackingData() async {
    final orderId = widget.orderData['id'];
    if (orderId == null) {
      fetchRealRoute();
      fetchAddresses();
      _startPolling();
      return;
    }

    try {
      final response = await DioClient().dio.get('${Endpoints.baseUrl}/v1/orders/$orderId/track');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final orderDataMap = (data['data'] is Map<String, dynamic>)
            ? (data['data'] as Map<String, dynamic>)
            : data;

        final status = orderDataMap['status']?.toString();
        final driverObj = orderDataMap['driver'] as Map<String, dynamic>?;

        final rLat = _toDouble(orderDataMap['restaurant_lat'] ?? orderDataMap['restaurant']?['latitude'] ?? orderDataMap['restaurant']?['restaurant_lat']);
        final rLng = _toDouble(orderDataMap['restaurant_lng'] ?? orderDataMap['restaurant']?['longitude'] ?? orderDataMap['restaurant']?['restaurant_lng']);
        final cLat = _toDouble(orderDataMap['customer_lat'] ?? orderDataMap['customer']?['latitude'] ?? orderDataMap['customer']?['customer_lat']);
        final cLng = _toDouble(orderDataMap['customer_lng'] ?? orderDataMap['customer']?['longitude'] ?? orderDataMap['customer']?['customer_lng']);

        double? dLat;
        double? dLng;
        if (driverObj != null) {
          dLat = _toDouble(driverObj['lat'] ?? driverObj['driver_lat'] ?? driverObj['latitude']);
          dLng = _toDouble(driverObj['lng'] ?? driverObj['driver_lng'] ?? driverObj['longitude']);
        } else {
          dLat = _toDouble(orderDataMap['driver_lat'] ?? orderDataMap['latitude']);
          dLng = _toDouble(orderDataMap['driver_lng'] ?? orderDataMap['longitude']);
        }

        if (!mounted) return;
        setState(() {
          if (status != null) {
            orderStatus = status;
          }
          if (rLat != null) _restaurantLat = rLat;
          if (rLng != null) _restaurantLng = rLng;
          if (cLat != null) _customerLat = cLat;
          if (cLng != null) _customerLng = cLng;

          if (dLat != null && dLng != null) {
            liveDriverPosition = LatLng(dLat, dLng);
          }
          if (driverObj != null) {
            liveDriverInfo = driverObj;
          }
        });
      }
    } catch (e) {
      debugPrint('Failed to load initial tracking coordinates: $e');
    } finally {
      fetchRealRoute();
      fetchAddresses();
      _startPolling();
    }
  }

  // ── Polling ───────────────────────────────────────────────────────────────
  void _startPolling() {
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _fetchLiveDriverData(),
    );
  }

  Future<void> _fetchLiveDriverData() async {
    final orderId = widget.orderData['id'];
    if (orderId == null) return;

    try {
      final response = await DioClient().dio.get('${Endpoints.baseUrl}/v1/orders/$orderId/track');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final orderDataMap = (data['data'] is Map<String, dynamic>)
            ? (data['data'] as Map<String, dynamic>)
            : data;

        final status = orderDataMap['status']?.toString();
        final driverObj = orderDataMap['driver'] as Map<String, dynamic>?;

        final rLat = _toDouble(orderDataMap['restaurant_lat'] ?? orderDataMap['restaurant']?['latitude'] ?? orderDataMap['restaurant']?['restaurant_lat']);
        final rLng = _toDouble(orderDataMap['restaurant_lng'] ?? orderDataMap['restaurant']?['longitude'] ?? orderDataMap['restaurant']?['restaurant_lng']);
        final cLat = _toDouble(orderDataMap['customer_lat'] ?? orderDataMap['customer']?['latitude'] ?? orderDataMap['customer']?['customer_lat']);
        final cLng = _toDouble(orderDataMap['customer_lng'] ?? orderDataMap['customer']?['longitude'] ?? orderDataMap['customer']?['customer_lng']);

        double? dLat;
        double? dLng;
        if (driverObj != null) {
          dLat = _toDouble(driverObj['lat'] ?? driverObj['driver_lat'] ?? driverObj['latitude']);
          dLng = _toDouble(driverObj['lng'] ?? driverObj['driver_lng'] ?? driverObj['longitude']);
        } else {
          dLat = _toDouble(orderDataMap['driver_lat'] ?? orderDataMap['latitude']);
          dLng = _toDouble(orderDataMap['driver_lng'] ?? orderDataMap['longitude']);
        }

        if (!mounted) return;
        setState(() {
          if (status != null) {
            orderStatus = status;
          }
          if (rLat != null) _restaurantLat = rLat;
          if (rLng != null) _restaurantLng = rLng;
          if (cLat != null) _customerLat = cLat;
          if (cLng != null) _customerLng = cLng;

          if (dLat != null && dLng != null) {
            liveDriverPosition = LatLng(dLat, dLng);
          }
          if (driverObj != null) {
            liveDriverInfo = driverObj;
          }
        });
      }
    } catch (_) {
      // Silently ignore — UI keeps showing the last known state
    }
  }

  // ── OSRM Route ────────────────────────────────────────────────────────────
  Future<void> fetchRealRoute() async {
    try {
      // OSRM public API — free, no key required
      // Format: /route/v1/{profile}/{lng,lat};{lng,lat}
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '$_restaurantLng,$_restaurantLat;$_customerLng,$_customerLat'
        '?overview=full&geometries=geojson',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coordinates =
            data['routes'][0]['geometry']['coordinates'] as List;
        if (!mounted) return;
        setState(() {
          routePoints = coordinates
              .map((c) => LatLng(c[1] as double, c[0] as double))
              .toList();
          isLoadingRoute = false;
        });
      } else {
        if (!mounted) return;
        setState(() => isLoadingRoute = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingRoute = false);
    }
  }

  Future<void> fetchAddresses() async {
    try {
      final storeUrl = Uri.parse(
        'https://us1.locationiq.com/v1/reverse.php?key=$locationIqKey'
        '&lat=$_restaurantLat&lon=$_restaurantLng&format=json&accept-language=ar',
      );
      final customerUrl = Uri.parse(
        'https://us1.locationiq.com/v1/reverse.php?key=$locationIqKey'
        '&lat=$_customerLat&lon=$_customerLng&format=json&accept-language=ar',
      );

      final storeResponse = await http.get(storeUrl);
      final customerResponse = await http.get(customerUrl);

      if (storeResponse.statusCode == 200) {
        final storeData = json.decode(storeResponse.body);
        if (mounted) {
          setState(
            () => storeAddress = storeData['display_name'] ?? storeAddress,
          );
        }
      }
      if (customerResponse.statusCode == 200) {
        final customerData = json.decode(customerResponse.body);
        if (mounted) {
          setState(
            () => customerAddress =
                customerData['display_name'] ?? customerAddress,
          );
        }
      }
    } catch (_) {
      // Handle error implicitly
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomBackground(
          child: Stack(
            children: [
              // 1. الخريطة في الخلفية
              Positioned.fill(child: _buildMapPlaceholder()),

              // 2. المحتوى (AppBar, Timeline, Bottom Info)
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // الجزء العلوي
                  SafeArea(
                    child: Column(
                      children: [
                        _buildAppBar(context),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildHorizontalTimeline(),
                        ),
                      ],
                    ),
                  ),

                  // الجزء السفلي
                  _buildBottomPanel(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // App Bar
  // ===========================================================================
  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => context.pop(),
            size: 18,
          ),
          Text(
            "track_order".tr(),
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 40), // Placeholder for balance/alignment
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required double size,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Center(
              child: Icon(icon, color: Colors.white, size: size),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // Map Placeholder
  // ===========================================================================
  Widget _buildMapPlaceholder() {
    // Initial center: live driver → restaurant fallback
    final mapCenter =
        liveDriverPosition ?? LatLng(_restaurantLat, _restaurantLng);

    // Driver Marker point
    final LatLng motorcyclePoint =
        liveDriverPosition ?? LatLng(_restaurantLat, _restaurantLng);

    return FlutterMap(
      options: MapOptions(initialCenter: mapCenter, initialZoom: 14.5),
      children: [
        ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            -1,
            0,
            0,
            0,
            255,
            0,
            -1,
            0,
            0,
            255,
            0,
            0,
            -1,
            0,
            255,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.dfood.app',
          ),
        ),
        PolylineLayer(
          polylines: isLoadingRoute
              ? <Polyline<Object>>[]
              : <Polyline<Object>>[
                  Polyline<Object>(
                    points: routePoints,
                    color: const Color(0xFFD32F2F),
                    strokeWidth: 4.0,
                  ),
                ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: LatLng(_restaurantLat, _restaurantLng),
              width: 40,
              height: 40,
              child: _buildMapPin(Icons.storefront, const Color(0xFF0F55E8)),
            ),
            Marker(
              point: LatLng(_customerLat, _customerLng),
              width: 40,
              height: 40,
              child: _buildMapPin(Icons.home_filled, const Color(0xFFFF416C)),
            ),
            // Only show driver marker if we have driver location, or show at restaurant if fallback needed
            if (liveDriverPosition != null)
              Marker(
                point: motorcyclePoint,
                width: 50,
                height: 50,
                child: _buildMapPin(
                  Icons.motorcycle,
                  const Color(0xFFE58B29),
                  size: 50,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMapPin(IconData icon, Color color, {double size = 40}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Container(
          width: size * 0.7,
          height: size * 0.7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: size * 0.4),
        ),
      ),
    );
  }

  int _getTimelineIndex(String? status) {
    final s = (status ?? 'pending').toLowerCase();
    switch (s) {
      case 'pending':
        return 0;
      case 'confirmed':
      case 'accepted':
        return 1;
      case 'preparing':
      case 'processing':
        return 2;
      case 'out_for_delivery':
      case 'driver_assigned':
      case 'on_the_way':
        return 3;
      case 'delivered':
      case 'completed':
        return 4;
      default:
        return 0;
    }
  }

  // ===========================================================================
  // Horizontal Timeline
  // ===========================================================================
  Widget _buildHorizontalTimeline() {
    final currentStatus = orderStatus ??
                          liveDriverInfo?['order_status'] ?? 
                          liveDriverInfo?['status'] ?? 
                          widget.orderData['status'];
    final step = _getTimelineIndex(currentStatus?.toString());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2640).withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Connecting lines
          Positioned(
            top: 15,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Expanded(
                  child: Container(height: 2, color: const Color(0xFFD32F2F)),
                ), // Red/Orange
                Expanded(
                  child: Container(height: 2, color: const Color(0xFFD32F2F)),
                ),
                Expanded(
                  child: Container(height: 2, color: const Color(0xFFD32F2F)),
                ),
                Expanded(child: Container(height: 2, color: Colors.white12)),
              ],
            ),
          ),
          // Step Items
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTimelineItem(
                "order_placed".tr(),
                isCompleted: step >= 1,
                isActive: step == 0,
              ),
              _buildTimelineItem(
                "order_confirmed".tr(),
                isCompleted: step >= 2,
                isActive: step == 1,
                isPending: step < 1,
              ),
              _buildTimelineItem(
                "preparing_item".tr(),
                isCompleted: step >= 3,
                isActive: step == 2,
                isPending: step < 2,
              ),
              _buildTimelineItem(
                "delivery_on_the_way".tr(),
                isCompleted: step >= 4,
                isActive: step == 3,
                isPending: step < 3,
              ),
              _buildTimelineItem(
                "delivered".tr(),
                isCompleted: step == 4,
                isActive: step == 4,
                isPending: step < 4,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    String title, {
    bool isCompleted = false,
    bool isActive = false,
    bool isPending = false,
  }) {
    Color color;
    IconData icon;

    if (isCompleted) {
      color = const Color(0xFFD32F2F); // Completed: Primary red/orange
      icon = Icons.check_circle;
    } else if (isActive) {
      color = const Color(0xFFE58B29); // Active: Orange accent
      icon = Icons.motorcycle;
    } else {
      color = Colors.white24; // Pending: Grey
      icon = Icons.radio_button_unchecked;
    }

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted || isActive
                  ? color.withOpacity(0.2)
                  : const Color(0xFF2A2640),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              color: isActive || isCompleted ? Colors.white : Colors.white54,
              fontSize: 10,
              fontWeight: isActive || isCompleted
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Bottom Panel (Driver & Route Info)
  // ===========================================================================
  Widget _buildBottomPanel() {
    // Resolve driver info: prefer live data explicitly
    final driverName = liveDriverInfo?['name']?.toString() ?? 'جارِ البحث عن مندوب';
    final driverPhone = liveDriverInfo?['phone']?.toString() ?? '';
    final driverRating = _toDouble(liveDriverInfo?['rating']) ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF140C36),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            offset: const Offset(0, -5),
            blurRadius: 20,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Route Info Header
              Text(
                "trip_route".tr(),
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),

              // Route Visual
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2640).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    Column(
                      children: [
                        const Icon(
                          Icons.store,
                          color: Color(0xFF0F55E8),
                          size: 24,
                        ),
                        Container(
                          height: 30,
                          width: 2,
                          color: Colors.white24,
                          margin: const EdgeInsets.symmetric(vertical: 5),
                        ),
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFFFF416C),
                          size: 24,
                        ),
                      ],
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "from_store".tr(),
                            style: GoogleFonts.cairo(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            storeAddress,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.route,
                                color: Colors.orangeAccent,
                                size: 16,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "9.82 " + "km".tr(),
                                style: GoogleFonts.poppins(
                                  color: Colors.orangeAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "to_customer".tr(),
                            style: GoogleFonts.cairo(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            customerAddress,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Driver Info
              Text(
                "delivery_man".tr(),
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2640).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white12,
                      child: Icon(Icons.person, color: Colors.white54),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driverName,
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              // Build rating stars dynamically
                              ..._buildRatingStars(driverRating),
                              const SizedBox(width: 5),
                              Text(
                                driverRating > 0
                                    ? driverRating.toStringAsFixed(1)
                                    : '—',
                                style: GoogleFonts.poppins(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.push('/chat', extra: driverName),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE58B29).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline,
                              color: Color(0xFFE58B29),
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD32F2F).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.phone,
                            color: Color(0xFFD32F2F),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- Order Received Button ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.pushReplacement('/rate-order', extra: widget.orderData);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 5,
                    shadowColor: const Color(0xFFD32F2F).withOpacity(0.5),
                  ),
                  child: Text(
                    "order_received".tr(),
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Rating stars helper ───────────────────────────────────────────────────
  List<Widget> _buildRatingStars(double rating) {
    final List<Widget> stars = [];
    final int fullStars = rating.floor();
    final bool hasHalf = (rating - fullStars) >= 0.5;

    for (int i = 0; i < fullStars && i < 5; i++) {
      stars.add(const Icon(Icons.star, color: Colors.orange, size: 14));
    }
    if (hasHalf && stars.length < 5) {
      stars.add(const Icon(Icons.star_half, color: Colors.orange, size: 14));
    }
    while (stars.length < 5) {
      stars.add(const Icon(Icons.star_border, color: Colors.orange, size: 14));
    }
    return stars;
  }
}
