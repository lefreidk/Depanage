import 'package:flutter/material.dart';
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
    if (phone.startsWith('0')) phone = phone.substring(1);
    if (phone.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('رقم غير صحيح')),
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
        SnackBar(content: Text('فشل: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppConfig.appName)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'رقم الهاتف',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _sendOtp,
                child: Text(
                  _isLoading ? 'جاري الإرسال...' : 'إرسال رمز التحقق',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
