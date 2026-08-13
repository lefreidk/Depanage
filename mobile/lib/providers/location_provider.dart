import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/location_service.dart';

class LocationProvider extends ChangeNotifier {
  LatLng? _currentPosition;
  LatLng? _dropoffPosition;
  String _status = 'تحديد الموقع...';
  bool _isLoading = false;

  LatLng? get currentPosition => _currentPosition;
  LatLng? get dropoffPosition => _dropoffPosition;
  String get status => _status;
  bool get isLoading => _isLoading;

  // جلب الموقع الحالي للمستخدم
  Future<void> getCurrentLocation() async {
    _isLoading = true;
    _status = 'جاري تحديد الموقع...';
    notifyListeners();

    // دعم الويب: استخدام موقع افتراضي
    if (kIsWeb) {
      _currentPosition = LatLng(36.7538, 3.0588);
      _status = 'وضع المعاينة (موقع افتراضي)';
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final position = await LocationService.getCurrentPosition();
      _currentPosition = LatLng(position.latitude, position.longitude);
      _status = 'الموقع جاهز';
    } catch (e) {
      _status = 'فشل تحديد الموقع: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  // تعيين موقع الوجهة (يُستدعى عند الضغط على الخريطة)
  void setDropoffPosition(LatLng position) {
    _dropoffPosition = position;
    notifyListeners();
  }

  // مسح موقع الوجهة
  void clearDropoff() {
    _dropoffPosition = null;
    notifyListeners();
  }
}
