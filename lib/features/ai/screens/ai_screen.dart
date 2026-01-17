import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';

class AiScreen extends StatelessWidget {
  const AiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2432), // Dark theme background like screenshot? Or keep AppTheme?
      // Screenshot shows dark background with buttons. Let's use a nice dark gradient or solid color. 
      // Actually screenshot looks like Telegram Dark Mode.
      // Let's stick to AppTheme but maybe dark mode specific if requested. 
      // User said "AI modulni ham botdagi tugmalar kabi qilib sozla" (Configure AI module like bot buttons).
      // I'll make it look good.
      appBar: AppBar(
        title: const Text("AI Yordamchi", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E2432),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: const Color(0xFF1E2432),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Sizga qanday yordam bera olaman? Quyidagi mavzulardan birini tanlang:",
              style: TextStyle(color: Colors.white70, fontSize: 15),
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: 20),
            
            _buildAiButton(context, "Stipendiya haqida", Icons.monetization_on, () {}),
            _buildAiButton(context, "Hemis parolini tiklash", Icons.vpn_key, () {}),
            _buildAiButton(context, "Kredit-modul tizimi", Icons.school, () {}),
            _buildAiButton(context, "Dars jadvali", Icons.calendar_today, () {}),
            _buildAiButton(context, "Konspekt qilish (File/Matn)", Icons.note_alt, () {}),
            const Divider(color: Colors.white24, height: 30),
            _buildAiButton(context, "AI bilan suhbat", Icons.chat_bubble, () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tez orada...")));
            }, isPrimary: true),
          ],
        ),
      ),
    );
  }

  Widget _buildAiButton(BuildContext context, String text, IconData icon, VoidCallback onTap, {bool isPrimary = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isPrimary ? Colors.blue.withOpacity(0.2) : const Color(0xFF2B3442),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isPrimary ? Colors.blue.withOpacity(0.5) : const Color(0xFF384252),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: isPrimary ? Colors.blue : const Color(0xFF6B7C93), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isPrimary ? Colors.blue : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white24, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
