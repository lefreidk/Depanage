import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../localizations/app_localizations.dart';
import '../screens/profile_screen.dart';
import '../screens/history_screen.dart';
import '../screens/workshops_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/driver_dashboard_screen.dart'; // ← جديد

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final appProvider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = AppLocalizations.of(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              auth.user?.name ?? lang.translate('app_name') ?? 'ديباناج',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              auth.user?.phone ?? '',
              style: TextStyle(color: Colors.white70),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: AppTheme.primary, size: 40),
            ),
            decoration: BoxDecoration(color: AppTheme.primary),
          ),
          ListTile(
            leading: Icon(Icons.home_outlined, color: AppTheme.primary),
            title: Text(lang.translate('home') ?? 'الرئيسية'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
            },
          ),
          ListTile(
            leading: Icon(Icons.person_outline, color: AppTheme.primary),
            title: Text(lang.translate('profile') ?? 'الملف الشخصي'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.history, color: AppTheme.primary),
            title: Text(lang.translate('history') ?? 'سجل الطلبات'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HistoryScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.build, color: AppTheme.primary),
            title: Text(lang.translate('workshops') ?? 'ورشات التصليح'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => WorkshopsScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.settings_outlined, color: AppTheme.primary),
            title: Text(lang.translate('settings') ?? 'الإعدادات'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SettingsScreen()),
              );
            },
          ),
          Divider(),
          SwitchListTile(
            secondary: Icon(Icons.local_shipping, color: AppTheme.primary),
            title: Text(lang.translate('driver_mode') ?? 'وضع شريك العمل'),
            subtitle: Text(
              lang.translate('driver_mode_subtitle') ?? 'استقبال طلبات الجر كسائق',
              style: TextStyle(fontSize: 12),
            ),
            value: appProvider.isDriverMode,
            activeColor: AppTheme.primary,
            onChanged: (value) async {
              await context.read<AppProvider>().toggleDriverMode(value);
              if (value && context.mounted) {
                Navigator.pop(context); // إغلاق القائمة
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DriverDashboardScreen()),
                );
              }
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: AppTheme.error),
            title: Text(
              lang.translate('logout') ?? 'تسجيل الخروج',
              style: TextStyle(color: AppTheme.error),
            ),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (dialogContext) {
                  return AlertDialog(
                    title: Text(lang.translate('logout') ?? 'تسجيل الخروج'),
                    content: Text(lang.translate('logout_confirm') ?? 'هل تريد حقاً تسجيل الخروج؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: Text(lang.translate('cancel') ?? 'إلغاء'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: Text(
                          lang.translate('logout') ?? 'تسجيل الخروج',
                          style: TextStyle(color: AppTheme.error),
                        ),
                      ),
                    ],
                  );
                },
              );

              if (confirm == true) {
                await context.read<AuthProvider>().logout();
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }
}
