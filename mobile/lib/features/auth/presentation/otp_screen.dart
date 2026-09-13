import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../home/presentation/home_screen.dart';
import '../providers/auth_provider.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  Timer? _resendTimer;
  int _secondsLeft = 60;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _secondsLeft = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft == 0) {
        timer.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_otpController.text.length != 4) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyOtp(widget.phone, _otpController.text);

    if (!mounted) return;

    if (ok) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      final message = auth.lastError?.message ?? 'رمز التحقق غير صحيح';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      _otpController.clear();
    }
  }

  Future<void> _resend() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.sendOtp(widget.phone);
    if (!mounted) return;
    if (ok) {
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إعادة إرسال الرمز')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colors = context.colors;

    final pinTheme = PinTheme(
      width: 58,
      height: 58,
      textStyle: AppTextStyles.headline(colors.textPrimary),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.border, width: 1.4),
      ),
    );

    final focusedPinTheme = pinTheme.copyDecorationWith(
      border: Border.all(color: AppColors.primary, width: 2),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('تأكيد الرقم')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(color: colors.surfaceAlt, shape: BoxShape.circle),
                child: const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 40),
              ).animate().scale(duration: AppDurations.slow, curve: Curves.elasticOut),
              const SizedBox(height: AppSpacing.lg),

              Text('أدخل رمز التحقق', style: AppTextStyles.headline(colors.textPrimary)),
              const SizedBox(height: AppSpacing.xs),
              Text.rich(
                TextSpan(
                  style: AppTextStyles.bodyMedium(colors.textSecondary),
                  children: [
                    const TextSpan(text: 'تم إرسال رمز مكوّن من 4 أرقام عبر واتساب إلى\n'),
                    TextSpan(text: widget.phone, style: AppTextStyles.bodyMedium(AppColors.primary)),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              Center(
                child: Pinput(
                  length: 4,
                  controller: _otpController,
                  defaultPinTheme: pinTheme,
                  focusedPinTheme: focusedPinTheme,
                  onCompleted: (_) => _verify(),
                ).animate().scale(delay: 150.ms),
              ),

              const SizedBox(height: AppSpacing.xxl),

              AppButton(
                label: auth.isVerifyingOtp ? 'جاري التحقق...' : 'تأكيد',
                isLoading: auth.isVerifyingOtp,
                onPressed: _verify,
              ),

              const SizedBox(height: AppSpacing.lg),

              Center(
                child: _secondsLeft > 0
                    ? Text(
                        'يمكنك إعادة الإرسال بعد $_secondsLeft ثانية',
                        style: AppTextStyles.bodyMedium(colors.textSecondary),
                      )
                    : TextButton(
                        onPressed: _resend,
                        child: const Text('إعادة إرسال الرمز'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
