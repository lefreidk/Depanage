import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../theme.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  OtpScreen({required this.phone});

  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // التحقق من الرمز عبر الخادم
  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 4) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await AuthService.verifyOtp(widget.phone, _otpController.text);
      // تحديث AuthProvider بالمستخدم الجديد
      await context.read<AuthProvider>().loginUser(user);

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'رمز التحقق غير صحيح';
      });
    }
  }

  // إعادة إرسال الرمز
  Future<void> _resendOtp() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.sendOtp(widget.phone);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إعادة إرسال الرمز')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل إعادة الإرسال: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: TextStyle(
        fontSize: 20,
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.primary),
        borderRadius: BorderRadius.circular(12),
      ),
    );

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
                // أيقونة التحقق
                Icon(Icons.verified_user, size: 80, color: AppTheme.secondary)
                    .animate()
                    .scale(duration: 600.ms),
                SizedBox(height: 24),
                // العنوان
                Text(
                  'تأكيد رقم الجوال',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: AppTheme.textPrimary),
                ).animate().fadeIn(),
                SizedBox(height: 8),
                // وصف الرمز المرسل
                Text(
                  'تم إرسال رمز التحقق إلى ${widget.phone}',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'الرجاء التحقق من واتساب',
                  style: TextStyle(color: AppTheme.primary, fontSize: 14),
                ),
                SizedBox(height: 40),
                // حقول إدخال الرمز
                Pinput(
                  length: 4,
                  controller: _otpController,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: defaultPinTheme.copyBorderWith(
                    border: Border.all(color: AppTheme.primary, width: 2),
                  ),
                  onCompleted: (pin) => _verifyOtp(),
                ).animate().scale(delay: 200.ms),
                SizedBox(height: 24),
                // زر التأكيد
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white),
                          )
                        : Text('تأكيد'),
                  ),
                ).animate().slideY(begin: 0.3, delay: 400.ms),
                SizedBox(height: 16),
                // إعادة إرسال الرمز
                TextButton(
                  onPressed: _isLoading ? null : _resendOtp,
                  child: Text(
                    'إعادة إرسال الرمز',
                    style: TextStyle(color: AppTheme.primary),
                  ),
                ),
                // عرض رسالة خطأ إن وجدت
                if (_errorMessage != null) ...[
                  SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: AppTheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
