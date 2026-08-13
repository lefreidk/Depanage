import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/location_provider.dart';
import '../providers/request_provider.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';
import '../config.dart';
import '../localizations/app_localizations.dart';
import 'request_screen.dart';

class RequestDetailScreen extends StatefulWidget {
  final String vehicleCategory;
  final LatLng pickupLocation;

  const RequestDetailScreen({
    Key? key,
    required this.vehicleCategory,
    required this.pickupLocation,
  }) : super(key: key);

  @override
  _RequestDetailScreenState createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  LatLng? _dropoffLocation;
  double _distanceKm = 0;
  double _suggestedPrice = 0;
  double _selectedPrice = 0;
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
  }

  double _calculateDistance(LatLng start, LatLng end) {
    final distance = const Distance();
    return distance.as(LengthUnit.Kilometer, start, end);
  }

  double _calculateSuggestedPrice(double distanceKm) {
    final pricePerKm = AppConfig.pricePerKm[widget.vehicleCategory] ?? 500;
    return (distanceKm * pricePerKm).roundToDouble();
  }

  // تعديل التوقيع ليقبل TapPosition و LatLng
  void _handleMapTap(TapPosition position, LatLng point) {
    setState(() {
      _dropoffLocation = point;
      _distanceKm = _calculateDistance(widget.pickupLocation, point);
      _suggestedPrice = _calculateSuggestedPrice(_distanceKm);
      _selectedPrice = _suggestedPrice;
    });
  }

  void _adjustPrice(double delta) {
    setState(() {
      _selectedPrice = (_selectedPrice + delta).clamp(0, 100000).toDouble();
    });
  }

  Future<void> _publishRequest() async {
    if (_dropoffLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الرجاء تحديد الوجهة بالضغط على الخريطة')),
      );
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final requestProv = context.read<RequestProvider>();
      final authProv = context.read<AuthProvider>();

      await requestProv.createRequest(
        driverId: authProv.user?.id ?? '1',
        vehicleType: widget.vehicleCategory,
        pickupLat: widget.pickupLocation.latitude,
        pickupLng: widget.pickupLocation.longitude,
        dropoffLat: _dropoffLocation!.latitude,
        dropoffLng: _dropoffLocation!.longitude,
        price: _selectedPrice,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RequestScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل نشر الطلب: $e')),
      );
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('request_details') ?? 'تفاصيل الطلب'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              center: widget.pickupLocation,
              zoom: 13,
              onTap: _handleMapTap, // الآن التوقيع صحيح
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.depannage.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.pickupLocation,
                    width: 60,
                    height: 60,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.3),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Icon(Icons.car_repair, color: Colors.white, size: 30),
                    ),
                  ),
                  if (_dropoffLocation != null)
                    Marker(
                      point: _dropoffLocation!,
                      width: 50,
                      height: 50,
                      child: Icon(Icons.flag, color: Colors.green, size: 40),
                    ),
                ],
              ),
            ],
          ),

          // البطاقة السفلية للتفاصيل
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.directions_car, color: AppTheme.primary),
                      SizedBox(width: 8),
                      Text(
                        AppConfig.vehicleCategories[widget.vehicleCategory] ??
                            widget.vehicleCategory,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isDark ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  Row(
                    children: [
                      Icon(Icons.route, color: AppTheme.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        _dropoffLocation == null
                            ? lang.translate('tap_to_set_destination') ??
                                'اضغط على الخريطة لتحديد الوجهة'
                            : '${lang.translate('distance') ?? 'المسافة'}: ${_distanceKm.toStringAsFixed(1)} كم',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _dropoffLocation == null ? null : () => _adjustPrice(-100),
                        icon: Icon(Icons.remove_circle_outline, color: AppTheme.primary),
                        iconSize: 32,
                      ),
                      Column(
                        children: [
                          Text(
                            lang.translate('price') ?? 'السعر',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            ),
                          ),
                          Text(
                            '${_selectedPrice.round()} ${AppConfig.currency}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: _dropoffLocation == null ? null : () => _adjustPrice(100),
                        icon: Icon(Icons.add_circle_outline, color: AppTheme.primary),
                        iconSize: 32,
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (_isPublishing || _dropoffLocation == null)
                          ? null
                          : _publishRequest,
                      icon: _isPublishing
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white),
                            )
                          : Icon(Icons.campaign),
                      label: Text(
                        _isPublishing
                            ? (lang.translate('publishing') ?? 'جاري النشر...')
                            : (lang.translate('publish_request') ??
                                'نشر الطلب للسائقين القريبين'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 56),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().slideY(begin: 1, duration: 600.ms, curve: Curves.easeOut),
          ),
        ],
      ),
    );
  }
}
