import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';

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

  Future<void> _initApp() async {
    // التحقق من حالة تسجيل الدخول
    final auth = context.read<AuthProvider>();
    await auth.checkLoginStatus();

    // انتظار 3 ثوانٍ لعرض شاشة البداية
    await Future.delayed(3.seconds);

    if (!mounted) return;

    // توجيه المستخدم حسب حالة تسجيل الدخول
    if (auth.isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
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
            colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.7)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping, size: 100, color: Colors.white)
                .animate()
                .scale(duration: 800.ms, curve: Curves.elasticOut),
            SizedBox(height: 24),
            Text(
              'ديباناج',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ).animate().fadeIn(delay: 400.ms),
            SizedBox(height: 8),
            Text(
              'خدمة الجر بين يديك',
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ).animate().fadeIn(delay: 800.ms),
            SizedBox(height: 60),
            CircularProgressIndicator(color: Colors.white)
                .animate()
                .fadeIn(delay: 1.2.seconds),
          ],
        ),
      ),
    );
  }
}
