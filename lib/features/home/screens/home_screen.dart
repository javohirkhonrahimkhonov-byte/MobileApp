import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/data_service.dart'; 
// Using package imports is safer but let's correct relative first to match file system if package name is tricky
import 'package:talabahamkor_mobile/core/services/data_service.dart';
import 'package:talabahamkor_mobile/core/theme/app_theme.dart';
import 'package:talabahamkor_mobile/core/providers/auth_provider.dart';
import 'package:talabahamkor_mobile/features/activities/screens/activities_screen.dart';
import 'package:talabahamkor_mobile/features/profile/screens/profile_screen.dart';
import 'package:talabahamkor_mobile/features/community/screens/community_screen.dart';
import 'package:talabahamkor_mobile/features/student_module/screens/student_module_screen.dart';
import 'package:talabahamkor_mobile/features/student_module/widgets/student_dashboard_widgets.dart';

// ... (existing imports)

  @override
  Widget build(BuildContext context) {
    // Screens for BottomNav
    final List<Widget> screens = [
      _buildHomeContent(),           // 0: Home (Dashboard)
      StudentModuleScreen(),         // 1: Yangiliklar (Ex-Talaba)
      AiScreen(),                    // 2: AI
      CommunityScreen(),             // 3: Choyxona
      ProfileScreen(),               // 4: Profile
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite, 
      body: SafeArea(
        child: screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: AppTheme.primaryBlue,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: "Asosiy"),
            BottomNavigationBarItem(icon: Icon(Icons.newspaper_rounded), label: "Yangiliklar"),
            BottomNavigationBarItem(icon: Icon(Icons.smart_toy_rounded), label: "AI"),
            BottomNavigationBarItem(icon: Icon(Icons.forum_rounded), label: "Choyxona"),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profil"),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header (Avatar + Name + Status)
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[200],
                child: const Icon(Icons.person, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Salom, ${() {
                      final name = _profile?['full_name'] ?? 'Talaba';
                      final parts = name.split(' ');
                      return parts.length > 1 ? parts[1] : parts[0];
                    }()}!",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.accentGreen, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text("Online", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Stack(
                children: [
                  IconButton(icon: const Icon(Icons.notifications_none_rounded, size: 28), onPressed: () {}),
                  Positioned(right: 12, top: 12, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                onPressed: _logout,
                tooltip: "Chiqish",
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 2. GPA Module (Full Width)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryBlue, Color(0xFF0052CC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: (_dashboard?['gpa'] ?? 0.0) / 5.0,
                        strokeWidth: 8,
                        color: AppTheme.accentGreen,
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                      Text(
                        "${_dashboard?['gpa'] ?? '0.0'}", 
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Joriy Semestr", 
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "A'lo natija! 🏆", 
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
                      ),
                      Text(
                        "Guruh: ${_profile?['group_number'] ?? '...'}", 
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. Module Grid (Dashboard)
          const Text(
            "Xizmatlar",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              DashboardCard(
                title: "Davomat",
                icon: Icons.calendar_today_rounded,
                color: Colors.green,
                onTap: () => _showMock("Davomat"),
              ),
              DashboardCard(
                title: "Ijtimoiy Faollik",
                icon: Icons.star_rounded,
                color: Colors.orange,
                onTap: () => _showMock("Ijtimoiy Faollik"),
              ),
              DashboardCard(
                title: "Hujjatlar",
                icon: Icons.folder_open_rounded,
                color: Colors.blue,
                onTap: () => _showMock("Hujjatlar"),
              ),
              DashboardCard(
                title: "Sertifikatlar",
                icon: Icons.workspace_premium_rounded,
                color: Colors.deepPurple,
                onTap: () => _showMock("Sertifikatlar"),
              ),
              DashboardCard(
                title: "Klublar",
                icon: Icons.people_outline_rounded,
                color: Colors.redAccent,
                onTap: () => _showMock("Klublar"),
              ),
              DashboardCard(
                title: "Murojaatlar",
                icon: Icons.chat_bubble_outline_rounded,
                color: Colors.cyan,
                onTap: () => _showMock("Murojaatlar"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMock(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$feature bo'limi tez orada ishga tushadi!")),
    );
  }
}
