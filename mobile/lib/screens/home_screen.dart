import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme.dart';

const String serverUrl = 'https://name-depannage-server.onrender.com/'; // غيّره

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  IO.Socket? socket;
  LatLng? _currentPosition;
  String _status = 'تحديد الموقع...';
  bool _isRequesting = false;
  int? _nearbyProvidersCount;

  @override
  void initState() {
    super.initState();
    _getLocation();
    _initSocket();
  }

  Future<void> _getLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      Position pos = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(pos.latitude, pos.longitude);
        _status = 'الموقع جاهز';
      });
    } catch (e) {
      setState(() => _status = 'فشل تحديد الموقع');
    }
  }

  void _initSocket() {
    socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });
    socket!.on('connect', (_) => _loginAndRegister());
    socket!.on('new:offer', (data) {
      // الانتقال إلى شاشة العروض
      Navigator.push(context, MaterialPageRoute(builder: (_) => OffersScreen(offer: data)));
    });
    socket!.on('request:created', (data) {
      setState(() {
        _isRequesting = false;
        _nearbyProvidersCount = data['nearbyCount'];
        _status = 'تم إرسال الطلب إلى $_nearbyProvidersCount مزود';
      });
    });
  }

  void _loginAndRegister() async {
    try {
      final res = await http.post(
        Uri.parse('$serverUrl/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': '0500000000'}),
      );
      final user = jsonDecode(res.body);
      socket!.emit('register', user['user']['id']);
    } catch (e) {}
  }

  void _requestTow() {
    if (_currentPosition == null || socket == null) return;
    setState(() {
      _isRequesting = true;
      _status = 'جارٍ إرسال الطلب...';
    });
    socket!.emit('request:tow', {
      'driverId': '1',
      'vehicleType': 'sedan',
      'pickup': {'lat': _currentPosition!.latitude, 'lng': _currentPosition!.longitude},
      'dropoff': {'lat': _currentPosition!.latitude + 0.01, 'lng': _currentPosition!.longitude + 0.01},
      'price': 50.0,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentPosition == null
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  options: MapOptions(center: _currentPosition!, zoom: 14),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.depannage.app',
                    ),
                    MarkerLayer(markers: [
                      Marker(
                        point: _currentPosition!,
                        width: 60,
                        height: 60,
                        child: Icon(Icons.car_repair, color: AppTheme.primaryColor, size: 40),
                      ),
                    ]),
                  ],
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 16,
                  right: 16,
                  child: _buildStatusCard(),
                ),
                Positioned(
                  bottom: 30,
                  left: 24,
                  right: 24,
                  child: _buildRequestButton(),
                ),
              ],
            ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            _isRequesting
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.info_outline, color: AppTheme.primaryColor),
            SizedBox(width: 12),
            Expanded(child: Text(_status)),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestButton() {
    return ElevatedButton.icon(
      onPressed: _isRequesting ? null : _requestTow,
      icon: Icon(Icons.local_shipping),
      label: Text('طلب ونش'),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 60),
      ),
    );
  }
}

// شاشة عرض مؤقتة (مكانها)
class OffersScreen extends StatelessWidget {
  final offer;
  OffersScreen({this.offer});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('عرض سعر')),
      body: Center(child: Text('السعر: ${offer['price']} ريال')),
    );
  }
}
