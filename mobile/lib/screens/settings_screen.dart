import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';
import '../config.dart';
import '../localizations/app_localizations.dart';
import 'profile_screen.dart';
import 'driver_onboarding_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  // فتح واتساب الدعم الفني
  Future<void> _openWhatsApp(BuildContext context) async {
    final url = 'https://wa.me/${AppConfig.supportWhatsAppNumber}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر فتح واتساب')),
      );
    }
  }

  // تسجيل الخروج
  Future<void> _logout(BuildContext context, AppLocalizations lang) async {
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
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(lang.translate('settings') ?? 'الإعدادات')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // ========== قسم الحساب ==========
          Text(
            lang.translate('account') ?? 'الحساب',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
          SizedBox(height: 8),
          Card(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            child: ListTile(
              leading: Icon(Icons.person_outline, color: AppTheme.primary),
              title: Text(lang.translate('profile') ?? 'الملف الشخصي'),
              subtitle: Text(lang.translate('profile_subtitle') ?? 'تعديل الاسم والصورة والمركبات'),
              trailing: Icon(Icons.chevron_left),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfileScreen()),
                );
              },
            ),
          ),
          SizedBox(height: 24),

          // ========== قسم التفضيلات ==========
          Text(
            lang.translate('preferences') ?? 'التفضيلات',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
          SizedBox(height: 8),
          Card(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            child: Column(
              children: [
                // اختيار اللغة
                ListTile(
                  leading: Icon(Icons.language, color: AppTheme.primary),
                  title: Text(lang.translate('language') ?? 'اللغة'),
                  trailing: DropdownButton<String>(
                    value: appProvider.locale.languageCode,
                    underline: SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'ar', child: Text('العربية')),
                      DropdownMenuItem(value: 'fr', child: Text('Français')),
                      DropdownMenuItem(value: 'en', child: Text('English')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        context.read<AppProvider>().setLocale(Locale(value));
                      }
                    },
                  ),
                ),
                Divider(height: 1),
                // الوضع الداكن
                SwitchListTile(
                  secondary: Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    color: AppTheme.primary,
                  ),
                  title: Text(lang.translate('dark_mode') ?? 'الوضع الداكن'),
                  value: appProvider.themeMode == ThemeMode.dark,
                  activeColor: AppTheme.primary,
                  onChanged: (value) {
                    context.read<AppProvider>().toggleTheme(value);
                  },
                ),
                Divider(height: 1),
                // وضع شريك العمل
                SwitchListTile(
                  secondary: Icon(Icons.local_shipping, color: AppTheme.primary),
                  title: Text(lang.translate('driver_mode') ?? 'وضع شريك العمل'),
                  subtitle: Text(lang.translate('driver_mode_subtitle') ?? 'استقبال طلبات الجر كسائق'),
                  value: appProvider.isDriverMode,
                  activeColor: AppTheme.primary,
                  onChanged: (value) async {
                    await context.read<AppProvider>().toggleDriverMode(value);
                    if (value) {
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => DriverOnboardingScreen()),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          // ========== قسم الدعم ==========
          Text(
            lang.translate('support') ?? 'الدعم',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
          SizedBox(height: 8),
          Card(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.info_outline, color: AppTheme.primary),
                  title: Text(lang.translate('about_app') ?? 'حول التطبيق'),
                  subtitle: Text('${lang.translate('version') ?? 'الإصدار'} ${AppConfig.appVersion}'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.chat, color: Colors.green),
                  title: Text(lang.translate('contact_whatsapp') ?? 'اتصل بنا عبر واتساب'),
                  onTap: () => _openWhatsApp(context),
                ),
              ],
            ),
          ),
          SizedBox(height: 32),

          // ========== زر تسجيل الخروج ==========
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _logout(context, lang),
              icon: Icon(Icons.logout, color: AppTheme.error),
              label: Text(
                lang.translate('logout') ?? 'تسجيل الخروج',
                style: TextStyle(color: AppTheme.error),
              ),
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
