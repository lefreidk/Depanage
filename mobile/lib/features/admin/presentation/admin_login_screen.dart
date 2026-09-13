import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../data/admin_repository.dart';
import 'admin_dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repository = AdminRepository();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_usernameController.text.trim().isEmpty || _passwordController.text.isEmpty) return;

    setState(() => _isLoading = true);
    final result = await _repository.login(_usernameController.text.trim(), _passwordController.text);
    if (!mounted) return;
    setState(() => _isLoading = false);

    result.when(
      success: (_) => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
      failure: (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('دخول الإدارة')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(color: colors.surfaceAlt, shape: BoxShape.circle),
                child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary, size: 44),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('لوحة تحكم ديباناج', style: AppTextStyles.headline(colors.textPrimary)),
              const SizedBox(height: AppSpacing.xl),
              AppTextField(label: 'اسم المستخدم', controller: _usernameController, prefixIcon: Icons.person_outline),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'كلمة المرور',
                controller: _passwordController,
                obscureText: true,
                prefixIcon: Icons.lock_outline_rounded,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(label: 'دخول', isLoading: _isLoading, onPressed: _login),
            ],
          ),
        ),
      ),
    );
  }
}
