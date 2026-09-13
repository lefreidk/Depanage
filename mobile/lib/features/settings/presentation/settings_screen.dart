import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_common_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/presentation/login_screen.dart';
import '../../driver/presentation/driver_dashboard_screen.dart';
import '../../admin/presentation/admin_login_screen.dart';
import '../providers/app_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _openWhatsApp(BuildContext context) async {
    final uri = Uri.parse('https://wa.me/${AppConfig.supportWhatsAppNumber}');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد حقاً تسجيل الخروج؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('تسجيل الخروج', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProv = context.watch<AppProvider>();
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _SectionTitle('التفضيلات'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(
                    appProv.themeMode == ThemeMode.dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text('الوضع الداكن'),
                  value: appProv.themeMode == ThemeMode.dark,
                  activeThumbColor: AppColors.primary,
                  onChanged: (value) => context.read<AppProvider>().setDarkMode(value),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.local_shipping_outlined, color: AppColors.primary),
                  title: const Text('وضع شريك العمل'),
                  subtitle: const Text('استقبال طلبات الجر كسائق', style: TextStyle(fontSize: 12)),
                  value: appProv.isDriverMode,
                  activeThumbColor: AppColors.primary,
                  onChanged: (value) async {
                    await context.read<AppProvider>().setDriverMode(value);
                    if (value && context.mounted) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverDashboardScreen()));
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          _SectionTitle('الدعم'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.chat_rounded, color: AppColors.success),
                  title: const Text('تواصل معنا عبر واتساب'),
                  onTap: () => _openWhatsApp(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.primary),
                  title: const Text('دخول الإدارة'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminLoginScreen())),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.info_outline_rounded, color: colors.textSecondary),
                  title: const Text('حول التطبيق'),
                  subtitle: Text('الإصدار ${AppConfig.appVersion}'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          OutlinedButton.icon(
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            label: const Text('تسجيل الخروج', style: TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, right: 4),
      child: Text(title, style: AppTextStyles.bodyMedium(context.colors.textSecondary)),
    );
  }
}
