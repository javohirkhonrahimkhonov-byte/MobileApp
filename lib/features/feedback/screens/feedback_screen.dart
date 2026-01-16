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

  // Bot-aligned Hierarchy (Updated per user request)
  final List<Map<String, dynamic>> _recipientHierarchy = [
    {
      "label": "🏛 Rahbariyat",
      "id": "rahbariyat",
      "children": [
        {"label": "🎓 Rektor", "id": "rektor"},
        {"label": "👔 O'quv ishlari prorektori", "id": "prorektor"},
        {"label": "👔 Yoshlar ishlari prorektori", "id": "yoshlar_prorektor"},
        {"label": "🔬 Ilmiy ishlar bo'yicha prorektor", "id": "ilmiy_prorektor"},
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
    {"label": "🧠 Psixolog", "id": "psixolog"},
    {"label": "🧑‍🏫 Tyutor", "id": "tyutor"},
  ];

// ... existing code ...

  Widget _buildContent() {
    if (_step == 0 || _step == 1) {
      final items = _step == 0 
          ? widget.hierarchy 
          : (_selectedCategory!['children'] as List).cast<Map<String, dynamic>>();

      final titleText = _step == 0 ? "Kimga yuborilsin?" : "${_selectedCategory!['label']} tarkibi:";

      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(titleText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  if (_step == 0) {
                     _selectCategory(item);
                  } else {
                     _selectSubCategory(item);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.shade100, blurRadius: 4, offset: const Offset(0, 2))
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item['label'].trim(), 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            )).toList(),
          ],
        ),
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
