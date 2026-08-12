import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';

class LocationProvider extends ChangeNotifier {
  LatLng? _currentPosition;
  String _status = 'تحديد الموقع...';
  bool _isLoading = false;

  LatLng? get currentPosition => _currentPosition;
  String get status => _status;
  bool get isLoading => _isLoading;

  // جلب الموقع الحالي
  Future<void> getCurrentLocation() async {
    _isLoading = true;
    _status = 'جاري تحديد الموقع...';
    notifyListeners();

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

  // تعيين موقع الوجهة يدويًا (للاستخدام في شاشة الطلب)
  LatLng? _dropoffPosition;
  LatLng? get dropoffPosition => _dropoffPosition;

  void setDropoffPosition(LatLng position) {
    _dropoffPosition = position;
    notifyListeners();
  }

  // إعادة تعيين الوجهة
  void clearDropoff() {
    _dropoffPosition = null;
    notifyListeners();
  }
}
