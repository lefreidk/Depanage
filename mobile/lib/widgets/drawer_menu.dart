import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(auth.user?.name ?? 'مستخدم'),
            accountEmail: Text(auth.user?.phone ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: AppTheme.primary, size: 40),
            ),
            decoration: BoxDecoration(
              color: AppTheme.primary,
            ),
          ),
          ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('الملف الشخصي'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: Icon(Icons.history),
            title: Text('سجل الطلبات'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/history');
            },
          ),
          ListTile(
            leading: Icon(Icons.settings_outlined),
            title: Text('الإعدادات'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: AppTheme.error),
            title: Text('تسجيل الخروج', style: TextStyle(color: AppTheme.error)),
            onTap: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().logout();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
        ],
      ),
    );
  }
}
