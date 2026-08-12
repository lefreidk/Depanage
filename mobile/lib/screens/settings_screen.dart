import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('الإعدادات')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // قسم التفضيلات
          Text(
            'التفضيلات',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('الإشعارات'),
                  subtitle: Text('استقبال تنبيهات الطلبات والعروض'),
                  value: _notificationsEnabled,
                  activeColor: AppTheme.primary,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                ),
                Divider(height: 1),
                SwitchListTile(
                  title: Text('الوضع الداكن'),
                  subtitle: Text('تفعيل المظهر الداكن للتطبيق'),
                  value: _darkModeEnabled,
                  activeColor: AppTheme.primary,
                  onChanged: (value) {
                    setState(() => _darkModeEnabled = value);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('سيتم تفعيل الوضع الداكن في التحديث القادم')),
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          // قسم الحساب
          Text(
            'الحساب',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.person_outline, color: AppTheme.primary),
                  title: Text('الملف الشخصي'),
                  trailing: Icon(Icons.chevron_left),
                  onTap: () {
                    Navigator.pushNamed(context, '/profile');
                  },
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.history, color: AppTheme.primary),
                  title: Text('سجل الطلبات'),
                  trailing: Icon(Icons.chevron_left),
                  onTap: () {
                    Navigator.pushNamed(context, '/history');
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          // قسم حول التطبيق
          Text(
            'حول التطبيق',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.info_outline, color: AppTheme.primary),
                  title: Text('الإصدار'),
                  trailing: Text('1.0.0'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.share, color: AppTheme.primary),
                  title: Text('مشاركة التطبيق'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('قريباً')),
                    );
                  },
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.star, color: AppTheme.primary),
                  title: Text('تقييم التطبيق'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('شكراً لدعمك!')),
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          // زر تسجيل الخروج
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
              icon: Icon(Icons.logout, color: AppTheme.error),
              label: Text('تسجيل الخروج', style: TextStyle(color: AppTheme.error)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.error),
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
