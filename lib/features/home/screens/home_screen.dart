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
import 'package:talabahamkor_mobile/features/ai/screens/ai_screen.dart';

// Commenting out missing screens for now to get build working, or using placeholders
// import 'package:talabahamkor_mobile/features/clubs/screens/clubs_screen.dart';
// import 'package:talabahamkor_mobile/features/feedback/screens/feedback_screen.dart';
// import 'package:talabahamkor_mobile/features/documents/screens/documents_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final DataService _dataService = DataService();
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _dashboard;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final profile = await _dataService.getProfile();
      final dashboard = await _dataService.getDashboardStats();
      if (mounted) {
        setState(() {
          _profile = profile;
          _dashboard = dashboard;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading home data: $e");
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Chiqish"),
        content: const Text("Tizimdan chiqmoqchimisiz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Yo'q"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
            child: const Text("Ha", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    // Screens for BottomNav
    final List<Widget> screens = [
      _buildHomeContent(),           // 0: Home
      StudentModuleScreen(),         // 1: Talaba Moduli
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
          type: BottomNavigationBarType.fixed, // Fixed is crucial for >3 items
          backgroundColor: Colors.white,
          elevation: 0,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: "Asosiy"),
            BottomNavigationBarItem(icon: Icon(Icons.newspaper_rounded), label: "Talaba"),
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

          // 3. Module Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              _buildModuleCard(
                title: "Faollik",
                value: "${_dashboard?['activities_count'] ?? 0}",
                subtitle: "Ballarim",
                icon: Icons.emoji_events_rounded,
                color: Colors.orange,
                onTap: () => setState(() => _currentIndex = 1),
              ),
              _buildModuleCard(
                title: "Klublar",
                value: "${_dashboard?['clubs_count'] ?? 0}",
                subtitle: "A'zolik",
                icon: Icons.groups_rounded,
                color: Colors.purple,
                onTap: () {}, // Navigator.push(context, MaterialPageRoute(builder: (_) => const ClubsScreen())),
              ),
              _buildModuleCard(
                title: "Davomat",
                value: "${_dashboard?['missed_hours'] ?? 0} soat",
                subtitle: "Qoldirilgan dars",
                icon: Icons.timer_off_outlined,
                color: Colors.redAccent,
                onTap: () {}, // Future: Open Attendance Details
              ),
              _buildModuleCard(
                title: "Murojaat",
                value: "Dekanat",
                subtitle: "Aloqa",
                icon: Icons.chat_bubble_rounded,
                color: AppTheme.accentGreen,
                onTap: () {}, // Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackScreen())),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard({
    required String title, 
    required String value, 
    required String subtitle, 
    required IconData icon, 
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: const Color(0xFF0123FF).withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 4)),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Icon(Icons.arrow_outward_rounded, color: Colors.grey[300], size: 20),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textBlack)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
