import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../app_config.dart';

class LocationProvider extends ChangeNotifier {
  LatLng? _currentPosition;
  String _status = 'جاري تحديد الموقع...';
  bool _isLoading = false;

  LatLng? get currentPosition => _currentPosition;
  String get status => _status;
  bool get isLoading => _isLoading;

  Future<void> getCurrentLocation() async {
    _isLoading = true;
    _status = 'جاري تحديد الموقع...';
    notifyListeners();

    if (kIsWeb) {
      _currentPosition = const LatLng(AppConfig.defaultLat, AppConfig.defaultLng);
      _status = 'وضع المعاينة';
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('خدمة الموقع غير مفعّلة');

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('تم رفض إذن الموقع');
      }

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _currentPosition = LatLng(position.latitude, position.longitude);
      _status = 'تم تحديد الموقع';
    } catch (e) {
      _status = 'تعذر تحديد الموقع';
    }

    _isLoading = false;
    notifyListeners();
  }
}
