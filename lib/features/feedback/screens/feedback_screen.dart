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

  void _showAddFeedbackDialog() {
    final textController = TextEditingController();
    String selectedRole = 'dekanat';
    String? filePath;
    String? fileName;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Yangi Murojaat"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  items: const [
                    DropdownMenuItem(value: 'rahbariyat', child: Text("🏛 Rahbariyat")),
                    DropdownMenuItem(value: 'dekanat', child: Text("🏫 Dekanat")),
                    DropdownMenuItem(value: 'tyutor', child: Text("🧑‍🏫 Tyutor")),
                    DropdownMenuItem(value: 'psixolog', child: Text("🧠 Psixolog")),
                  ],
                  onChanged: (v) => setDialogState(() => selectedRole = v!),
                  decoration: const InputDecoration(labelText: "Kimga"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    labelText: "Murojaat matni",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () async {
                    FilePickerResult? result = await FilePicker.platform.pickFiles();
                    if (result != null) {
                      setDialogState(() {
                        filePath = result.files.single.path;
                        fileName = result.files.single.name;
                      });
                    }
                  },
                  icon: const Icon(Icons.attach_file),
                  label: Text(fileName ?? "Fayl biriktirish (Ixtiyoriy)"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Bekor qilish"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (textController.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                _submitFeedback(textController.text, selectedRole, filePath);
              },
              child: const Text("Yuborish"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitFeedback(String text, String role, String? path) async {
    setState(() => _isLoading = true);
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
      default: return Colors.blue;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return "Kutilmoqda";
      case 'answered': return "Javob berilgan";
      case 'closed': return "Yopilgan";
      default: return status;
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
        onPressed: _showAddFeedbackDialog,
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.add),
      ),
    );
  }
}
