import 'package:flutter/material.dart';

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
    String phone = _phoneController.text.trim();

    // إزالة الصفر الأول إذا أدخله المستخدم
    if (phone.startsWith('0')) {
      phone = phone.substring(1);
    }

    if (phone.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال رقم جوال صحيح')),
      );
      return;
    }

    final fullPhone = '+213$phone';

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
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.local_shipping,
                size: 80,
                color: isDark ? Colors.white : AppTheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                AppConfig.appName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'أدخل رقم جوالك للمتابعة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(
                  fontSize: 18,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'رقم الهاتف',
                  hintText: '550123456',
                  prefixText: '+213 ',
                  prefixStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                  filled: true,
                  fillColor: isDark ? AppTheme.darkSurface : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppTheme.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(18),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : const Text(
                          'إرسال رمز التحقق',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
