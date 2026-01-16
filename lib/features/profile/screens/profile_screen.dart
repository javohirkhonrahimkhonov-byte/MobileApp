import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/student.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final student = auth.currentUser;

    if (student == null) {
      return const Center(child: Text("Ma'lumot topilmadi"));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // 1. Avatar & Name
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundWhite,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryBlue, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: ClipOval(
                    child: student.imageUrl != null && student.imageUrl!.isNotEmpty
                        ? Image.network(
                            student.imageUrl!, 
                            fit: BoxFit.cover,
                            headers: const {'User-Agent': 'Mozilla/5.0'}, // Fix for some servers blocking default Dart UA
                            errorBuilder: (ctx, err, _) => _buildInitials(student.fullName),
                          )
                        : _buildInitials(student.fullName),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  student.fullName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22, 
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textBlack,
                  ),
                ),
                Text(
                  "ID: ${student.hemisLogin}",
                  style: TextStyle(
                    fontSize: 14, 
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 2. Info Cards (Bot Style List)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
               BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                _buildInfoRow(Icons.account_balance_rounded, "Universitet", student.universityName ?? "Topilmadi"),
                const Divider(height: 1),
                _buildInfoRow(Icons.school_rounded, "Fakultet", student.facultyName ?? "-"),
                const Divider(height: 1),
                _buildInfoRow(Icons.menu_book_rounded, "Yo'nalish", student.specialtyName ?? "-"),
                const Divider(height: 1),
                _buildInfoRow(
                  Icons.groups_rounded,
                  "Guruh",
                  (student.groupNumber != null && student.groupNumber!.length > 5)
                      ? student.groupNumber!.substring(0, 5)
                      : (student.groupNumber ?? "-"),
                ),
                const Divider(height: 1),
                _buildInfoRow(Icons.calendar_today_rounded, "Semestr", student.semesterName ?? "-"),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // 3. Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              label: const Text("Tizimdan Chiqish", style: TextStyle(color: Colors.white, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitials(String name) {
    String initials = "ST";
    if (name.isNotEmpty) {
      initials = name.substring(0, 1).toUpperCase();
      if (name.contains(" ")) {
        initials += name.split(" ")[1].substring(0, 1).toUpperCase();
      }
    }
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 32, 
          fontWeight: FontWeight.bold, 
          color: AppTheme.primaryBlue
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: AppTheme.textBlack, fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Chiqish"),
        content: const Text("Rostdan ham tizimdan chiqmoqchimisiz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Yo'q"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
            child: const Text("Ha", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
