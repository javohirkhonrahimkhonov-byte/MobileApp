import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:talabahamkor_mobile/core/theme/app_theme.dart';
import 'package:talabahamkor_mobile/core/services/data_service.dart';
import 'social_activity_detail_screen.dart';

// Mock Model (Updated to match API response structure roughly)
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

  factory SocialActivity.fromJson(Map<String, dynamic> json) {
    // Extract images if any
    List<String> images = [];
    if (json['images'] != null) {
      for (var img in json['images']) {
         // Assuming API might return file_id or url. 
         // Since we can't display file_id, we will just keep it. 
         // If we had a proxy: "https://api.bot.com/file/${img['file_id']}"
         images.add(img['file_id'] ?? ""); 
      }
    }
    return SocialActivity(
      id: json['id'].toString(),
      category: json['category'] ?? "Boshqa",
      title: json['name'] ?? "Nomsiz",
      description: json['description'] ?? "",
      date: json['date'] ?? "",
      status: json['status'] ?? "pending",
      imageUrls: images,
    );
  }
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
  bool _isLoading = false;

  final List<String> _categories = ["Barchasi", "To'garak", "Yutuqlar", "Ma'rifat darslari", "Volontyorlik", "Madaniy tashriflar", "Sport", "Boshqa"];
  final List<String> _statuses = ["Barchasi", "Tasdiqlangan", "Kutilmoqda", "Bekor qilingan"];

  List<SocialActivity> _activities = [];

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoading = true);
    try {
      final rawData = await Provider.of<DataService>(context, listen: false).getActivities();
      setState(() {
        _activities = rawData.map((e) => SocialActivity.fromJson(e)).toList();
      });
    } catch (e) {
      debugPrint("Load Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text("Ijtimoiy Faollik", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(onPressed: _loadActivities, icon: const Icon(Icons.refresh))
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : Column(
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
    int approved = 0;
    int pending = 0;
    int rejected = 0;

    for (var act in _activities) {
      if (act.status == 'approved') approved++;
      else if (act.status == 'pending') pending++;
      else if (act.status == 'rejected') rejected++;
    }

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

    // Attempt to parse first image URL or use placeholder
    // If it's just a file_id, this won't work, so we fallback to icon
    bool hasValidImage = activity.imageUrls.isNotEmpty && activity.imageUrls.first.startsWith("http");

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
                  child: hasValidImage
                      ? CachedNetworkImage(
                          imageUrl: activity.imageUrls.first,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                        )
                      : const Center(child: Icon(Icons.image, color: Colors.grey, size: 40)), // Placeholder
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
        onSave: (activity) async {
          // Send to API
          try {
             // Map categories to API values if needed, otherwise send as is
             // API expects "category", "name", "description", "date"
             // But category needs to be lower case snake_case likely if the bot relies on it?
             // Checking 'activities.py' line 32: CATEGORIES = ["togarak", "yutuqlar", "marifat", "volontyorlik", "madaniy", "sport", "boshqa"]
             // So I should map user friendly names to keys.
             
             String apiCat = activity.category.toLowerCase();
             if (activity.category == "To'garak") apiCat = "togarak";
             if (activity.category == "Yutuqlar") apiCat = "yutuqlar";
             if (activity.category == "Ma'rifat darslari") apiCat = "marifat";
             if (activity.category == "Volontyorlik") apiCat = "volontyorlik";
             if (activity.category == "Madaniy tashriflar") apiCat = "madaniy";
             if (activity.category == "Sport") apiCat = "sport";
             if (activity.category == "Boshqa") apiCat = "boshqa";

             await Provider.of<DataService>(context, listen: false).addActivity(
               apiCat, 
               activity.title, 
               activity.description, 
               activity.date
             );
             
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Faollik muvaffaqiyatli yuborildi! Xodim tasdiqlashini kuting. ⏳')),
             );
             
             // Reload list
             _loadActivities();
             
          } catch(e) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Xatolik: $e')),
             );
          }
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
    // Dynamic Labels logic
    String titleLabel = "Faollik nomi";
    String titleHint = "Nomini kiriting...";
    String descLabel = "Faollik tavsifi";
    String descHint = "Batafsil ma'lumot...";

    switch (_selectedCategory) {
      case "Ma'rifat darslari":
        titleLabel = "Ma'rifat darsi mavzusi";
        titleHint = "Mavzuni kiriting (masalan: Odob-axloq)";
        descLabel = "Ma'rifat darsi tavsifi";
        descHint = "Dars haqida qisqacha yozing...";
        break;
      case "To'garak":
        titleLabel = "To'garak nomi";
        titleHint = "Qaysi to'garakka qatnashdingiz?";
        descLabel = "To'garak tavsifi";
        descHint = "Mashg'ulot haqida ma'lumot...";
        break;
      case "Yutuqlar":
        titleLabel = "Yutuq nomi";
        titleHint = "Qanday yutuqqa erishdingiz?";
        descLabel = "Yutuq tavsifi";
        descHint = "Musobaqa yoki tadbir haqida...";
        break;
      case "Volontyorlik":
        titleLabel = "Volontyorlik nomi";
        titleHint = "Qanday ishda yordam berdingiz?";
        descLabel = "Volontyorlik tavsifi";
        descHint = "Bajarilgan ishlar haqida...";
        break;
      case "Madaniy tashriflar":
        titleLabel = "Tashrif nomi";
        titleHint = "Qayerga tashrif buyurdingiz?";
        descLabel = "Tashrif tavsifi";
        descHint = "Tashrifdan olgan taassurotlaringiz...";
        break;
      case "Sport":
        titleLabel = "Sport turi / Musobaqa nomi";
        titleHint = "Futbol, Shaxmat yoki musobaqa nomi...";
        descLabel = "Faollik tavsifi";
        descHint = "Musobaqa natijalari...";
        break;
      default:
        titleLabel = "Faollik nomi";
        titleHint = "Faollik nomini kiriting...";
        descLabel = "Faollik tavsifi";
        descHint = "Faollik haqida ma'lumot...";
    }

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
            decoration: InputDecoration(
               labelText: titleLabel,
               hintText: titleHint,
               border: const OutlineInputBorder(),
               prefixIcon: const Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 16),
          
          // Description Input
          TextField(
            controller: _descController,
            maxLines: 4,
            decoration: InputDecoration(
               labelText: descLabel,
               hintText: descHint,
               border: const OutlineInputBorder(),
               alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          
          // Date Picker
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4), // Match InputDecoration default
                color: Colors.transparent, // Required for tap to work on empty space inside
              ),
              child: Row(
                children: [
                   const Icon(Icons.calendar_month, color: AppTheme.primaryBlue), // Updated icon
                   const SizedBox(width: 12),
                   Text(
                     _selectedDate == null 
                       ? "Sana, Oy, Yilni tanlang" 
                       : DateFormat('dd.MM.yyyy').format(_selectedDate!),
                     style: TextStyle(color: _selectedDate == null ? Colors.grey[600] : Colors.black, fontSize: 16, fontWeight: _selectedDate == null ? FontWeight.normal : FontWeight.w500),
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
    final now = DateTime.now();
    final firstDate = DateTime(2020);
    final lastDate = DateTime(2030);
    
    // Ensure initialDate is valid
    DateTime initialDate = _selectedDate ?? now;
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('uz', 'UZ'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryBlue,
              onPrimary: Colors.white, 
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
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

    // Creating object to return to parent for saving
    final newActivity = SocialActivity(
      id: "0", // Temp ID
      category: _selectedCategory!,
      title: _titleController.text,
      description: _descController.text,
      date: DateFormat('dd.MM.yyyy').format(_selectedDate!),
      status: "pending",
      imageUrls: [],
    );

    widget.onSave(newActivity);
    Navigator.pop(context);
  }
}


