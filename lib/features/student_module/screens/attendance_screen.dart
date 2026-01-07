import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/data_service.dart';
import '../../../core/models/attendance.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final DataService _dataService = DataService();
  late Future<List<Attendance>> _attendanceFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _attendanceFuture = _dataService.getAttendanceList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text("Davomat", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<List<Attendance>>(
        future: _attendanceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Icon(Icons.error_outline, size: 48, color: Colors.red),
                   const SizedBox(height: 16),
                   Text("Xatolik: ${snapshot.error}", textAlign: TextAlign.center),
                   TextButton(onPressed: _loadData, child: const Text("Qayta urinish"))
                 ],
               ),
             );
          }

          final list = snapshot.data ?? [];
          
          // Calculate Stats
          int excused = list.where((a) => a.isExcused).fold(0, (sum, item) => sum + item.hours);
          int unexcused = list.where((a) => !a.isExcused).fold(0, (sum, item) => sum + item.hours);
          int total = excused + unexcused;

          return Column(
            children: [
              // Stats Cards
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Row(
                  children: [
                    _buildStatCard("Sababli", excused, Colors.green),
                    const SizedBox(width: 12),
                    _buildStatCard("Sababsiz", unexcused, Colors.red),
                    const SizedBox(width: 12),
                    _buildStatCard("Jami", total, AppTheme.primaryBlue),
                  ],
                ),
              ),
              
              const SizedBox(height: 10),

              // Detailed List
              Expanded(
                child: list.isEmpty 
                  ? const Center(child: Text("Qoldirilgan darslar yo'q 🎉"))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                         final item = list[index];
                         return Container(
                           margin: const EdgeInsets.only(bottom: 12),
                           padding: const EdgeInsets.all(16),
                           decoration: BoxDecoration(
                             color: Colors.white,
                             borderRadius: BorderRadius.circular(12),
                             boxShadow: [
                               BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset:const Offset(0, 2))
                             ]
                           ),
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Row(
                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                 children: [
                                   Expanded(
                                      child: Text(
                                        item.subjectName, 
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                   ),
                                   Container(
                                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                     decoration: BoxDecoration(
                                       color: (item.isExcused ? Colors.green : Colors.red).withOpacity(0.1),
                                       borderRadius: BorderRadius.circular(8)
                                     ),
                                     child: Text(
                                       "${item.hours} soat",
                                       style: TextStyle(
                                         color: item.isExcused ? Colors.green : Colors.red,
                                         fontWeight: FontWeight.bold,
                                         fontSize: 12
                                       ),
                                     ),
                                   )
                                 ],
                               ),
                               const SizedBox(height: 8),
                               Row(
                                 children: [
                                   Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                                   const SizedBox(width: 4),
                                   Text(item.date, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                   const SizedBox(width: 12),
                                   Expanded(
                                     child: Text(
                                       item.lessonTheme, 
                                       style: TextStyle(color: Colors.grey[800], fontSize: 13),
                                       overflow: TextOverflow.ellipsis,
                                     ),
                                   ),
                                 ],
                               ),
                               const SizedBox(height: 4),
                               Text(
                                  item.isExcused ? "Sababli" : "Sababsiz",
                                  style: TextStyle(
                                    color: item.isExcused ? Colors.green : Colors.red,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic
                                  ),
                               )
                             ],
                           ),
                         );
                      },
                    ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Text(
              "$value",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]), // "qoldirilgan" so'zi olib tashlandi
            ),
          ],
        ),
      ),
    );
  }
}
