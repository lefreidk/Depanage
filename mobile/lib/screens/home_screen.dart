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
import '../widgets/drawer_menu.dart';
import '../widgets/vehicle_selector.dart';
import '../widgets/price_input.dart';
import 'request_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _vehicleType = 'سيدان';
  double _price = 3000;

  @override
  void initState() {
    super.initState();
    context.read<LocationProvider>().getCurrentLocation();
  }

  void _showRequestSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => _RequestSheet(
        vehicleType: _vehicleType,
        price: _price,
        onVehicleChanged: (type) {
          setState(() => _vehicleType = type);
        },
        onPriceChanged: (price) {
          setState(() => _price = price);
        },
        onSubmit: () {
          final locationProv = context.read<LocationProvider>();
          final requestProv = context.read<RequestProvider>();
          final authProv = context.read<AuthProvider>();

          if (locationProv.currentPosition == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('الرجاء تحديد الموقع أولاً')),
            );
            return;
          }

          final pickup = locationProv.currentPosition!;
          final dropoff = LatLng(
            pickup.latitude + 0.01,
            pickup.longitude + 0.01,
          );

          requestProv.createRequest(
            driverId: authProv.user?.id ?? '1',
            vehicleType: _vehicleType,
            pickupLat: pickup.latitude,
            pickupLng: pickup.longitude,
            dropoffLat: dropoff.latitude,
            dropoffLng: dropoff.longitude,
            price: _price,
          );

          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RequestScreen()),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: DrawerMenu(), // القائمة الجانبية
      body: Consumer2<LocationProvider, RequestProvider>(
        builder: (context, locationProv, requestProv, _) {
          if (locationProv.currentPosition == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primary),
                  SizedBox(height: 16),
                  Text(locationProv.status),
                ],
              ),
            );
          }

          return Stack(
            children: [
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
                left: 16,
                child: Card(
                  shape: CircleBorder(),
                  child: IconButton(
                    icon: Icon(Icons.menu, color: AppTheme.primary),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  ),
                ),
              ),

              // شريط الحالة
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 70,
                right: 16,
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.my_location, color: AppTheme.primary, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            locationProv.status,
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        if (requestProv.isWaitingOffers)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.accent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'بانتظار العروض',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // زر الطلب
              Positioned(
                bottom: 30,
                left: 24,
                right: 24,
                child: ElevatedButton.icon(
                  onPressed: _showRequestSheet,
                  icon: Icon(Icons.local_shipping),
                  label: Text('طلب ونش'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 56),
                    backgroundColor: AppTheme.primary,
                    shadowColor: AppTheme.primary.withOpacity(0.3),
                    elevation: 8,
                  ),
                ).animate().slideY(begin: 1, duration: 600.ms, curve: Curves.easeOut),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RequestSheet extends StatelessWidget {
  final String vehicleType;
  final double price;
  final Function(String) onVehicleChanged;
  final Function(double) onPriceChanged;
  final VoidCallback onSubmit;

  _RequestSheet({
    required this.vehicleType,
    required this.price,
    required this.onVehicleChanged,
    required this.onPriceChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 24),
          Text('طلب خدمة جر', style: Theme.of(context).textTheme.headlineSmall),
          SizedBox(height: 24),
          VehicleSelector(
            selected: vehicleType,
            onChanged: onVehicleChanged,
          ),
          SizedBox(height: 16),
          PriceInput(
            initialPrice: price,
            onChanged: onPriceChanged,
          ),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSubmit,
              child: Text('تأكيد الطلب'),
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
