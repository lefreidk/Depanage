import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/workshops/presentation/workshops_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/driver/presentation/driver_dashboard_screen.dart';
import '../../features/driver/presentation/driver_onboarding_screen.dart';
import '../../features/settings/providers/app_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final appProv = context.watch<AppProvider>();

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person_rounded, color: AppColors.primary, size: 30),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.user?.name.isNotEmpty == true ? auth.user!.name : 'ديباناج',
                          style: AppTextStyles.title(Colors.white),
                        ),
                        Text(auth.user?.phone ?? '', style: AppTextStyles.bodySmall(Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _tile(context, Icons.person_outline_rounded, 'الملف الشخصي', () => _push(context, const ProfileScreen())),
            _tile(context, Icons.history_rounded, 'سجل الطلبات', () => _push(context, const HistoryScreen())),
            _tile(context, Icons.build_outlined, 'ورشات التصليح', () => _push(context, const WorkshopsScreen())),
            _tile(context, Icons.settings_outlined, 'الإعدادات', () => _push(context, const SettingsScreen())),
            _tile(context, Icons.badge_outlined, 'انضم كسائق شريك', () => _push(context, const DriverOnboardingScreen())),
            const Divider(),
            SwitchListTile(
              secondary: const Icon(Icons.local_shipping_outlined, color: AppColors.primary),
              title: const Text('وضع شريك العمل'),
              value: appProv.isDriverMode,
              activeColor: AppColors.primary,
              onChanged: (value) async {
                await context.read<AppProvider>().setDriverMode(value);
                if (value && context.mounted) {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverDashboardScreen()));
                }
              },
            ),
            const Divider(),
            _tile(context, Icons.logout_rounded, 'تسجيل الخروج', () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            }, color: AppColors.error),
          ],
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Widget _tile(BuildContext context, IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.primary),
      title: Text(label, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }
}
