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

  final List<String> _categories = ["Barchasi", "To'garak", "Yutuqlar", "Ma'rifat darslari", "Volontyorlik", "Madaniy tashriflar", "Sport", "Boshqa"];
  final List<String> _statuses = ["Barchasi", "Tasdiqlangan", "Kutilmoqda", "Bekor qilingan"];

  // Mock Data
  final List<SocialActivity> _activities = [
    SocialActivity(
      id: "1",
      category: "Volontyorlik",
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
          // 1. Statistics Header (Only Statuses)
          _buildStatsHeader(),

          const SizedBox(height: 16),

          // 2. Filters (Dropdown-like)
          _buildFilterBar(),

          // 3. Activity List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _getFilteredActivities().length,
              itemBuilder: (context, index) {
                return _buildActivityCard(_getFilteredActivities()[index]);
              },
            ),
          ),
          
          // 4. Bottom Add Button (Fixed)
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), 
            blurRadius: 20, 
            offset: const Offset(0, -5)
          )
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _showAddActivityDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text(
              "Faollik qo'shish",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    // Calculate real counts based on _activities
    int approved = 0;
    int pending = 0;
    int rejected = 0;

    // In a real app, this would come from backend logic
    // For mock, we can just hardcode or count mock data
    // Let's count mock data + some base values to look realistic as per user prompt stats (12, 5, 3..)
    // User requested: "tasdiqlangan, kutilyapti, rad etilgan va ularni soni yetarli"
    approved = 12; 
    pending = 5;
    rejected = 2;

    final stats = [
      {"label": "Tasdiqlangan", "count": approved, "color": Colors.green, "bg": Colors.green[50]},
      {"label": "Kutilmoqda", "count": pending, "color": Colors.orange, "bg": Colors.orange[50]},
      {"label": "Rad etilgan", "count": rejected, "color": Colors.red, "bg": Colors.red[50]},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: stats.map((item) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "${item['count']}", 
                    style: TextStyle(
                      fontSize: 22, 
                      fontWeight: FontWeight.bold, 
                      color: item['color'] as Color
                    )
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['label'] as String, 
                    style: TextStyle(
                      fontSize: 12, 
                      fontWeight: FontWeight.w600, 
                      color: Colors.grey[600]
                    )
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterButton(
              label: _selectedCategory == "Barchasi" ? "Kategoriya" : _selectedCategory,
              isSelected: _selectedCategory != "Barchasi",
              icon: Icons.category_outlined,
              onTap: () => _showFilterSheet(
                title: "Kategoriyani tanlang",
                options: _categories,
                selected: _selectedCategory,
                onSelect: (val) => setState(() => _selectedCategory = val),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildFilterButton(
              label: _selectedStatus == "Barchasi" ? "Status" : _selectedStatus,
              isSelected: _selectedStatus != "Barchasi",
              icon: Icons.filter_list_rounded,
              onTap: () => _showFilterSheet(
                title: "Statusni tanlang",
                options: _statuses,
                selected: _selectedStatus,
                onSelect: (val) => setState(() => _selectedStatus = val),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required String label, 
    required bool isSelected, 
    required IconData icon, 
    required VoidCallback onTap
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppTheme.primaryBlue : Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? AppTheme.primaryBlue : Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.primaryBlue : Colors.grey[700],
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: isSelected ? AppTheme.primaryBlue : Colors.grey[500]),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet({
    required String title,
    required List<String> options,
    required String selected,
    required Function(String) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Divider(height: 1, color: Colors.grey[200]),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSel = option == selected;
                  return ListTile(
                    onTap: () {
                      onSelect(option);
                      Navigator.pop(context);
                    },
                    title: Text(option, style: TextStyle(
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      color: isSel ? AppTheme.primaryBlue : Colors.black87,
                    )),
                    trailing: isSel ? const Icon(Icons.check_rounded, color: AppTheme.primaryBlue) : null,
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddActivitySheet(
        categories: _categories.where((c) => c != "Barchasi").toList(),
        onSave: (activity) {
          setState(() {
            _activities.insert(0, activity); // Add to top
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Faollik muvaffaqiyatli qo\'shildi! ✅')),
          );
        },
      ),
    );
  }
}

class AddActivitySheet extends StatefulWidget {
  final List<String> categories;
  final Function(SocialActivity) onSave;

  const AddActivitySheet({super.key, required this.categories, required this.onSave});

  @override
  State<AddActivitySheet> createState() => _AddActivitySheetState();
}

class _AddActivitySheetState extends State<AddActivitySheet> {
  int _step = 1; // 1 = Category, 2 = Form
  String? _selectedCategory;
  
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle Bar
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                if (_step == 2) 
                  IconButton(
                    icon: const Icon(Icons.arrow_back), 
                    onPressed: () => setState(() => _step = 1),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                if (_step == 2) const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _step == 1 ? "Kategoriyani tanlang" : "Ma'lumotlarni kiriting",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(),
          
          // Content
          Expanded(
            child: _step == 1 ? _buildCategoryStep() : _buildFormStep(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStep() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.categories.length,
      itemBuilder: (context, index) {
        final category = widget.categories[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedCategory = category;
                _step = 2;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.category, color: AppTheme.primaryBlue, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Text(category, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected Category Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _selectedCategory ?? "",
              style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
          
          // Title Input
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
               labelText: "Faollik nomi",
               hintText: "Masalan: Navro'z bayrami",
               border: OutlineInputBorder(),
               prefixIcon: Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 16),
          
          // Description Input
          TextField(
            controller: _descController,
            maxLines: 4,
            decoration: const InputDecoration(
               labelText: "Faollik tavsifi",
               hintText: "Faollik haqida qisqacha ma'lumot...",
               border: OutlineInputBorder(),
               alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          
          // Date Picker
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4), // Match InputDecoration default
              ),
              child: Row(
                children: [
                   const Icon(Icons.calendar_today, color: Colors.grey),
                   const SizedBox(width: 12),
                   Text(
                     _selectedDate == null 
                       ? "Sanani tanlang" 
                       : "${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}",
                     style: TextStyle(color: _selectedDate == null ? Colors.grey[600] : Colors.black, fontSize: 16),
                   ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Save Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _saveActivity,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("Saqlash", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2025),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveActivity() {
    if (_titleController.text.isEmpty || _descController.text.isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Barcha maydonlarni to'ldiring")));
      return;
    }

    final newActivity = SocialActivity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      category: _selectedCategory!,
      title: _titleController.text,
      description: _descController.text,
      date: "${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}",
      status: "pending",
      imageUrls: [], // No image upload for now
    );

    widget.onSave(newActivity);
    Navigator.pop(context);
  }

