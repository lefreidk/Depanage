import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme.dart';
import '../config.dart';
import '../services/auth_service.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الرجاء إدخال رقم جوال صحيح')),
      );
      return;
    }

    // إضافة رمز الجزائر إذا لم يكن موجودًا
    final fullPhone = phone.startsWith('+') ? phone : '+213$phone';

    setState(() => _isLoading = true);

    try {
      await AuthService.sendOtp(fullPhone);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OtpScreen(phone: fullPhone)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل إرسال الرمز: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppTheme.darkBackground, AppTheme.darkBackground]
                : [AppTheme.primary.withOpacity(0.1), AppTheme.lightBackground],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_shipping,
                    size: 100,
                    color: isDark ? Colors.white : AppTheme.primary,
                  ).animate().scale(duration: 600.ms),
                  SizedBox(height: 24),
                  Text(
                    AppConfig.appName,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: isDark ? Colors.white : AppTheme.primary,
                        ),
                  ).animate().fadeIn(),
                  SizedBox(height: 8),
                  Text(
                    'أدخل رقم جوالك للمتابعة',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  SizedBox(height: 40),

                  // حقل إدخال رقم الهاتف بشكل واضح
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                    ),
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(
                        fontSize: 18,
                        color: isDark ? Colors.white : AppTheme.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'مثال: 0550123456',
                        hintStyle: TextStyle(
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                        prefixIcon: Icon(Icons.phone, color: AppTheme.primary),
                        prefixText: '+213 ',
                        prefixStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.textPrimary,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(18),
                      ),
                    ),
                  ).animate().slideX(begin: -0.2, delay: 200.ms),
                  SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendOtp,
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white),
                            )
                          : Text('إرسال رمز التحقق'),
                    ),
                  ).animate().slideY(begin: 0.3, delay: 400.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
