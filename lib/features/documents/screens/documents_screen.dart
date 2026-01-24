import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/data_service.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final DataService _dataService = DataService();
  bool _isLoading = false;
  List<dynamic> _documents = []; // Placeholder for real docs if implemented

  @override
  void initState() {
    super.initState();
    // In a real app, we'd fetch actual documents here
    // _loadDocuments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text("Hujjatlar", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // For now, always empty as requested (demo docs removed)
    if (_documents.isEmpty) {
      return Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_copy_outlined, size: 80, color: Colors.grey[200]),
                  const SizedBox(height: 16),
                  Text(
                    "Hujjatlar yo'q",
                    style: TextStyle(color: Colors.grey[400], fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Hali hech qanday hujjat yuklanmagan",
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          _buildBottomButton(),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: _documents.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
               // ... Future real item implementation
               return const SizedBox();
            },
          ),
        ),
        _buildBottomButton(),
      ],
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
            onPressed: _showAddDocumentSheet,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text(
              "Hujjat yuklash",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddDocumentSheet() {
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
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text("Hujjat turini tanlang", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Divider(height: 1, color: Colors.grey[100]),
            _buildActionItem(Icons.credit_card_rounded, "Passport nusxasi"),
            _buildActionItem(Icons.work_outline_rounded, "Rezyume (CV)"),
            _buildActionItem(Icons.assignment_ind_rounded, "Obyektivka"),
            _buildActionItem(Icons.folder_shared_rounded, "Boshqa hujjat"),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String title) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.black87, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fayl tanlash oynasi ochilmoqda...")));
      },
    );
  }
}
