import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import '../providers/location_provider.dart';
import '../theme.dart';
import '../config.dart';

// نموذج ورشة التصليح
class Workshop {
  final int id;
  final String name;
  final String specialty;
  final String phone;
  final double lat;
  final double lng;
  final double rating;

  Workshop({
    required this.id,
    required this.name,
    required this.specialty,
    required this.phone,
    required this.lat,
    required this.lng,
    required this.rating,
  });

  factory Workshop.fromJson(Map<String, dynamic> json) {
    return Workshop(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      specialty: json['specialty'] ?? '',
      phone: json['phone'] ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
    );
  }
}

class WorkshopsScreen extends StatefulWidget {
  @override
  _WorkshopsScreenState createState() => _WorkshopsScreenState();
}

class _WorkshopsScreenState extends State<WorkshopsScreen> {
  List<Workshop> _workshops = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWorkshops();
  }

  // تحميل الورشات من الخادم
  Future<void> _loadWorkshops() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.serverUrl}/api/workshops'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _workshops = data.map((json) => Workshop.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('فشل تحميل الورشات');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // فتح الهاتف للاتصال بالورشة
  Future<void> _callWorkshop(String phone) async {
    final url = 'tel:$phone';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر فتح الهاتف')),
      );
    }
  }

  // فتح الخرائط للتوجيه إلى الورشة
  Future<void> _openMaps(Workshop workshop) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${workshop.lat},${workshop.lng}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // بديل: فتح تطبيق الخرائط العام
      final fallback = 'geo:${workshop.lat},${workshop.lng}?q=${workshop.lat},${workshop.lng}';
      final fallbackUri = Uri.parse(fallback);
      if (await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر فتح الخرائط')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locationProv = context.watch<LocationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('ورشات التصليح'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadWorkshops,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 60, color: AppTheme.error),
                      SizedBox(height: 16),
                      Text(
                        'فشل تحميل الورشات',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadWorkshops,
                        child: Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : _workshops.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.build_circle, size: 80, color: Colors.grey[300]),
                          SizedBox(height: 16),
                          Text(
                            'لا توجد ورشات شراكة متاحة حالياً',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // الخريطة (نصف الشاشة)
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: FlutterMap(
                            options: MapOptions(
                              center: locationProv.currentPosition ??
                                  LatLng(AppConfig.defaultLat, AppConfig.defaultLng),
                              zoom: AppConfig.defaultZoom,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.depannage.app',
                              ),
                              MarkerLayer(
                                markers: _workshops.map((workshop) {
                                  return Marker(
                                    point: LatLng(workshop.lat, workshop.lng),
                                    width: 40,
                                    height: 40,
                                    child: Icon(
                                      Icons.build,
                                      color: AppTheme.accent,
                                      size: 35,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        // القائمة (النصف الآخر)
                        Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: _workshops.length,
                            itemBuilder: (context, index) {
                              final workshop = _workshops[index];
                              return _buildWorkshopCard(workshop, isDark, locationProv.currentPosition);
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }

  // بطاقة ورشة
  Widget _buildWorkshopCard(Workshop workshop, bool isDark, LatLng? userLocation) {
    // حساب المسافة إذا توفر موقع المستخدم
    double? distanceKm;
    if (userLocation != null) {
      distanceKm = const Distance().as(
        LengthUnit.Kilometer,
        userLocation,
        LatLng(workshop.lat, workshop.lng),
      );
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      color: isDark ? AppTheme.darkSurface : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.build, color: AppTheme.accent),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workshop.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        workshop.specialty,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // التقييم
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 18),
                    SizedBox(width: 4),
                    Text(
                      workshop.rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            // المسافة
            if (distanceKm != null)
              Row(
                children: [
                  Icon(Icons.near_me, color: AppTheme.primary, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'على بعد ${distanceKm.toStringAsFixed(1)} كم',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            SizedBox(height: 12),
            // أزرار الإجراء
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _callWorkshop(workshop.phone),
                    icon: Icon(Icons.phone, size: 18),
                    label: Text('اتصال'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openMaps(workshop),
                    icon: Icon(Icons.directions, size: 18),
                    label: Text('توجيه'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
