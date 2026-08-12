class AppConfig {
  // معلومات التطبيق
  static const String appName = 'ديباناج';
  static const String appVersion = '1.0.0';

  // رابط الخادم الخلفي
  static const String serverUrl = 'https://depannage-server.onrender.com';

  // العملة
  static const String currency = 'دج';

  // إحداثيات افتراضية (الجزائر العاصمة)
  static const double defaultLat = 36.7538;
  static const double defaultLng = 3.0588;
  static const double defaultZoom = 13.0;

  // رقم واتساب الدعم الفني (بصيغة دولية بدون +)
  static const String supportWhatsAppNumber = '213561014379';

  // نسبة العمولة من كل رحلة (15%)
  static const double commissionRate = 0.15;

  // الحد الأدنى لرصيد المحفظة للسائق (دج)
  static const double minWalletBalance = 500;

  // أسعار الكيلومتر حسب فئة المركبة (دج)
  static const Map<String, double> pricePerKm = {
    'motorcycle': 300,
    'car': 500,
    'utility': 500,
    'truck': 900,
    'heavy_truck': 900,
  };

  // فئات المركبات المعطلة المدعومة
  static const Map<String, String> vehicleCategories = {
    'motorcycle': 'دراجة',
    'car': 'سيارة سياحية',
    'utility': 'سيارة نفعية',
    'truck': 'شاحنة خفيفة',
    'heavy_truck': 'شاحنة ثقيلة',
  };
}
