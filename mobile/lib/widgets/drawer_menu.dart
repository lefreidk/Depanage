import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../screens/profile_screen.dart';
import '../screens/history_screen.dart';
import '../screens/workshops_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/driver_onboarding_screen.dart';
import '../screens/login_screen.dart';

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final appProvider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // رأس القائمة
          UserAccountsDrawerHeader(
            accountName: Text(
              auth.user?.name ?? 'مستخدم ديباناج',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(
              auth.user?.phone ?? '',
              style: TextStyle(color: Colors.white70),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: AppTheme.primary, size: 40),
            ),
            decoration: BoxDecoration(
              color: AppTheme.primary,
            ),
          ),

          // الرئيسية
          ListTile(
            leading: Icon(Icons.home_outlined, color: AppTheme.primary),
            title: Text('الرئيسية'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
            },
          ),

          // الملف الشخصي
          ListTile(
            leading: Icon(Icons.person_outline, color: AppTheme.primary),
            title: Text('الملف الشخصي'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileScreen()),
              );
            },
          ),

          // سجل الطلبات
          ListTile(
            leading: Icon(Icons.history, color: AppTheme.primary),
            title: Text('سجل الطلبات'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HistoryScreen()),
              );
            },
          ),

          // ورشات التصليح
          ListTile(
            leading: Icon(Icons.build, color: AppTheme.primary),
            title: Text('ورشات التصليح'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => WorkshopsScreen()),
              );
            },
          ),

          // الإعدادات
          ListTile(
            leading: Icon(Icons.settings_outlined, color: AppTheme.primary),
            title: Text('الإعدادات'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SettingsScreen()),
              );
            },
          ),

          Divider(),

          // وضع شريك العمل
          SwitchListTile(
            secondary: Icon(Icons.local_shipping, color: AppTheme.primary),
            title: Text(
              'وضع شريك العمل',
              style: TextStyle(
                color: isDark ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            subtitle: Text(
              'استقبال طلبات الجر كسائق',
              style: TextStyle(fontSize: 12),
            ),
            value: appProvider.isDriverMode,
            activeColor: AppTheme.primary,
            onChanged: (value) async {
              await context.read<AppProvider>().toggleDriverMode(value);
              if (value) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DriverOnboardingScreen()),
                );
              }
            },
          ),

          Divider(),

          // تسجيل الخروج
          ListTile(
            leading: Icon(Icons.logout, color: AppTheme.error),
            title: Text(
              'تسجيل الخروج',
              style: TextStyle(color: AppTheme.error),
            ),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (dialogContext) {
                  return AlertDialog(
                    title: Text('تسجيل الخروج'),
                    content: Text('هل تريد حقاً تسجيل الخروج؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: Text('إلغاء'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: Text(
                          'تسجيل الخروج',
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
