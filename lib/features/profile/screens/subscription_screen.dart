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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Premium Obuna", style: TextStyle(color: Colors.black)),
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
            _buildFeatureItem(Icons.movie_filter_rounded, "AI Konspekt (Video/Audio)"),
            _buildFeatureItem(Icons.analytics_rounded, "Kengaytirilgan Statistika"),
            _buildFeatureItem(Icons.block_flipped, "Reklamasiz rejim"),
            _buildFeatureItem(Icons.support_agent_rounded, "Tezkor qo'llab-quvvatlash"),
            
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

            // 3.5 Payme Automartik
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _payWithPayme,
                icon: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.payment, color: Colors.white), 
                label: Text(_isLoading ? "Yuklanmoqda..." : "Payme orqali to'lash (Avtomatik)", style: const TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00CCCC), // Payme Color roughly
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            

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
