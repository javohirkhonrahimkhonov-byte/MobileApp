import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/community_models.dart';
import '../services/community_service.dart';
import '../widgets/post_card.dart';
import '../widgets/shimmer_post.dart';
import '../screens/create_post_screen.dart';
import 'chat_list_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final CommunityService _service = CommunityService();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundWhite,
        appBar: AppBar(
          title: const Text("Choyxona", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          bottom: const TabBar(
            labelColor: AppTheme.primaryBlue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryBlue,
            isScrollable: true,
            tabs: [
              Tab(text: "Yo'nalish"),
              Tab(text: "Fakultet"),
              Tab(text: "Universitet"),
              Tab(text: "Respublika"),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.black),
              onPressed: () {},
            ),
            IconButton(
              icon: Stack(
                children: [
                   const Icon(Icons.chat_bubble_outline_rounded, color: Colors.black),
                   Positioned(
                     right: 0,
                     top: 0,
                     child: Container(
                       width: 8,
                       height: 8,
                       decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                     ),
                   )
                ],
              ),
              onPressed: () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen()));
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: TabBarView(
          children: [
            _buildFeed("specialty"),
            _buildFeed("faculty"),
            _buildFeed("university"),
            _buildFeed("republic"),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreatePostScreen()),
            );
          },
          backgroundColor: AppTheme.primaryBlue,
          icon: const Icon(Icons.edit, color: Colors.white),
          label: const Text("Fikr bildirish", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }



  Widget _buildFeed(String scope) {
    return FutureBuilder<List<Post>>(
      future: _service.getPosts(scope: scope),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
             padding: const EdgeInsets.all(16),
             itemCount: 3,
             itemBuilder: (ctx, i) => const ShimmerPost(),
          );
        }
        if (snapshot.hasError) {
          return Center(child: Text("Xatolik: ${snapshot.error}"));
        }
        final posts = snapshot.data ?? [];
        
        // Combine Input Widget + Posts
        final int itemCount = posts.isEmpty ? 2 : posts.length + 1; // 1 for Input

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Extra bottom padding for FAB
          itemCount: itemCount,
          itemBuilder: (context, index) {
            // Index 0: Write Post Input
            if (index == 0) {
              return _buildWritePostInput();
            }

            // Empty State (if no posts)
            if (posts.isEmpty) {
               return _buildEmptyState();
            }

            // Posts (index - 1 because of Input widget)
            return PostCard(post: posts[index - 1]);
          },
        );
      },
    );
  }

  Widget _buildWritePostInput() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
           BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreatePostScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.backgroundWhite,
                  child: Icon(Icons.person, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Nima haqida o'ylayapsiz?",
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                ),
                Icon(Icons.edit_note_rounded, color: AppTheme.primaryBlue.withOpacity(0.8)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "Hozircha jimjitlik...",
              style: TextStyle(color: Colors.grey[600], fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Birinchi bo'lib fikr bildiring!",
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreatePostScreen()),
                );
              },
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text("Post yozish", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            )
          ],
        ),
      ),
    );
  }
}
