import 'package:flutter/material.dart';

/// نظام الألوان الموحّد للتطبيق.
/// الفكرة: أزرق ليلي عميق كلون أساسي (ثقة + احترافية) مع برتقالي دافئ
/// كلون تمييز (طاقة + إجراء)، على خلفيات ناعمة ومريحة للعين.
class AppColors {
  AppColors._();

  // الألوان الأساسية
  static const Color primary = Color(0xFF0B3D91); // أزرق ليلي عميق
  static const Color primaryLight = Color(0xFF3A6CC7);
  static const Color primaryDark = Color(0xFF06255C);

  // لون التمييز / الإجراء
  static const Color accent = Color(0xFFFF7A30); // برتقالي دافئ
  static const Color accentLight = Color(0xFFFFA366);

  // حالات
  static const Color success = Color(0xFF1FAA6D);
  static const Color warning = Color(0xFFF5A524);
  static const Color error = Color(0xFFE5484D);
  static const Color info = Color(0xFF3A6CC7);

  // الوضع الفاتح
  static const Color lightBackground = Color(0xFFF6F8FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFEFF3F8);
  static const Color lightBorder = Color(0xFFE3E8EF);
  static const Color lightTextPrimary = Color(0xFF16202B);
  static const Color lightTextSecondary = Color(0xFF6B7785);

  // الوضع الداكن
  static const Color darkBackground = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkSurfaceAlt = Color(0xFF1E2530);
  static const Color darkBorder = Color(0xFF2A323D);
  static const Color darkTextPrimary = Color(0xFFF2F5F8);
  static const Color darkTextSecondary = Color(0xFF9AA6B2);

  // تدرجات جاهزة للاستخدام في البطاقات/الأزرار البارزة
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B3D91), Color(0xFF1B5FC4)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF7A30), Color(0xFFFF9A5A)],
  );

  // ألوان حالة الطلب/الرحلة
  static const Color statusPending = Color(0xFFF5A524);
  static const Color statusAccepted = Color(0xFF3A6CC7);
  static const Color statusInProgress = Color(0xFF0B3D91);
  static const Color statusCompleted = Color(0xFF1FAA6D);
  static const Color statusCancelled = Color(0xFFE5484D);
}
