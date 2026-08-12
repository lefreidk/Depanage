import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'dart:convert';

// ========== غيّر هذا إلى رابط خادم Render الخاص بك ==========
const String serverUrl = 'https://name-depannage-server.onrender.com/';
// مثال: 'https://depannage-server.onrender.com'
// ==========================================================

void main() {
  runApp(DepannageApp());
}

class DepannageApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ديباناج',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  IO.Socket? socket;
  LatLng? _currentPosition;
  String _status = 'جاري تحديد الموقع...';

  @override
  void initState() {
    super.initState();
    _getLocation();
    _initSocket();
  }

  Future<void> _getLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
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

    socket!.on('connect', (_) {
      // تسجيل دخول وهمي
      _loginAndRegister();
    });

    socket!.on('new:offer', (data) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('عرض سعر'),
          content: Text('السعر: ${data['price']} ريال'),
          actions: [
            TextButton(
              onPressed: () {
                // قبول العرض
                socket!.emit('offer:accept', {
                  'offerId': data['offerId'],
                  'requestId': data['requestId'],
                  'providerId': data['providerId'],
                });
                Navigator.pop(context);
                setState(() => _status = 'تم قبول العرض!');
              },
              child: Text('قبول'),
            ),
          ],
        ),
      );
    });

    socket!.on('offer:accepted', (data) {
      setState(() => _status = 'العرض قُبل، جاري الوصول...');
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
    } catch (e) {
      print('فشل تسجيل الدخول: $e');
    }
  }

  void _requestTow() async {
    if (_currentPosition == null || socket == null) return;
    setState(() => _status = 'جارٍ إرسال الطلب...');
    socket!.emit('request:tow', {
      'driverId': '1',
      'vehicleType': 'sedan',
      'pickup': {
        'lat': _currentPosition!.latitude,
        'lng': _currentPosition!.longitude,
      },
      'dropoff': {
        'lat': _currentPosition!.latitude + 0.01,
        'lng': _currentPosition!.longitude + 0.01,
      },
      'price': 50.0,
    });
    socket!.on('request:created', (data) {
      setState(() => _status = 'تم إرسال الطلب، انتظر العروض...');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ديباناج'), centerTitle: true),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            color: Colors.blue.shade50,
            width: double.infinity,
            child: Text(_status, textAlign: TextAlign.center),
          ),
          Expanded(
            child: _currentPosition == null
                ? Center(child: CircularProgressIndicator())
                : FlutterMap(
                    options: MapOptions(
                      center: _currentPosition,
                      zoom: 13,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.depannage',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentPosition!,
                            width: 40,
                            height: 40,
                            child: Icon(Icons.car_repair,
                                color: Colors.red, size: 40),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _requestTow,
        label: Text('طلب ونش'),
        icon: Icon(Icons.local_shipping),
      ),
    );
  }
}
