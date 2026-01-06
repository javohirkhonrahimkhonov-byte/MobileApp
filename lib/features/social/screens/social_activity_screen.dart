import 'package:flutter/material.dart';
import 'package:talabahamkor_mobile/core/theme/app_theme.dart';
import 'social_activity_detail_screen.dart';

// Mock Model
class SocialActivity {
  final String id;
  final String category;
  final String title;
  final String description;
  final String date;
  final String status; // 'approved', 'pending', 'rejected'
  final List<String> imageUrls;

  SocialActivity({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.date,
    required this.status,
    required this.imageUrls,
  });
}

class SocialActivityScreen extends StatefulWidget {
  const SocialActivityScreen({super.key});

  @override
  State<SocialActivityScreen> createState() => _SocialActivityScreenState();
}

class _SocialActivityScreenState extends State<SocialActivityScreen> {
  // Filters
  String _selectedCategory = "Barchasi";
  String _selectedStatus = "Barchasi";

  final List<String> _categories = ["Barchasi", "Tadbir", "Volontyorlik", "To'garak", "Sport", "Boshqa"];
  final List<String> _statuses = ["Barchasi", "Tasdiqlangan", "Kutilmoqda", "Bekor qilingan"];

  // Mock Data
  final List<SocialActivity> _activities = [
    SocialActivity(
      id: "1",
      category: "Tadbir",
      title: "Navro'z bayrami tashkilotchiligi",
      description: "Universitet miqyosidagi Navro'z bayramida faol qatnashdim. Tashkiliy ishlarda yordam berdim.",
      date: "21.03.2024",
      status: "approved",
      imageUrls: ["https://picsum.photos/id/1018/800/600", "https://picsum.photos/id/1015/800/600"],
    ),
    SocialActivity(
      id: "2",
      category: "Sport",
      title: "Futbol musobaqasi",
      description: "Fakultetlararo futbol musobaqasida 1-o'rinni oldik.",
      date: "15.04.2024",
      status: "pending",
      imageUrls: ["https://picsum.photos/id/1025/800/600"],
    ),
    SocialActivity(
      id: "3",
      category: "Volontyorlik",
      title: "Daraxt ekish aksiyasi",
      description: "Yashil makon loyihasi doirasida 10 ta daraxt ekdim.",
      date: "10.03.2024",
      status: "rejected",
      imageUrls: ["https://picsum.photos/id/1040/800/600"],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text("Ijtimoiy Faollik", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // 1. Statistics Header
          _buildStatsHeader(),

          // 2. Filters
          _buildFilters(),

          // 3. Activity List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _getFilteredActivities().length,
              itemBuilder: (context, index) {
                return _buildActivityCard(_getFilteredActivities()[index]);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddActivityDialog,
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.add),
        label: const Text("Faollik qo'shish"),
      ),
    );
  }

  Widget _buildStatsHeader() {
    // Calculate counts (Mock)
    final stats = {
      "Tadbir": 12,
      "Volontyorlik": 5,
      "Sport": 3,
      "To'garak": 8,
      "Boshqa": 1,
    };

    return Container(
      height: 110, // Increased height to prevent overflow
      color: Colors.white,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12), // Reduced vertical padding
        scrollDirection: Axis.horizontal,
        itemCount: stats.keys.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final key = stats.keys.elementAt(index);
          final value = stats[key];
          return Container(
            constraints: const BoxConstraints(minWidth: 100),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.backgroundWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "$value", 
                  style: const TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.w800, 
                    color: AppTheme.primaryBlue
                  )
                ),
                Text(
                  key, 
                  style: TextStyle(
                    fontSize: 13, 
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600]
                  )
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _selectedCategory = cat),
                    backgroundColor: Colors.white,
                    selectedColor: AppTheme.primaryBlue.withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primaryBlue : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
                    ),
                    checkmarkColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20), 
                      side: BorderSide(color: isSelected ? AppTheme.primaryBlue : Colors.grey[300]!)
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    elevation: 0,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Status Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _statuses.map((status) {
                final isSelected = _selectedStatus == status;
                Color color;
                switch(status) {
                  case "Tasdiqlangan": color = Colors.green; break;
                  case "Kutilmoqda": color = Colors.orange; break;
                  case "Bekor qilingan": color = Colors.red; break;
                  default: color = Colors.grey;
                }
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(  // Changed from ChoiceChip to FilterChip for consistent look
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _selectedStatus = status),
                    backgroundColor: Colors.white,
                    selectedColor: color.withOpacity(0.1), 
                    labelStyle: TextStyle(
                      color: isSelected ? color : Colors.grey[600],
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
                    ),
                    checkmarkColor: color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20), 
                      side: BorderSide(color: isSelected ? color : Colors.grey[300]!)
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<SocialActivity> _getFilteredActivities() {
    return _activities.where((a) {
      final categoryMatch = _selectedCategory == "Barchasi" || a.category == _selectedCategory;
      
      bool statusMatch = true;
      if (_selectedStatus != "Barchasi") {
        if (_selectedStatus == "Tasdiqlangan" && a.status != "approved") statusMatch = false;
        if (_selectedStatus == "Kutilmoqda" && a.status != "pending") statusMatch = false;
        if (_selectedStatus == "Bekor qilingan" && a.status != "rejected") statusMatch = false;
      }
      return categoryMatch && statusMatch;
    }).toList();
  }

  Widget _buildActivityCard(SocialActivity activity) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch(activity.status) {
      case "approved":
        statusColor = Colors.green;
        statusText = "Tasdiqlangan";
        statusIcon = Icons.check_circle_rounded;
        break;
      case "rejected":
        statusColor = Colors.red;
        statusText = "Rad etilgan";
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = Colors.orange;
        statusText = "Kutilmoqda";
        statusIcon = Icons.access_time_rounded;
    }

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SocialActivityDetailScreen(activity: activity))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06), 
              blurRadius: 15, 
              offset: const Offset(0, 8),
              spreadRadius: -4,
            )
          ],
        ),
        clipBehavior: Clip.antiAlias, // Clean corners
        child: Column(
          children: [
            // Image with Category Overlay
            Stack(
              children: [
                Container(
                  height: 200, // Slightly taller
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: activity.imageUrls.isNotEmpty 
                      ? Image.network(
                          activity.imageUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                        ) 
                      : const Center(child: Icon(Icons.image_not_supported, color: Colors.grey, size: 40)),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]
                    ),
                    child: Text(
                      activity.category, 
                      style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)
                    ),
                  ),
                ),
              ],
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 6),
                          Text(activity.date, style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(statusIcon, size: 14, color: statusColor),
                            const SizedBox(width: 4),
                            Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    activity.title, 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87, height: 1.2), 
                    maxLines: 2, 
                    overflow: TextOverflow.ellipsis
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddActivityDialog() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Faollik qo'shish oynasi keyingi bosqichda...")));
  }
}
