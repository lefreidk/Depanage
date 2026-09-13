class AppConfig {
  AppConfig._();

  static const String appName = 'ديباناج';
  static const String appVersion = '2.0.0';

  // يُفضّل حقن هذه القيمة عبر --dart-define عند البناء بدل تثبيتها هنا
  static const String serverUrl = String.fromEnvironment(
    'SERVER_URL',
    defaultValue: 'https://depannage-server.onrender.com',
  );

  static const String currency = 'دج';

  static const double defaultLat = 36.7538;
  static const double defaultLng = 3.0588;
  static const double defaultZoom = 13.0;

  static const String supportWhatsAppNumber = '213561014379';

  static const Map<String, double> pricePerKm = {
    'motorcycle': 300,
    'car': 500,
    'utility': 500,
    'truck': 900,
    'heavy_truck': 900,
  };

  static const Map<String, String> vehicleCategories = {
    'motorcycle': 'دراجة',
    'car': 'سيارة سياحية',
    'utility': 'سيارة نفعية',
    'truck': 'شاحنة خفيفة',
    'heavy_truck': 'شاحنة ثقيلة',
  };
}
