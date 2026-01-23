import 'package:flutter/material.dart';
import '../services/community_service.dart';
import '../../../../core/models/student.dart';
import '../../../../core/theme/app_theme.dart';
import '../screens/user_profile_screen.dart';

class UserSearchDelegate extends SearchDelegate {
  final CommunityService _service = CommunityService();

  @override
  String get searchFieldLabel => "Talabalarni qidirish...";

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchList();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.length < 2) {
       return FutureBuilder<List<String>>(
         future: _service.getSearchHistory(),
         builder: (context, snapshot) {
           final history = snapshot.data ?? [];
           
           if (history.isEmpty) {
             return Container(
               color: Colors.white,
               child: const Center(
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Icon(Icons.search, size: 64, color: Colors.grey),
                     SizedBox(height: 16),
                     Text("Username yoki ism kiriting\n(kamida 2 ta harf)", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                   ],
                 ),
               ),
             );
           }
           
           return Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Padding(
                 padding: const EdgeInsets.all(16),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     const Text("So'nggi qidiruvlar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                     TextButton(
                       onPressed: () async {
                         await _service.clearSearchHistory();
                         showSuggestions(context); // Refresh
                       }, 
                       child: const Text("Tozalash", style: TextStyle(color: Colors.red))
                     )
                   ],
                 ),
               ),
               Expanded(
                 child: ListView.builder(
                   itemCount: history.length,
                   itemBuilder: (context, index) {
                     final item = history[index];
                     return ListTile(
                       leading: const Icon(Icons.history, color: Colors.grey),
                       title: Text(item),
                       onTap: () {
                         query = item;
                         showResults(context);
                       },
                       trailing: IconButton(
                         icon: const Icon(Icons.close, size: 16),
                         onPressed: () {
                           // Remove individual item (Logic needed in service but for now reload)
                           // Ideally _service.removeFromHistory(item).
                           // We will skip single remove for now or just ignore.
                         },
                       ),
                     );
                   },
                 ),
               ),
             ],
           );
         }
       );
    }
    return _buildSearchList();
  }

  Widget _buildSearchList() {
    return FutureBuilder<List<Student>>(
      future: _service.searchStudents(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
           return const Center(child: Text("Xatolik yuz berdi"));
        }
        
        final students = snapshot.data ?? [];
        
        if (students.isEmpty) {
           return const Center(child: Text("Hech kim topilmadi"));
        }

        return ListView.builder(
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            return Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                    backgroundImage: student.imageUrl != null && student.imageUrl!.isNotEmpty
                        ? NetworkImage(student.imageUrl!)
                        : null,
                    child: (student.imageUrl == null || student.imageUrl!.isEmpty)
                        ? Text(student.fullName.isNotEmpty ? student.fullName[0] : "?", style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 18))
                        : null,
                  ),
                  title: Row(
                    children: [
                      Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (student.isPremium) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: Colors.blue, size: 16),
                      ]
                    ],
                  ),
                  subtitle: Text("@${student.username ?? 'usernamesiz'}", style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w500)),
                  onTap: () {
                     // Save to history
                     _service.saveSearchQuery(query);
                     
                    // Navigate to Profile
                    Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(
                      authorName: student.fullName,
                      authorId: student.id.toString(),
                      authorUsername: student.username ?? "",
                      authorAvatar: student.imageUrl ?? "",
                      authorRole: "Talaba",
                      authorIsPremium: student.isPremium, // NEW
                    )));
                  },
                ),
                const Divider(height: 1, thickness: 1, indent: 72), // Divider with indentation
              ],
            );
          },
        );
      },
    );
  }
}
