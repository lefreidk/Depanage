import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../theme.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // انتظر 3 ثوانٍ ثم انتقل للشاشة المناسبة
    Future.delayed(3.seconds, () {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      if (auth.isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.7),
            ],
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
                  duration: 1.seconds,
                  curve: Curves.elasticOut,
                ),
            SizedBox(height: 24),
            // اسم التطبيق
            Text(
              'ديباناج',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ).animate().fadeIn(delay: 500.ms, duration: 800.ms),
            SizedBox(height: 8),
            // شعار الخدمة
            Text(
              'خدمة الجر بين يديك',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ).animate().fadeIn(delay: 1.seconds, duration: 600.ms),
            SizedBox(height: 60),
            // مؤشر تحميل دائري
            CircularProgressIndicator(
              color: Colors.white,
            ).animate().fadeIn(delay: 1.5.seconds),
          ],
        ),
      ),
    );
  }
}
