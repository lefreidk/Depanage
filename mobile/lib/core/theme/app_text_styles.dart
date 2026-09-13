import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// نظام الطباعة الموحّد. نستخدم خط Cairo (يدعم العربية بشكل ممتاز
/// ومصمم خصيصاً لواجهات المستخدم الحديثة) عبر google_fonts.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _base({
    required double size,
    required FontWeight weight,
    required Color color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.cairo(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // عناوين كبيرة (شاشات ترحيب / أرقام بارزة)
  static TextStyle displayLarge(Color color) =>
      _base(size: 34, weight: FontWeight.w800, color: color, height: 1.2);

  static TextStyle displayMedium(Color color) =>
      _base(size: 26, weight: FontWeight.w800, color: color, height: 1.25);

  // عناوين الشاشات والأقسام
  static TextStyle headline(Color color) =>
      _base(size: 20, weight: FontWeight.w700, color: color, height: 1.3);

  static TextStyle title(Color color) =>
      _base(size: 17, weight: FontWeight.w700, color: color, height: 1.3);

  // نصوص أساسية
  static TextStyle bodyLarge(Color color) =>
      _base(size: 16, weight: FontWeight.w500, color: color, height: 1.5);

  static TextStyle bodyMedium(Color color) =>
      _base(size: 14, weight: FontWeight.w500, color: color, height: 1.5);

  static TextStyle bodySmall(Color color) =>
      _base(size: 12.5, weight: FontWeight.w500, color: color, height: 1.4);

  // تسميات وأزرار
  static TextStyle button(Color color) =>
      _base(size: 15.5, weight: FontWeight.w700, color: color, letterSpacing: 0.2);

  static TextStyle caption(Color color) =>
      _base(size: 11.5, weight: FontWeight.w600, color: color, height: 1.3);

  // أرقام بارزة (السعر، المسافة...)
  static TextStyle numericLarge(Color color) =>
      _base(size: 28, weight: FontWeight.w800, color: color, height: 1.1);
}
