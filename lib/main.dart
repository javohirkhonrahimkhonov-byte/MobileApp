import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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
