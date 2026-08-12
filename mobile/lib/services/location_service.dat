import 'package:geolocator/geolocator.dart';

class LocationService {
  // الحصول على الموقع الحالي للمستخدم
  static Future<Position> getCurrentPosition() async {
    // 1. التحقق من صلاحية استخدام الموقع
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('خدمة الموقع غير مفعلة. الرجاء تفعيل GPS.');
    }

    // 2. التحقق من إذن الموقع
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('تم رفض إذن الوصول إلى الموقع.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('تم حظر إذن الموقع نهائيًا. الرجاء تعديل الإعدادات.');
    }

    // 3. جلب الموقع الحالي بدقة عالية
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // حساب المسافة بين نقطتين (بالكيلومتر)
  static double calculateDistance({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return Geolocator.distanceBetween(
          startLat,
          startLng,
          endLat,
          endLng,
        ) /
        1000; // تحويل من متر إلى كيلومتر
  }
}
