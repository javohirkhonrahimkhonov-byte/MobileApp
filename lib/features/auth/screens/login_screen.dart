import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart'; // NEW
import 'dart:async'; // NEW
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/constants/api_constants.dart'; // For backendUrl
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // To save token manually if needed

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
  
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Check initial link if app was closed
    try {
      final initialUri = await _appLinks.getInitialLink(); // Changed to getInitialLink
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      // Ignore
    }

    // Listen to incoming links
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) async {
    // Scheme: talabahamkor://login?token=...&role=...
    if (uri.host == 'login' && uri.queryParameters.containsKey('token')) {
      final token = uri.queryParameters['token'];
      final role = uri.queryParameters['role'] ?? 'student';
      
      if (token != null) {
        debugPrint("Deep Link Token: $token Role: $role");
        
        // Save Manually (AuthService helper would be better, but direct here is faster for task)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('user_role', role);
        
        // Fetch Profile
        // We reuse AuthService for this
        final authService = AuthService();
        await authService.fetchAndSaveProfile(token); // Force fetch & save
        
        // Trigger Provider Refresh
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Muvaffaqiyatli kirdingiz! ✅"), backgroundColor: Colors.green),
           );
           
           final authProvider = Provider.of<AuthProvider>(context, listen: false);
           await authProvider.checkLoginStatus(); // Will load token & fetch profile
        }
      }
    }
  }

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
  }
  
  // HEMIS OAuth Handler
  Future<void> _loginWithHemisOAuth() async {
      // Open /api/v1/oauth/login
      // which redirects to HEMIS
      // which redirects to /authlog (Nginx) -> /api/v1/oauth/callback
      // which redirects to talabahamkor://login
      
      final url = Uri.parse("${ApiConstants.backendUrl}/oauth/login");
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Brauzerni ochib bo'lmadi")),
        );
      }
  }

  // Telegram Login Logic
  Future<void> _loginWithTelegram() async {
    final authService = AuthService(); 
    
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
    _showLoadingDialog(); 
    
    bool verified = false;
    int attempts = 0;
    while (!verified && attempts < 30 && mounted) {
      await Future.delayed(const Duration(seconds: 2));
      attempts++;
      
      final student = await authService.checkTelegramAuth(uuid);
      if (student != null) {
        verified = true;
        if (mounted) {
          Navigator.pop(context); 
           final authProvider = Provider.of<AuthProvider>(context, listen: false);
           await authProvider.checkLoginStatus(); 
        }
      }
    }
    
    if (!verified && mounted) {
       Navigator.pop(context); 
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
                    "HEMIS tizimidan kirish",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 30),
                  
                  // OAuth Button (PRIMARY)
                   ElevatedButton.icon(
                      onPressed: _loginWithHemisOAuth,
                      icon: const Icon(Icons.school, color: Colors.white),
                      label: const Text("HEMIS orqali kirish", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue, // Brand color
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Divider
                  const Row(children: [
                      Expanded(child: Divider()),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("YOKI")),
                      Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 24),
                  
                  // Login Field (Direct fallback)
                  TextFormField(
                    controller: _loginController,
                    decoration: const InputDecoration(
                      labelText: "Login / ID",
                      prefixIcon: Icon(Icons.person_outline, color: Colors.grey),
                      isDense: true,
                    ),
                    validator: (v) => v!.isEmpty ? "Login kiriting" : null,
                  ),
                  const SizedBox(height: 12),
                  
                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _isObscure,
                    decoration: InputDecoration(
                      labelText: "Parol",
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                      isDense: true,
                      suffixIcon: IconButton(
                        icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                        onPressed: () => setState(() => _isObscure = !_isObscure),
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? "Parol kiriting" : null,
                  ),
                  const SizedBox(height: 16),
                  
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return OutlinedButton(
                        onPressed: auth.isLoading ? null : _submit,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: auth.isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text("Login/Parol bilan kirish"),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // TELEGRAM BUTTON
                  TextButton.icon(
                    onPressed: _loginWithTelegram,
                    icon: const Icon(Icons.telegram, color: Colors.blue),
                    label: const Text("Telegram orqali kirish"),
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
