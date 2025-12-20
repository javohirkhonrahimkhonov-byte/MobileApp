import 'package:flutter/material.dart';
import '../../core/services/data_service.dart';
import '../../core/theme/app_theme.dart';

class ClubsScreen extends StatefulWidget {
  const ClubsScreen({super.key});

  @override
  State<ClubsScreen> createState() => _ClubsScreenState();
}

class _ClubsScreenState extends State<ClubsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DataService _dataService = DataService();
  List<dynamic> _myClubs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadClubs();
  }

  Future<void> _loadClubs() async {
    try {
      final data = await _dataService.getMyClubs();
      if (mounted) {
        setState(() {
          _myClubs = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryBlue,
          tabs: const [
            Tab(text: "Mening Klublarim"),
            Tab(text: "Barcha Klublar"),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMyClubsList(),
              const Center(child: Text("Barcha klublar ro'yxati (Loading...)")),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMyClubsList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_myClubs.isEmpty) return const Center(child: Text("Siz hech qaysi klubga a'zo emassiz."));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myClubs.length,
      itemBuilder: (context, index) {
        final membership = _myClubs[index];
        final club = membership['club'];
        return Card(
          elevation: 2,
          child: ListTile(
            leading: const Icon(Icons.people_outline, size: 32, color: AppTheme.primaryBlue),
            title: Text(club['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Rol: ${membership['role']}"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        );
      },
    );
  }
}
