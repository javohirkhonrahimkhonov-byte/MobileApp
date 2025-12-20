import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/data_service.dart';
import '../../core/theme/app_theme.dart';
import '../../features/activities/screens/activities_screen.dart'; // Will create next
import '../../features/clubs/screens/clubs_screen.dart'; // Will create next
import '../widgets/dashboard_stats_widget.dart'; // Will create next
import '../widgets/drawer_widget.dart';

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

  @override
  Widget build(BuildContext context) {
    // Screens for BottomNav
    final List<Widget> screens = [
      _buildHomeContent(),
      const ActivitiesScreen(), // Placeholder for now
      const Center(child: Text("AI Konspekt (Tez orada)")),
      const ClubsScreen(),      // Placeholder for now
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("TalabaHamkor"),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
        ],
      ),
      drawer: const AppDrawer(), // Logout is here
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppTheme.primaryBlue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Bosh sahifa"),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "Faolliklar"),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: "AI"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Klublar"),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Text(
              "Salom, ${_profile?['full_name']?.split(' ')?[0] ?? 'Talaba'}! 👋",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              "Guruh: ${_profile?['group_number']} • ID: ${_profile?['id']}",
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            
            // GPA Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                   const Text("Joriy GPA Ko'rsatkichi", style: TextStyle(color: Colors.white70)),
                   const SizedBox(height: 8),
                   Text(
                     "${_dashboard?['gpa'] ?? '0.0'}", 
                     style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)
                   ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats Grid
            Row(
              children: [
                Expanded(child: _statCard("Faolliklar", "${_dashboard?['activities_count']}", Icons.star, Colors.orange)),
                const SizedBox(width: 16),
                Expanded(child: _statCard("Klublar", "${_dashboard?['clubs_count']}", Icons.flag, Colors.purple)),
              ],
            ),
             const SizedBox(height: 16),
             Row(
              children: [
                Expanded(child: _statCard("Tasdiqlandi", "${_dashboard?['activities_approved_count']}", Icons.check_circle, AppTheme.accentGreen)),
                const SizedBox(width: 16),
                Expanded(child: _statCard("Hujjatlar", "0", Icons.folder, Colors.blueGrey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }
}
