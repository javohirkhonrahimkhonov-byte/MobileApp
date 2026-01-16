import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:talabahamkor_mobile/core/services/data_service.dart';
import 'package:talabahamkor_mobile/core/theme/app_theme.dart';
import 'package:talabahamkor_mobile/features/feedback/screens/feedback_detail_screen.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final DataService _dataService = DataService();
  List<dynamic> _feedbacks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeedbacks();
  }

  Future<void> _loadFeedbacks() async {
    try {
      final data = await _dataService.getMyFeedback();
      setState(() {
        _feedbacks = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xatolik: $e')),
      );
    }
  }

  // Bot-aligned Hierarchy
  final List<Map<String, dynamic>> _recipientHierarchy = [
    {
      "label": "🏛 Rahbariyat",
      "id": "rahbariyat",
      "children": [
        {"label": "🎓 Rektor", "id": "rektor"},
        {"label": "👔 O'quv ishlari prorektori", "id": "prorektor"},
        {"label": "👔 Yoshlar ishlari prorektori", "id": "yoshlar_prorektor"},
        {"label": "🔍 Inspektor", "id": "inspektor"},
      ]
    },
    {
      "label": "🏫 Dekanat",
      "id": "dekanat",
      "children": [
        {"label": "👤 Dekan", "id": "dekan"},
        {"label": "👤 Dekan o'rinbosari", "id": "dekan_orinbosari"},
      ]
    },
    {"label": "💰 Buxgalteriya", "id": "buxgalter"},
    {"label": "📚 Kutubxona", "id": "kutubxona"},
    {"label": "🧠 Psixolog", "id": "psixolog"},
    {"label": "🧑‍🏫 Tyutor", "id": "tyutor"},
  ];

  void _showAddFeedbackSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _FeedbackWizard(
        hierarchy: _recipientHierarchy,
        onSubmit: _submitFeedback,
      ),
    );
  }

  // Old simple dialog removed...
  Future<void> _submitFeedback(String text, String role, String? path, bool isAnonymous) async {
    setState(() => _isLoading = true);
    // ... existing submit logic
    try {
      await _dataService.sendFeedback(text, role, path, isAnonymous: isAnonymous);
      await _loadFeedbacks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Murojaat yuborildi! ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xatolik: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'answered': return Colors.green;
      case 'closed': return Colors.grey;
      case 'rejected': return Colors.red;
      default: return Colors.blue;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return "Kutilmoqda";
      case 'answered': return "Javob berilgan";
      case 'closed': return "Yopilgan";
      case 'rejected': return "Rad etilgan";
      default: return status;
    }
  }
}

class _FeedbackWizard extends StatefulWidget {
  final List<Map<String, dynamic>> hierarchy;
  final Function(String, String, String?, bool) onSubmit;

  const _FeedbackWizard({required this.hierarchy, required this.onSubmit});

  @override
  State<_FeedbackWizard> createState() => _FeedbackWizardState();
}

class _FeedbackWizardState extends State<_FeedbackWizard> {
  int _step = 0; // 0: Category, 1: SubCategory (if any), 2: Form
  Map<String, dynamic>? _selectedCategory;
  Map<String, dynamic>? _selectedSubCategory;
  bool _isAnonymous = false;
  
  final TextEditingController _textController = TextEditingController();
  String? _filePath;
  String? _fileName;

  void _selectCategory(Map<String, dynamic> item) {
    setState(() {
      _selectedCategory = item;
      if (item.containsKey('children')) {
        _step = 1;
      } else {
        _selectedSubCategory = null; 
        _step = 2; // Jump to form
      }
    });
  }

