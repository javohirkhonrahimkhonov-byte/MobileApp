import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

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
            
            // 4. Payment Info (Manual)
            const Text(
              "To'lov qilish (Qo'lda):",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  const Text("Quyidagi kartaga o'tkazma qiling:", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "8600 1234 5678 9012",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20, color: AppTheme.primaryBlue),
                        onPressed: () {
                          Clipboard.setData(const ClipboardData(text: "8600123456789012"));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Buferga nusxalandi")));
                        },
                      )
                    ],
                  ),
                  const Text("Toshmat Eshmatov", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  const Text(
                    "To'lov qilgach, chekni (skrinshot) administratorga Telegram orqali yuboring:",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Open telegram bot link? Or just show username
                      // For now, let's just show a dialog or assume they know the bot.
                      // Or Launch URL.
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tez orada avtomatik Click ulanadi!")));
                    }, 
                    icon: const Icon(Icons.send_rounded),
                    label: const Text("Chekni yuborish (Telegram)"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0088CC),
                      foregroundColor: Colors.white,
                    )
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            const Text(
              "Tez orada Click va Payme orqali avtomatik to'lov qo'shiladi.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
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
