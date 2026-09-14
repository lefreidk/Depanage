import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../auth/presentation/login_screen.dart';
import '../auth/providers/auth_provider.dart';
import '../home/presentation/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final auth = context.read<AuthProvider>();
    await auth.bootstrap();
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => auth.isLoggedIn ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 90)
                  .animate()
                  .scale(duration: 700.ms, curve: Curves.elasticOut),
              const SizedBox(height: AppSpacing.lg),
              Text(
                AppConfig.appName,
                style: AppTextStyles.displayLarge(Colors.white),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'خدمة الجر بين يديك',
                style: AppTextStyles.bodyLarge(Colors.white.withOpacity(0.85)),
              ).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: AppSpacing.xxxl),
              const CircularProgressIndicator(color: Colors.white).animate().fadeIn(delay: 800.ms),
            ],
          ),
        ),
      ),
    );
  }
}
