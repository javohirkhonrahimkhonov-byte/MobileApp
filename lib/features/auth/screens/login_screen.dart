import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // Add url_launcher
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'package:http/http.dart' as http; // Needed for internal logic if not in provider, but better to use existing AuthService through provider
import '../../../core/services/auth_service.dart'; // Import AuthService explicitly if needed for static access or distinct instance
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isObscure = true;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final error = await auth.login(
      _loginController.text.trim(),
      _passwordController.text.trim(),
    );

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  // Telegram Login Logic
  Future<void> _loginWithTelegram() async {
    final authService = AuthService(); // Create instance or get from provider
    
    // 1. Init
    final data = await authService.initTelegramAuth();
    if (data == null || !mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Telegram serveriga ulanib bo'lmadi")),
      );
      return;
    }

    final uuid = data['uuid']!;
    final url = data['url']!;

    // 2. Launch Telegram
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Telegram ilovasini ochib bo'lmadi")),
      );
    }

    // 3. Poll
    _showLoadingDialog(); // Show loading indicator
    
    bool verified = false;
    int attempts = 0;
    while (!verified && attempts < 30 && mounted) {
      await Future.delayed(const Duration(seconds: 2));
      attempts++;
      
      final student = await authService.checkTelegramAuth(uuid);
      if (student != null) {
        verified = true;
        if (mounted) {
          Navigator.pop(context); // Close dialog
          // Update Provider Manually if needed or reload app state
          // For now, assume global provider needs update or app reload
          // Ideally: context.read<AuthProvider>().setStudent(student);
           
           // Simple Hack: Reload App Logic by popping login
           // Or direct navigation
           // The AuthWrapper should handle it if 'auth_token' is saved
           // Let's notify Provider to reload
           final authProvider = Provider.of<AuthProvider>(context, listen: false);
           await authProvider.checkLoginStatus(); // Re-check token
        }
      }
    }
    
    if (!verified && mounted) {
       Navigator.pop(context); // Close dialog
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login vaqti tugadi yoki bekor qilindi.")),
      );
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Telegram orqali tasdiqlash kutilmoqda..."),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Branding Logo
                  Hero(
                    tag: 'app_logo',
                    child: Image.asset(
                      'assets/logo.png',
                      height: 120,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "tengdosh",
                    textAlign: TextAlign.center,
                    style: AppTheme.lightTheme.textTheme.displayMedium?.copyWith(
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "HEMIS tizimi orqali kiring",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 30),
                  
                  // Login Field
                  
                  // Login Field
                  TextFormField(
                    controller: _loginController,
                    decoration: const InputDecoration(
                      labelText: "HEMIS ID / Login",
                      prefixIcon: Icon(Icons.person_outline, color: AppTheme.primaryBlue),
                    ),
                    validator: (v) => v!.isEmpty ? "Login kiriting" : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _isObscure,
                    decoration: InputDecoration(
                      labelText: "Parol",
                      prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryBlue),
                      suffixIcon: IconButton(
                        icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                        onPressed: () => setState(() => _isObscure = !_isObscure),
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? "Parol kiriting" : null,
                  ),
                  const SizedBox(height: 24),
                  
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return ElevatedButton(
                        onPressed: auth.isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 24, 
                                height: 24, 
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                              )
                            : const Text(
                                "Kirish",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // TELEGRAM BUTTON
                  OutlinedButton.icon(
                    onPressed: _loginWithTelegram,
                    icon: const Icon(Icons.telegram, color: Colors.blue),
                    label: const Text("Telegram orqali kirish", style: TextStyle(color: Colors.blue)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
