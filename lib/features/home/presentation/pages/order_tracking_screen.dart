import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

import '../../../../core/widgets/custom_background.dart';

class OrderTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const OrderTrackingScreen({super.key, required this.orderData});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  List<LatLng> routePoints = [];
  String storeAddress = "جاري جلب العنوان...";
  String customerAddress = "جاري جلب العنوان...";
  bool isLoadingRoute = true;
  final String orsKey =
      'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjcwMjUxZDVkMDkzOTRhYTNiOGNkNWE3NjI5MTczZjlhIiwiaCI6Im11cm11cjY0In0=';
  final String locationIqKey = 'pk.93ec8bc5ca24f78b868563c6caec4660';

  @override
  void initState() {
    super.initState();
    fetchRealRoute();
    fetchAddresses();
  }

  Future<void> fetchRealRoute() async {
    try {
      final url = Uri.parse(
        'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$orsKey&start=49.1200,14.5450&end=49.1280,14.5380',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coordinates =
            data['features'][0]['geometry']['coordinates'] as List;
        setState(() {
          routePoints = coordinates
              .map((coord) => LatLng(coord[1], coord[0]))
              .toList();
          isLoadingRoute = false;
        });
      } else {
        setState(() => isLoadingRoute = false);
      }
    } catch (e) {
      setState(() => isLoadingRoute = false);
    }
  }

  Future<void> fetchAddresses() async {
    try {
      final storeUrl = Uri.parse(
        'https://us1.locationiq.com/v1/reverse.php?key=$locationIqKey&lat=14.5450&lon=49.1200&format=json&accept-language=ar',
      );
      final customerUrl = Uri.parse(
        'https://us1.locationiq.com/v1/reverse.php?key=$locationIqKey&lat=14.5380&lon=49.1280&format=json&accept-language=ar',
      );

      final storeResponse = await http.get(storeUrl);
      final customerResponse = await http.get(customerUrl);

      if (storeResponse.statusCode == 200) {
        final storeData = json.decode(storeResponse.body);
        setState(() {
          storeAddress = storeData['display_name'] ?? storeAddress;
        });
      }
      if (customerResponse.statusCode == 200) {
        final customerData = json.decode(customerResponse.body);
        setState(() {
          customerAddress = customerData['display_name'] ?? customerAddress;
        });
      }
    } catch (e) {
      // Handle error implicitly
    }
  }

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
            "تابع الطلب",
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
    return FlutterMap(
      options: const MapOptions(
        initialCenter: LatLng(14.5425, 49.1242),
        initialZoom: 14.5,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
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
              point: routePoints.isNotEmpty
                  ? routePoints.first
                  : const LatLng(14.5450, 49.1200),
              width: 40,
              height: 40,
              child: _buildMapPin(Icons.storefront, const Color(0xFF0F55E8)),
            ),
            Marker(
              point: routePoints.isNotEmpty
                  ? routePoints.last
                  : const LatLng(14.5380, 49.1280),
              width: 40,
              height: 40,
              child: _buildMapPin(Icons.home_filled, const Color(0xFFFF416C)),
            ),
            Marker(
              point: routePoints.isNotEmpty
                  ? routePoints[routePoints.length ~/ 2]
                  : const LatLng(14.5410, 49.1240),
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

  // ===========================================================================
  // Horizontal Timeline
  // ===========================================================================
  Widget _buildHorizontalTimeline() {
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
              _buildTimelineItem("تم تقديم\nالطلب", isCompleted: true),
              _buildTimelineItem("تم تأكيد\nالطلب", isCompleted: true),
              _buildTimelineItem("تحضير\nالسلعة", isCompleted: true),
              _buildTimelineItem("التسليم في\nالطريق", isActive: true),
              _buildTimelineItem("تم\nالتوصيل", isPending: true),
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
                "طريق الرحلة",
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
                            "من المتجر",
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
                                "9.82 كم",
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
                            "إلى العميل",
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
                "رجل التسليم",
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
                            "فهمي لبيب",
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.orange,
                                size: 14,
                              ),
                              const Icon(
                                Icons.star,
                                color: Colors.orange,
                                size: 14,
                              ),
                              const Icon(
                                Icons.star,
                                color: Colors.orange,
                                size: 14,
                              ),
                              const Icon(
                                Icons.star,
                                color: Colors.orange,
                                size: 14,
                              ),
                              const Icon(
                                Icons.star_half,
                                color: Colors.orange,
                                size: 14,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "4.9",
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
                        Container(
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
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFD32F2F,
                            ).withOpacity(0.15), // Red accent
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
                    context.pushReplacement('/rate-order');
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
                    "تم استلام الطلب",
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
}
