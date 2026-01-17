import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/data_service.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  final DataService _dataService = DataService();
  bool _isLoading = true;
  List<dynamic> _grades = [];

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    final grades = await _dataService.getGrades();
    if (mounted) {
      setState(() {
        _grades = grades;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text("O'zlashtirish", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _grades.isEmpty
              ? const Center(child: Text("Ma'lumot topilmadi"))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _grades.length,
                  itemBuilder: (context, index) {
                    final item = _grades[index];
                    return _buildGradeCard(item);
                  },
                ),
    );
  }

  Widget _buildGradeCard(dynamic item) {
    final subject = item['subject'] ?? "Fan";
    
    // Values from API are {"val_5": x, "raw": y} or null if we changed logic.
    // Wait, backend logic:
    // "on": {"val_5": on_5, "raw": on_data['grade']},
    // "yn": {"val_5": yn_5, "raw": yn_data['grade']}
    
    final on = item['on'] ?? {};
    final yn = item['yn'] ?? {};
    
    final onVal = on['val_5'] ?? 0;
    final ynVal = yn['val_5'] ?? 0;
    final ynRaw = yn['raw'] ?? 0; // Check raw to hide/show
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Name
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.book, color: Colors.blue, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  subject,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Scores Row
          Row(
            children: [
             const SizedBox(width: 32), // Indent to align with text
              _buildScoreBadge("ON", onVal, Colors.orange),
              if (ynRaw > 0) ...[
                 Container(
                   margin: const EdgeInsets.symmetric(horizontal: 12),
                   height: 20, 
                   width: 1, 
                   color: Colors.grey.shade300
                 ),
                _buildScoreBadge("YN", ynVal, Colors.blue),
              ],
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildScoreBadge(String label, dynamic score, Color color) {
      return Row(
          children: [
              Text(
                  label, 
                  style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)
              ),
              const SizedBox(width: 6),
              Text(
                  "$score/5", 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)
              ),
          ],
      );
  }
}
