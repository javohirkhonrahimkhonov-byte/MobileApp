import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/data_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isLoading = false;

  Future<void> _payWithPayme() async {
    setState(() => _isLoading = true);
    
    try {
      final url = await DataService().getPaymeUrl(amount: 10000);
      
      if (url != null && mounted) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Linkni ochib bo'lmadi")));
          }
        }
      } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("To'lov havolasini olib bo'lmadi")));
        }
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Xatolik: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _payWithClick() async {
    setState(() => _isLoading = true);
    
    try {
      final url = await DataService().getClickUrl(amount: 10000);
      
      if (url != null && mounted) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Linkni ochib bo'lmadi")));
          }
        }
      } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("To'lov havolasini olib bo'lmadi")));
        }
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Xatolik: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _payWithUzum() async {
    setState(() => _isLoading = true);
    
    try {
      final url = await DataService().getUzumUrl(amount: 10000);
      
      if (url != null && mounted) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Linkni ochib bo'lmadi")));
          }
        }
      } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("To'lov havolasini olib bo'lmadi")));
        }
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Xatolik: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Premium obuna", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
              ),
              child: Column(
                children: [
                   const Icon(Icons.workspace_premium, size: 60, color: Colors.amber),
                   const SizedBox(height: 10),
                   const Text(
                     "Premium talaba bo'ling",
                     style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                   ),
                   const SizedBox(height: 5),
                   const Text(
                     "Barcha imkoniyatlardan cheklovsiz foydalaning",
                     textAlign: TextAlign.center,
                     style: TextStyle(color: Colors.white70, fontSize: 14),
                   ),
                ],
              ),
            ),
            
            const SizedBox(height: 25),
            
            // 2. Features List
            _buildFeatureItem(Icons.psychology, "AI moduli"),
            _buildFeatureItem(Icons.store, "Bozor"),
            _buildFeatureItem(Icons.verified, "Premium belgisi"),
            _buildFeatureItem(Icons.public, "Ijtimoiy faollik tizimi"),
            
            const SizedBox(height: 30),
            
            // 3. Price
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!)
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Narxi: ", style: TextStyle(fontSize: 16)),
                  Text("10,000 so'm / oy", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
            ),
            
            const SizedBox(height: 30),

            // 3.5 Payme (Branded)
            _buildPaymentButton(
              title: "Payme orqali to'lash",
              color: const Color(0xFF00CCCC), // Payme Brand Color
              logoUrl: "https://logobank.uz:8005/media/logos_png/Payme-01.png",
              fallbackIcon: Icons.payment,
              onTap: _payWithPayme,
              isLoading: _isLoading && !_isLoading, // Hack to not show loading if other is loading? Actually just use _isLoading
            ),
            
            const SizedBox(height: 15),

            // 3.6 Click (Branded)
            _buildPaymentButton(
              title: "Click orqali to'lash",
              color: const Color(0xFF0047BA), // Click Brand Color
              logoUrl: "https://logobank.uz:8005/media/logos_png/Click-01.png", 
              fallbackIcon: Icons.touch_app,
              onTap: _payWithClick,
              isLoading: _isLoading, // We might want separate loading states, but single is fine
            ),
            
            const SizedBox(height: 30),
            

          ],
        ),
      ),
    );
  }

  Widget _buildPaymentButton({
    required String title,
    required Color color,
    required String logoUrl,
    required IconData fallbackIcon,
    required VoidCallback onTap,
    required bool isLoading,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 4,
          shadowColor: color.withOpacity(0.4),
        ),
        child: _isLoading 
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo or Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Image.network(
                    logoUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(fallbackIcon, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 15),
                Text(
                  title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 24),
          const SizedBox(width: 15),
          Text(text, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
