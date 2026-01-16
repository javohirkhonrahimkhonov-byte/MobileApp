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
  Future<void> _submitFeedback(String text, String role, String? path) async {
    setState(() => _isLoading = true);
    // ... existing submit logic
    try {
      await _dataService.sendFeedback(text, role, path);
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
  final Function(String, String, String?) onSubmit;

  const _FeedbackWizard({required this.hierarchy, required this.onSubmit});

  @override
  State<_FeedbackWizard> createState() => _FeedbackWizardState();
}

class _FeedbackWizardState extends State<_FeedbackWizard> {
  int _step = 0; // 0: Category, 1: SubCategory (if any), 2: Form
  Map<String, dynamic>? _selectedCategory;
  Map<String, dynamic>? _selectedSubCategory;
  
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController(); // Requested: Subject (Mavzu)
  String? _filePath;
  String? _fileName;

  void _selectCategory(Map<String, dynamic> item) {
    setState(() {
      _selectedCategory = item;
      if (item.containsKey('children')) {
        _step = 1;
      } else {
        _selectedSubCategory = null; // No sub-category
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
    final roleId = _selectedSubCategory?['id'] ?? _selectedCategory?['id'];
    final label = _selectedSubCategory?['label'] ?? _selectedCategory?['label'] ?? "Murojaat";

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        height: 600, // Fixed height or dynamic
        child: Column(
          children: [
            // Header
            Row(
              children: [
                if (_step > 0)
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        if (_step == 2) {
                           if (_selectedCategory!.containsKey('children')) {
                             _step = 1;
                           } else {
                             _step = 0;
                             _selectedCategory = null;
                           }
                        } else if (_step == 1) {
                          _step = 0;
                          _selectedCategory = null;
                        }
                      });
                    },
                  ),
                Expanded(
                  child: Text(
                    _step == 0 ? "Bo'limni tanlang" : (_step == 1 ? "Mas'ulni tanlang" : "Murojaat yozish"),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (_step > 0) const SizedBox(width: 40), // Balance back button
              ],
            ),
            const Divider(),
            
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
      return ListView.builder(
        itemCount: widget.hierarchy.length,
        itemBuilder: (ctx, i) {
          final item = widget.hierarchy[i];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance, color: AppTheme.primaryBlue),
              title: Text(item['label']),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _selectCategory(item),
            ),
          );
        },
      );
    } else if (_step == 1) {
      final children = _selectedCategory!['children'] as List;
      return ListView.builder(
        itemCount: children.length,
        itemBuilder: (ctx, i) {
          final item = children[i];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.person, color: AppTheme.primaryBlue),
              title: Text(item['label']),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _selectSubCategory(item),
            ),
          );
        },
      );
    } else {
      // Form Step
      final roleName = _selectedSubCategory?['label'] ?? _selectedCategory?['label'];
      
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                   const Icon(Icons.info_outline, color: Colors.blue),
                   const SizedBox(width: 10),
                   Expanded(child: Text("Qabul qiluvchi: $roleName", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            const Text("Mavzu (Qisqacha)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: "Masalan: Sessiya vaqtlari bo'yicha",
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 16),
            const Text("Murojaat matni", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: "Batafsil tushuntiring...",
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles();
                if (result != null) {
                  setState(() {
                    _filePath = result.files.single.path;
                    _fileName = result.files.single.name;
                  });
                }
              },
              icon: const Icon(Icons.attach_file),
               label: Text(_fileName ?? "Fayl biriktirish (Ixtiyoriy)"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black,
                elevation: 0,
              ),
            ),
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                   final text = _textController.text.trim();
                   // If backend supports title, we should prepend it or send as separate field.
                   // Current sendFeedback takes (text, role, file).
                   // I will prepend Title to Text: "MAVZU: Title\n\nText"
                   final title = _titleController.text.trim();
                   if (text.isEmpty) return;
                   
                   final fullText = title.isNotEmpty ? "MAVZU: $title\n\n$text" : text;
                   final roleId = _selectedSubCategory?['id'] ?? _selectedCategory?['id'];
                   
                   Navigator.pop(context); // Close sheet
                   widget.onSubmit(fullText, roleId, _filePath);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                child: const Text("Yuborish", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            )
          ],
        ),
      );
    }
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
