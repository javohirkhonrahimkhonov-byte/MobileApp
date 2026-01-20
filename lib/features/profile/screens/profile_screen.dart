import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart'; // NEW
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/student.dart';
import '../../../../core/services/data_service.dart'; // Ensure DataService is imported

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Username State
  bool _isEditingUsername = false;
  final TextEditingController _usernameController = TextEditingController();
  String? _usernameError;
  bool _isCheckingUsername = false;
  bool _isSavingUsername = false;

  void _onUsernameChanged(String value) async {
    setState(() => _usernameError = null);
    
    if (value.length < 2) return;
    
    setState(() => _isCheckingUsername = true);
    final available = await Provider.of<AuthProvider>(context, listen: false).checkUsernameAvailability(value);
    
    if (mounted) {
      setState(() {
        _isCheckingUsername = false;
        if (!available) {
           _usernameError = "Bu username allaqachon olingan";
        }
      });
    }
  }

  Future<void> _saveUsername() async {
     final value = _usernameController.text.toLowerCase().trim();
     if (value.length < 2 || value.length > 25) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Username 2-25 belgi bo'lishi kerak")));
       return;
     }
     if (_usernameError != null) return;
     
     setState(() => _isSavingUsername = true);
     final result = await Provider.of<AuthProvider>(context, listen: false).updateUsername(value);
     setState(() => _isSavingUsername = false);
     
     if (result['success'] == true) {
       setState(() {
         _isEditingUsername = false;
       });
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Username saqlandi!")));
     } else {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? "Xatolik")));
     }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final student = auth.currentUser;

    if (student == null) {
      return const Center(child: Text("Ma'lumot topilmadi"));
    }
    
    // Initialize controller only once if not editing or empty
    if (!_isEditingUsername && _usernameController.text.isEmpty && student.username != null) {
      _usernameController.text = student.username!;
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
                GestureDetector(
                  onTap: () => _showImageOptions(context),
                  child: Stack(
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
                                  headers: const {'User-Agent': 'Mozilla/5.0'},
                                  errorBuilder: (ctx, err, stack) => _buildInitials(student.fullName),
                                )
                              : _buildInitials(student.fullName),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
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
                  style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
                
                // --- USERNAME SECTION ---
                const SizedBox(height: 12),
                if (_isEditingUsername)
                  Container(
                    width: 220,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _usernameError != null ? Colors.red : AppTheme.primaryBlue.withOpacity(0.3))
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _usernameController,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                          decoration: InputDecoration(
                            hintText: "username",
                            prefixText: "@",
                            isDense: true,
                            border: InputBorder.none,
                            errorText: _usernameError,
                            errorStyle: const TextStyle(color: Colors.red, fontSize: 11),
                            suffixIcon: _isCheckingUsername 
                              ? const SizedBox(width: 12, height: 12, child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2))) 
                              : null
                          ),
                          onChanged: _onUsernameChanged,
                        ),
                        // Validation Error Below Border (Red) - Handled by InputDecoration.errorText or Custom
                        // Using custom text for better control if needed, but errorText works well.
                        
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () => setState(() => _isEditingUsername = false),
                              child: const Text("Bekor qilish", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ),
                            if (_isSavingUsername)
                               const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            else
                               TextButton(
                                 onPressed: _saveUsername,
                                 child: const Text("Saqlash", style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                               )
                          ],
                        )
                      ],
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () => setState(() => _isEditingUsername = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[300]!)
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            student.username != null ? "@${student.username}" : "Username o'rnatish",
                            style: TextStyle(
                              color: student.username != null ? Colors.black87 : AppTheme.primaryBlue, 
                              fontWeight: FontWeight.w600,
                              fontSize: 14
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.edit, size: 14, color: Colors.grey[600])
                        ],
                      ),
                    ),
                  ),
                // -----------------------

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

  // 4. Image Picker
  void _pickAndUploadImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    
    if (image != null) {
      // Show loading snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Rasm yuklanmoqda...")),
      );
      
      final DataService dataService = DataService();
      final newUrl = await dataService.uploadProfileImage(image.path);
      
      if (newUrl != null && context.mounted) {
         // Update Provider
         Provider.of<AuthProvider>(context, listen: false).updateProfileImage(newUrl);
         
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Rasm muvaffaqiyatli o'zgartirildi!")),
         );
      } else if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Rasm yuklashda xatolik!")),
         );
      }
    }
  }

  void _showImageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context, 
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.primaryBlue),
              title: const Text("Galereyadan tanlash"),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadImage(context);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      )
    );
  }
}

// End of file
