import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/request_provider.dart';
import '../providers/location_provider.dart';
import '../theme.dart';
import '../config.dart';

class TrackingScreen extends StatefulWidget {
  @override
  _TrackingScreenState createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  @override
  Widget build(BuildContext context) {
    final requestProv = context.watch<RequestProvider>();
    final locationProv = context.watch<LocationProvider>();
    final request = requestProv.currentRequest;

    if (request == null) {
      return Scaffold(
        appBar: AppBar(title: Text('تتبع الونش')),
        body: Center(child: Text('لا يوجد طلب نشط')),
      );
    }

    final pickupLatLng = LatLng(request.pickupLat, request.pickupLng);
    final dropoffLatLng = LatLng(request.dropoffLat, request.dropoffLng);

    return Scaffold(
      appBar: AppBar(title: Text('تتبع الونش')),
      body: Stack(
        children: [
          // الخريطة
          FlutterMap(
            options: MapOptions(
              center: pickupLatLng,
              zoom: AppConfig.defaultZoom,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.depannage.app',
              ),
              MarkerLayer(
                markers: [
                  // موقع الطلب
                  Marker(
                    point: pickupLatLng,
                    width: 50,
                    height: 50,
                    child: Icon(Icons.car_repair, color: AppTheme.primary, size: 40),
                  ),
                  // موقع الوجهة (إذا كانت موجودة)
                  Marker(
                    point: dropoffLatLng,
                    width: 50,
                    height: 50,
                    child: Icon(Icons.flag, color: Colors.green, size: 40),
                  ),
                ],
              ),
            ],
          ),

          // بطاقة الحالة السفلية
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الونش في الطريق',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person, color: AppTheme.primary, size: 20),
                        SizedBox(width: 8),
                        Text(request.providerName ?? 'مزود خدمة'),
                        Spacer(),
                        if (request.providerPlate != null)
                          Text(request.providerPlate!),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.payments, color: AppTheme.primary, size: 20),
                        SizedBox(width: 8),
                        Text('${request.price.round()} ${AppConfig.currency}'),
                      ],
                    ),
                    SizedBox(height: 16),
                    LinearProgressIndicator(
                      color: AppTheme.primary,
                      backgroundColor: Colors.grey[300],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'جاري الوصول إليك...',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ).animate().slideY(begin: 1, duration: 600.ms),
          ),
        ],
      ),
    );
  }
}
