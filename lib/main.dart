import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/notification_provider.dart';
import 'core/services/data_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'core/theme/app_theme.dart';

import 'dart:io';

void main() {
  HttpOverrides.global = MyHttpOverrides(); // Bypass SSL issues for Emulator
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        Provider(create: (_) => DataService()),
      ],
      child: const TalabaHamkorApp(),
    ),
  );
}

// Bypass Bad SSL Certificate (Android Emulator / University Server issues)
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class TalabaHamkorApp extends StatelessWidget {
  const TalabaHamkorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'tengdosh',
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('uz', 'UZ'), 
        Locale('ru', 'RU'),
        Locale('en', 'US'),
      ],
      // Force Uzbek as default if system is not supported or mixed
      locale: const Locale('uz', 'UZ'),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isLoading) {
             return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (auth.isAuthenticated) {
            return const HomeScreen();
          }
          return const LoginScreen();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
