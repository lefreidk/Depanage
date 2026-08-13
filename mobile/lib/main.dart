import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// المزودون
import 'providers/app_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/location_provider.dart';
import 'providers/request_provider.dart';

// الشاشات
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/home_screen.dart';
import 'screens/request_screen.dart';
import 'screens/tracking_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/workshops_screen.dart';
import 'screens/driver_onboarding_screen.dart';
import 'screens/completion_rating_screen.dart';
import 'screens/driver_dashboard_screen.dart'; // جديد

// الترجمة
import 'localizations/app_localizations.dart';

// الخدمات والإعدادات
import 'services/storage_service.dart';
import 'theme.dart';
import 'config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  runApp(DepannageApp());
}

class DepannageApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => RequestProvider()),
      ],
      child: Consumer<AppProvider>(
        builder: (context, appProvider, _) {
          return MaterialApp(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appProvider.themeMode,
            locale: appProvider.locale,
            supportedLocales: const [
              Locale('ar'),
              Locale('fr'),
              Locale('en'),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
            ],
            initialRoute: '/',
            routes: {
              '/': (context) => SplashScreen(),
              '/login': (context) => LoginScreen(),
              '/otp': (context) => OtpScreen(phone: ''),
              '/home': (context) => HomeScreen(),
              '/request': (context) => RequestScreen(),
              '/tracking': (context) => TrackingScreen(),
              '/profile': (context) => ProfileScreen(),
              '/history': (context) => HistoryScreen(),
              '/settings': (context) => SettingsScreen(),
              '/workshops': (context) => WorkshopsScreen(),
              '/driver_onboarding': (context) => DriverOnboardingScreen(),
              '/completion_rating': (context) => CompletionRatingScreen(),
              '/driver_dashboard': (context) => DriverDashboardScreen(), // جديد
            },
          );
        },
      ),
    );
  }
}
