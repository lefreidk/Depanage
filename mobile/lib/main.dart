import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// المزودون
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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => RequestProvider()),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
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
        },
      ),
    );
  }
}
