import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../config.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  // تهيئة التطبيق والتحقق من حالة الدخول
  Future<void> _initApp() async {
    // انتظار تحميل التفضيلات (اللغة والوضع)
    final appProvider = context.read<AppProvider>();
    final authProvider = context.read<AuthProvider>();

    // التحقق من حالة تسجيل الدخول
    await authProvider.checkLoginStatus();

    // عرض شاشة البداية لمدة 3 ثوانٍ مع الحركة
    await Future.delayed(3.seconds);

    if (!mounted) return;

    // التوجيه حسب الحالة
    if (authProvider.isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Color(0xFF121212) : AppTheme.primary;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [Color(0xFF1E1E1E), Color(0xFF121212)]
                : [AppTheme.primary, AppTheme.primary.withOpacity(0.7)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // أيقونة التطبيق مع حركة نبض
            Icon(
              Icons.local_shipping,
              size: 100,
              color: Colors.white,
            ).animate().scale(
                  duration: 800.ms,
                  curve: Curves.elasticOut,
                ),
            SizedBox(height: 24),
            // اسم التطبيق
            Text(
              AppConfig.appName,
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ).animate().fadeIn(delay: 400.ms),
            SizedBox(height: 8),
            // الوصف
            Text(
              'خدمة الجر بين يديك',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ).animate().fadeIn(delay: 800.ms),
            SizedBox(height: 60),
            // مؤشر التحميل
            CircularProgressIndicator(
              color: Colors.white,
            ).animate().fadeIn(delay: 1.2.seconds),
          ],
        ),
      ),
    );
  }
}
