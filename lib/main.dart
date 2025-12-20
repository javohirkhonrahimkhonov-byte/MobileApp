import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkLoginStatus()),
      ],
      child: const TalabaHamkorApp(),
    ),
  );
}

class TalabaHamkorApp extends StatelessWidget {
  const TalabaHamkorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TalabaHamkor',
      theme: AppTheme.lightTheme,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          switch (auth.status) {
            case AuthStatus.authenticated:
              return const HomeScreen();
            case AuthStatus.authenticating:
            case AuthStatus.unauthenticated:
            default:
              return const LoginScreen();
          }
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
