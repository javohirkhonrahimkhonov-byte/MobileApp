import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/student_dashboard_widgets.dart';

class StudentModuleScreen extends StatelessWidget {
  const StudentModuleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text("Talaba Moduli", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Asosiy Xizmatlar",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                DashboardCard(
                  title: "Davomat",
                  icon: Icons.calendar_today_rounded,
                  color: Colors.green,
                  onTap: () => _showMock(context, "Davomat"),
                ),
                DashboardCard(
                  title: "Ijtimoiy Faollik",
                  icon: Icons.star_rounded,
                  color: Colors.orange,
                  onTap: () => _showMock(context, "Ijtimoiy Faollik"),
                ),
                DashboardCard(
                  title: "Hujjatlar",
                  icon: Icons.folder_open_rounded,
                  color: Colors.blue,
                  onTap: () => _showMock(context, "Hujjatlar"),
                ),
                DashboardCard(
                  title: "Sertifikatlar",
                  icon: Icons.workspace_premium_rounded,
                  color: Colors.deepPurple,
                  onTap: () => _showMock(context, "Sertifikatlar"),
                ),
                DashboardCard(
                  title: "Klublar",
                  icon: Icons.people_outline_rounded,
                  color: Colors.redAccent,
                  onTap: () => _showMock(context, "Klublar"),
                ),
                DashboardCard(
                  title: "Murojaatlar",
                  icon: Icons.chat_bubble_outline_rounded,
                  color: Colors.cyan,
                  onTap: () => _showMock(context, "Murojaatlar"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMock(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$feature bo'limi tez orada ishga tushadi!")),
    );
  }
}
