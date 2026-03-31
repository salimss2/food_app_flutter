import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart'; // <-- استيراد حزمة التوجيه

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  // موقع الدبوس في منتصف الخريطة (افتراضياً صنعاء)
  LatLng _mapCenterPosition = const LatLng(15.3694, 44.1910);

  // موقع الهاتف الفعلي (النقطة الزرقاء)
  LatLng? _actualDeviceLocation;

  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _getUserCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- دالة جلب الموقع الفعلي ---
  Future<void> _getUserCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _actualDeviceLocation = LatLng(position.latitude, position.longitude);
        _mapCenterPosition = _actualDeviceLocation!;
        _isLoadingLocation = false;
      });

      _mapController.move(_mapCenterPosition, 16.0);
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      debugPrint("خطأ في جلب الموقع: $e");
    }
  }

  // --- دالة البحث عن مكان ---
  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoadingLocation = true);

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'com.dfood.app'},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);

        if (data.isNotEmpty) {
          final double lat = double.parse(data[0]['lat']);
          final double lon = double.parse(data[0]['lon']);
          final LatLng searchedLocation = LatLng(lat, lon);

          setState(() {
            _mapCenterPosition = searchedLocation;
          });

          _mapController.move(searchedLocation, 15.0);
        } else {
          _showSnackBar(
            "لم يتم العثور على المكان، حاول كتابة اسم مدينة أو شارع معروف.",
          );
        }
      }
    } catch (e) {
      _showSnackBar("حدث خطأ في البحث. يرجى التحقق من الاتصال بالإنترنت.");
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  // --- دالة تأكيد الموقع (تم التعديل هنا للرجوع للصفحة المطلوبة) ---
  // --- دالة تأكيد الموقع (محدثة لتكون ذكية) ---
  Future<void> _confirmLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      String formattedLocation =
          "${_mapCenterPosition.latitude.toStringAsFixed(4)}° N, ${_mapCenterPosition.longitude.toStringAsFixed(4)}° E";

      await prefs.setString('saved_location', formattedLocation);
      await prefs.setDouble('saved_lat', _mapCenterPosition.latitude);
      await prefs.setDouble('saved_lng', _mapCenterPosition.longitude);

      // 1. إظهار رسالة النجاح
      _showSnackBar('تم تحديد موقعك بنجاح', color: Colors.green);

      // 2. تأخير بسيط
      await Future.delayed(const Duration(seconds: 1));

      // 3. التوجيه الذكي
      if (mounted) {
        if (context.canPop()) {
          // إذا أتى من الملف الشخصي (يوجد شاشة سابقة في المكدس) سيرجع إليها
          context.pop();
        } else {
          // إذا أتى من شاشات البداية (لا يوجد شاشة سابقة)، يكمل مساره لتسجيل الدخول
          context.go('/login');
        }
      }
    } catch (e) {
      _showSnackBar("حدث خطأ أثناء حفظ الموقع.");
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _showSnackBar(String message, {Color color = Colors.redAccent}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            // 1. الخريطة
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _mapCenterPosition,
                initialZoom: 14.0,
                onPositionChanged: (MapCamera camera, bool hasGesture) {
                  _mapCenterPosition = camera.center;
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.dfood.app',
                ),

                if (_actualDeviceLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _actualDeviceLocation!,
                        width: 24,
                        height: 24,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F55E8),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.4),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            // 2. دبوس المنتصف
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: Icon(
                  Icons.location_on,
                  size: 50,
                  color: const Color(0xFF0F55E8),
                ),
              ),
            ),

            // 3. الشريط العلوي
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 8),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () =>
                            context.pop(), // الرجوع باستخدام go_router
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          onSubmitted: _searchLocation,
                          decoration: InputDecoration(
                            hintText: "ابحث عن مدينة، حي، شارع...",
                            hintStyle: GoogleFonts.cairo(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            prefixIcon: IconButton(
                              icon: const Icon(
                                Icons.search,
                                color: Color(0xFF0F55E8),
                              ),
                              onPressed: () =>
                                  _searchLocation(_searchController.text),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. زر تأكيد الموقع بالأسفل
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FloatingActionButton(
                      backgroundColor: Colors.white,
                      onPressed: _getUserCurrentLocation,
                      child: const Icon(
                        Icons.my_location,
                        color: Color(0xFF1E1A34),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _confirmLocation,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E1A34), Color(0xFF0F55E8)],
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isLoadingLocation
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                "تأكيد الموقع",
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
