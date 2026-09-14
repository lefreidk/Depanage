import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/auth_provider.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'أدخل رقم هاتفك';
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 9) return 'رقم الهاتف غير صحيح';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    var phone = _phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.startsWith('0')) phone = phone.substring(1);
    final fullPhone = '+213$phone';

    final auth = context.read<AuthProvider>();
    final sent = await auth.sendOtp(fullPhone);

    if (!mounted) return;

    if (sent) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => OtpScreen(phone: fullPhone)));
    } else {
      final message = auth.lastError?.message ?? 'تعذر إرسال الرمز';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colors = context.colors;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // رأس متدرّج بشعار التطبيق
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.xl)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 46),
                  ).animate().scale(duration: AppDurations.slow, curve: Curves.elasticOut),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    AppConfig.appName,
                    style: AppTextStyles.displayMedium(Colors.white),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'خدمة الجر بين يديك، أينما كنت',
                    style: AppTextStyles.bodyMedium(Colors.white.withOpacity(0.85)),
                  ).animate().fadeIn(delay: 350.ms),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      Text('مرحباً بك 👋', style: AppTextStyles.headline(colors.textPrimary)),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'أدخل رقم هاتفك لإرسال رمز التحقق عبر واتساب',
                        style: AppTextStyles.bodyMedium(colors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: AppTextStyles.bodyLarge(colors.textPrimary),
                        validator: _validatePhone,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          labelText: 'رقم الهاتف',
                          hintText: '05XX XX XX XX',
                          prefixIcon: Padding(
                            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                            child: Text('🇩🇿  +213', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          prefixIconConstraints: BoxConstraints(minWidth: 0),
                        ),
                      ).animate().slideY(begin: 0.2, duration: AppDurations.normal),

                      const SizedBox(height: AppSpacing.xl),

                      AppButton(
                        label: auth.isSendingOtp ? 'جاري الإرسال...' : 'إرسال رمز التحقق',
                        icon: Icons.arrow_forward_rounded,
                        isLoading: auth.isSendingOtp,
                        onPressed: _submit,
                      ).animate().slideY(begin: 0.3, delay: 100.ms, duration: AppDurations.normal),

                      const SizedBox(height: AppSpacing.lg),

                      Center(
                        child: Text(
                          'بالمتابعة أنت توافق على شروط الاستخدام وسياسة الخصوصية',
                          style: AppTextStyles.caption(colors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
