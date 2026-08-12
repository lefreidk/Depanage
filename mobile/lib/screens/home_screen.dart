import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/location_provider.dart';
import '../providers/request_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../config.dart';
import '../widgets/drawer_menu.dart';
import 'request_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // الفئة المختارة حاليًا (افتراضيًا سيارة سياحية)
  String _selectedCategory = 'car';

  @override
  void initState() {
    super.initState();
    // جلب موقع المستخدم
    context.read<LocationProvider>().getCurrentLocation();
  }

  // فتح شاشة تفاصيل الطلب مع تمرير الفئة المختارة
  void _openRequestDetail() {
    final locationProv = context.read<LocationProvider>();
    if (locationProv.currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الرجاء تحديد الموقع أولاً')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RequestDetailScreen(
          vehicleCategory: _selectedCategory,
          pickupLocation: locationProv.currentPosition!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationProv = context.watch<LocationProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: DrawerMenu(),
      body: locationProv.currentPosition == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primary),
                  SizedBox(height: 16),
                  Text(locationProv.status),
                ],
              ),
            )
          : Stack(
              children: [
                // الخريطة
                FlutterMap(
                  options: MapOptions(
                    center: locationProv.currentPosition,
                    zoom: AppConfig.defaultZoom,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.depannage.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: locationProv.currentPosition!,
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
                      ],
                    ),
                  ],
                ),

                // زر القائمة الجانبية
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  right: 16,
                  child: Card(
                    shape: CircleBorder(),
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    child: IconButton(
                      icon: Icon(Icons.menu, color: AppTheme.primary),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
                ),

                // شريط اختيار فئة المركبة
                Positioned(
                  top: MediaQuery.of(context).padding.top + 70,
                  left: 16,
                  right: 16,
                  child: _buildVehicleSelector(isDark),
                ),

                // شريط البحث الموحد
                Positioned(
                  bottom: 30,
                  left: 16,
                  right: 16,
                  child: _buildSearchBar(isDark),
                ),
              ],
            ),
    );
  }

  // شريط اختيار فئة المركبة (أفقي)
  Widget _buildVehicleSelector(bool isDark) {
    final categories = AppConfig.vehicleCategories;

    return Container(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => SizedBox(width: 8),
        itemBuilder: (context, index) {
          final key = categories.keys.elementAt(index);
          final label = categories[key]!;
          final isSelected = _selectedCategory == key;
          final icon = _getVehicleIcon(key);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = key;
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary
                    : (isDark ? AppTheme.darkSurface : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : Colors.grey.shade300,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: isSelected ? Colors.white : AppTheme.primary,
                    size: 28,
                  ),
                  SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white : AppTheme.textPrimary),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // شريط البحث الموحد
  Widget _buildSearchBar(bool isDark) {
    return Card(
      elevation: 4,
      color: isDark ? AppTheme.darkSurface : Colors.white,
      child: InkWell(
        onTap: _openRequestDetail,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Icon(Icons.search, color: AppTheme.primary),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'ما الوجهة وما التكلفة؟',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward, color: AppTheme.primary),
            ],
          ),
        ),
      ),
    ).animate().slideY(begin: 1, duration: 600.ms, curve: Curves.easeOut);
  }

  // أيقونة الفئة
  IconData _getVehicleIcon(String category) {
    switch (category) {
      case 'motorcycle':
        return Icons.two_wheeler;
      case 'car':
        return Icons.directions_car;
      case 'utility':
        return Icons.car_rental;
      case 'truck':
        return Icons.local_shipping;
      case 'heavy_truck':
        return Icons.fire_truck;
      default:
        return Icons.directions_car;
    }
  }
}