  void _selectSubCategory(Map<String, dynamic> item) {
    setState(() {
      _selectedSubCategory = item;
      _step = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine the final role ID
    final title = _step == 0 ? "Yangi murojaat" : (_step == 1 ? "Mas'ulni tanlang" : "Murojaat yozish");

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        height: 650, 
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            
            // Header with Back Button
            Row(
              children: [
                if (_step > 0)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_step == 2) {
                           if (_selectedCategory!.containsKey('children')) {
                             _step = 1;
                           } else {
                             _step = 0;
                             _selectedCategory = null;
                             _isAnonymous = false;
                           }
                        } else if (_step == 1) {
                          _step = 0;
                          _selectedCategory = null;
                        }
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(Icons.arrow_back, size: 24),
                    ),
                  ),
                Text(
                  title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_step == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Kimga yuborilsin?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: widget.hierarchy.map((item) => _buildChip(item, () => _selectCategory(item))).toList(),
          ),
        ],
      );
    } else if (_step == 1) {
      final children = _selectedCategory!['children'] as List;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${_selectedCategory!['label']} tarkibi:", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: children.map((item) => _buildChip(item, () => _selectSubCategory(item))).toList(),
          ),
        ],
      );
    } else {
      // Form Step
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected Recipient Display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 16, color: AppTheme.primaryBlue),
                  const SizedBox(width: 8),
                  Text(
                    _selectedSubCategory?['label'] ?? _selectedCategory?['label'],
                    style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Anonymity Toggle
            const Text("Maxfiylik", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Anonim yuborish", style: TextStyle(fontSize: 16)),
                    Text("Ism-familiyangiz ko'rinmaydi", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                Switch(
                  value: _isAnonymous,
                  onChanged: (v) => setState(() => _isAnonymous = v),
                  activeColor: AppTheme.primaryBlue,
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Text Input
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _textController,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: "Murojaat matnini yozing...",
                  border: InputBorder.none,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // File Attachment
            GestureDetector(
              onTap: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles();
                if (result != null) {
                  setState(() {
                    _filePath = result.files.single.path;
                    _fileName = result.files.single.name;
                  });
                }
              },
              child: Row(
                children: [
                  Icon(Icons.attach_file, color: _fileName != null ? AppTheme.primaryBlue : Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _fileName ?? "Fayl biriktirish (rasm, hujjat)",
                      style: TextStyle(color: _fileName != null ? AppTheme.primaryBlue : Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_fileName != null)
                     IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _fileName = null))
                ],
              ),
            ),

            const SizedBox(height: 24),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                   final text = _textController.text.trim();
                   final roleId = _selectedSubCategory?['id'] ?? _selectedCategory?['id'];
                   
                   if (text.isEmpty) return;
                   
                   Navigator.pop(context);
                   widget.onSubmit(text, roleId, _filePath, _isAnonymous);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0033FF), // Vibrant Blue
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text("Yuborish", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16), // Bottom safety padding
          ],
        ),
      );
    }
  }

  Widget _buildChip(Map<String, dynamic> item, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          item['label'].replaceAll(RegExp(r'[^\w\s]'), '').trim(), // Remove emojis for cleaner look if standard text preferred, or keep them.
          // User mockups show text only usually, effectively removing emojis or keeping them subtle.
          // Let's keep distinct text.
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mening Murojaatlarim")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _feedbacks.isEmpty
              ? const Center(child: Text("Murojaatlar mavjud emas"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _feedbacks.length,
                  itemBuilder: (context, index) {
                    final fb = _feedbacks[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FeedbackDetailScreen(feedbackId: fb['id']),
                            ),
                          );
                        },
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(fb['status']).withOpacity(0.2),
                          child: Icon(Icons.message, color: _getStatusColor(fb['status'])),
                        ),
                        title: Text(
                          fb['text'] ?? "Matnsiz",
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Kimga: ${fb['assigned_role']?.toUpperCase() ?? 'Noma\'lum'}"),
                            Text("Holati: ${_getStatusText(fb['status'])}"),
                          ],
                        ),
                        trailing: Text(
                          (fb['created_at'] as String).substring(0, 10),
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFeedbackSheet,
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.add),
      ),
    );
  }
}
