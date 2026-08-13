import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/request_provider.dart';
import '../services/socket_service.dart';
import '../theme.dart';
import '../config.dart';
import 'completion_rating_screen.dart';

class TrackingScreen extends StatefulWidget {
  @override
  _TrackingScreenState createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  LatLng? _truckPosition;

  @override
  void initState() {
    super.initState();
    _listenForProviderLocation();
  }

  // الاستماع لتحديثات موقع السطحة من الخادم
  void _listenForProviderLocation() {
    final socket = SocketService.socket;
    socket.on('provider:location:update', (data) {
      if (mounted && data['lat'] != null && data['lng'] != null) {
        setState(() {
          _truckPosition = LatLng(
            (data['lat'] as num).toDouble(),
            (data['lng'] as num).toDouble(),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    SocketService.socket.off('provider:location:update');
    super.dispose();
  }

  // إتمام الرحلة والتوجه لشاشة التقييم
  void _completeTrip() {
    final requestProv = context.read<RequestProvider>();
    requestProv.completeRequest();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => CompletionRatingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final requestProv = context.watch<RequestProvider>();
    final request = requestProv.currentRequest;

    if (request == null) {
      return Scaffold(
        appBar: AppBar(title: Text('تتبع الونش')),
        body: Center(child: Text('لا يوجد طلب نشط')),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pickupLatLng = LatLng(request.pickupLat, request.pickupLng);
    final dropoffLatLng = LatLng(request.dropoffLat, request.dropoffLng);

    return Scaffold(
      appBar: AppBar(title: Text('تتبع الونش')),
      body: Stack(
        children: [
          // الخريطة
          FlutterMap(
            options: MapOptions(
              center: _truckPosition ?? pickupLatLng,
              zoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.depannage.app',
              ),
              MarkerLayer(
                markers: [
                  // موقع العميل (العطل)
                  Marker(
                    point: pickupLatLng,
                    width: 50,
                    height: 50,
                    child: Icon(Icons.car_repair,
                        color: AppTheme.primary, size: 40),
                  ),
                  // الوجهة
                  Marker(
                    point: dropoffLatLng,
                    width: 50,
                    height: 50,
                    child: Icon(Icons.flag, color: Colors.green, size: 40),
                  ),
                  // موقع السطحة (إذا توفر)
                  if (_truckPosition != null)
                    Marker(
                      point: _truckPosition!,
                      width: 60,
                      height: 60,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Icon(Icons.local_shipping,
                            color: Colors.white, size: 30),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // البطاقة السفلية
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // معلومات السائق
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppTheme.primary.withOpacity(0.1),
                        child: Icon(Icons.person, color: AppTheme.primary),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.providerName ?? 'السائق غير محدد',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppTheme.textPrimary,
                              ),
                            ),
                            if (request.providerPlate != null)
                              Text(
                                'لوحة: ${request.providerPlate}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.lightTextSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  // بانر الدفع النقدي
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.accent),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.payments, color: AppTheme.accent),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'الدفع نقداً حصراً للسائق عند الوصول',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '${request.price.round()} ${AppConfig.currency}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // زر إنهاء الرحلة (مؤقت للتجربة، في النهائي يفعّله السائق)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _completeTrip,
                      icon: Icon(Icons.check_circle_outline),
                      label: Text('إنهاء الرحلة والتقييم'),
                    ),
                  ),
                ],
              ),
            ).animate().slideY(begin: 1, duration: 600.ms),
          ),
        ],
      ),
    );
  }
}
