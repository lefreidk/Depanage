import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'app_config.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/home/providers/location_provider.dart';
import 'features/request/providers/request_provider.dart';
import 'features/driver/providers/driver_provider.dart';
import 'features/settings/providers/app_provider.dart';
import 'features/splash/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DepannageApp());
}

class DepannageApp extends StatelessWidget {
  const DepannageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()..loadPreferences()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => RequestProvider()),
        ChangeNotifierProvider(create: (_) => DriverProvider()),
      ],
      child: Consumer<AppProvider>(
        builder: (context, appProv, _) {
          return MaterialApp(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: appProv.themeMode,
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar'), Locale('fr'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              return Directionality(textDirection: TextDirection.rtl, child: child!);
            },
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
