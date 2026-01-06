import 'package:flutter/material.dart';
import '../../../core/services/data_service.dart';
import '../../../core/theme/app_theme.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final DataService _dataService = DataService();
  List<dynamic> _documents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    try {
      final data = await _dataService.getMyDocuments();
      setState(() {
        _documents = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRequestDialog() {
    final descController = TextEditingController();
    String selectedType = "Ma'lumotnoma";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Hujjat so'rash"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedType,
                items: const [
                  DropdownMenuItem(value: "Ma'lumotnoma", child: Text("📄 Ma'lumotnoma (O'qish joyidan)")),
                  DropdownMenuItem(value: "Transcript", child: Text("📊 Transkript (Baholar)")),
                  DropdownMenuItem(value: "Tavsifnoma", child: Text("📜 Tavsifnoma (Xarakteristika)")),
                ],
                onChanged: (v) => setDialogState(() => selectedType = v!),
                decoration: const InputDecoration(labelText: "Hujjat turi"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: "Qayerga (Izoh)",
                  hintText: "Masalan: Hokimiyatga",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Bekor qilish")),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                _submitRequest(selectedType, descController.text);
              },
              child: const Text("Yuborish"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRequest(String type, String desc) async {
    setState(() => _isLoading = true);
    try {
      await _dataService.requestDocument(type, desc);
      await _loadDocuments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("So'rov yuborildi! ✅")),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hujjatlarim")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _documents.isEmpty
              ? const Center(child: Text("Hujjat so'rovlari yo'q"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _documents.length,
                  itemBuilder: (context, index) {
                    final doc = _documents[index];
                    bool isReady = doc['status'] == 'completed' || doc['status'] == 'ready';
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          isReady ? Icons.check_circle : Icons.access_time_filled,
                          color: isReady ? Colors.green : Colors.orange,
                        ),
                        title: Text(doc['type'] ?? "Hujjat"),
                        subtitle: Text("Status: ${doc['status']}"),
                        trailing: isReady
                            ? IconButton(
                                icon: const Icon(Icons.download),
                                onPressed: () {
                                  // TODO: Download logic (Open URL)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Yuklab olish tez orada...")),
                                  );
                                },
                              )
                            : null,
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showRequestDialog,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}
