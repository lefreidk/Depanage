/// ثوابت المسافات، الانحناءات والارتفاعات — تُستخدم في كل الشاشات
/// لضمان اتساق بصري كامل عبر التطبيق بدل أرقام عشوائية متفرقة.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

class AppRadius {
  AppRadius._();

  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 28;
  static const double pill = 999;
}

class AppElevation {
  AppElevation._();

  static const double none = 0;
  static const double low = 2;
  static const double medium = 6;
  static const double high = 14;
}

class AppDurations {
  AppDurations._();

  static const fast = Duration(milliseconds: 180);
  static const normal = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 500);
}
