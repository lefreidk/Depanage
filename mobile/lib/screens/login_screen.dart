import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
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
  String _completePhone = '';
  bool _isLoading = false;

  // إرسال رمز التحقق إلى رقم الهاتف
  Future<void> _sendOtp() async {
    if (_completePhone.trim().length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الرجاء إدخال رقم جوال صحيح')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // استدعاء خدمة المصادقة لإرسال الرمز عبر الخادم
      await AuthService.sendOtp(_completePhone);
      
      if (!mounted) return;
      
      // الانتقال إلى شاشة التحقق
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OtpScreen(phone: _completePhone)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل إرسال الرمز: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primary.withOpacity(0.1), AppTheme.background],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                SizedBox(height: 60),
                // أيقونة التطبيق مع حركة
                Icon(Icons.local_shipping, size: 100, color: AppTheme.primary)
                    .animate()
                    .scale(duration: 600.ms),
                SizedBox(height: 24),
                // اسم التطبيق
                Text(
                  AppConfig.appName,
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(color: AppTheme.primary),
                ).animate().fadeIn(),
                SizedBox(height: 8),
                // الوصف
                Text(
                  'أدخل رقم جوالك للمتابعة',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                ),
                SizedBox(height: 40),
                // حقل إدخال رقم الهاتف
                IntlPhoneField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'رقم الجوال',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  initialCountryCode: 'DZ', // الجزائر
                  onChanged: (phone) {
                    _completePhone = phone.completeNumber;
                  },
                ).animate().slideX(begin: -0.2, delay: 200.ms),
                SizedBox(height: 24),
                // زر إرسال رمز التحقق
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
    );
  }
}
