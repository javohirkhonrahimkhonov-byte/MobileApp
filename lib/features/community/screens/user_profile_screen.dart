import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/community_models.dart';
import '../services/community_service.dart';
import '../widgets/post_card.dart';

class UserProfileScreen extends StatefulWidget {
  final String authorName;
  final String authorUsername;
  final String authorAvatar;
  final String authorRole;

  const UserProfileScreen({
    super.key,
    required this.authorName,
    required this.authorUsername,
    required this.authorAvatar,
    required this.authorRole,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final CommunityService _service = CommunityService();

  int _postCount = 0;
  bool _isLoading = true;
  List<Post> _posts = [];

  @override
  void initState() {
    super.initState();
    _loadUserPosts();
  }

  Future<void> _loadUserPosts() async {
    // Fetch posts where authorName matches (Not ideal but works for now as we don't pass ID)
    // Better: Filter locally from fetching all univ posts or add endpoint. 
    // Assuming getPosts returns all univ posts, filtering by name is fragile but consistent with current app logic context.
    // Actually `getPosts` supports filtering by scope.
    
    // We will simulate fetching specific user posts by filtering the list
    // In a real app we'd call `getPosts(userId: ...)`
    try {
      final allPosts = await _service.getPosts(scope: "university");
      final userPosts = allPosts.where((p) => p.authorName == widget.authorName).toList();
      
      if (mounted) {
        setState(() {
          _posts = userPosts;
          _postCount = userPosts.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Name Splitting Logic
    final nameParts = widget.authorName.split(" ");
    String line1 = widget.authorName;
    String line2 = "";
    
    if (nameParts.length > 2) {
      line1 = "${nameParts[0]} ${nameParts[1]}";
      line2 = nameParts.sublist(2).join(" ");
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(widget.authorUsername, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Avatar
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                      backgroundImage: widget.authorAvatar.isNotEmpty ? NetworkImage(widget.authorAvatar) : null,
                      child: widget.authorAvatar.isEmpty 
                         ? Text(widget.authorName[0], style: const TextStyle(fontSize: 32, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold))
                         : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Centered & Split Name
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Text(
                          line1.toUpperCase(), 
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                        ),
                        if (line2.isNotEmpty)
                          Text(
                            line2.toUpperCase(), 
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  Text(widget.authorRole, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  
                  const SizedBox(height: 24),
                  
                  // Dynamic Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStat("Postlar", "$_postCount"),
                      _buildStat("Kuzatuvchilar", "0"), 
                      _buildStat("Obuna", "0"),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                          elevation: 0,
                        ),
                        child: const Text("Kuzatish", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: const BorderSide(color: Colors.black12),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text("Xabar yozish", style: TextStyle(color: Colors.black)),
                      )
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                const TabBar(
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.black,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: [
                    Tab(icon: Icon(Icons.grid_on)), // User Posts
                    Tab(icon: Icon(Icons.repeat)),  // Reposts
                  ],
                ),
              ),
              pinned: true,
            ),
          ],
          body: TabBarView(
            children: [
              // 1. User Posts
              _isLoading 
                 ? const Center(child: CircularProgressIndicator()) 
                 : _posts.isEmpty 
                    ? const Center(child: Text("Postlar yo'q", style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: _posts.length,
                        itemBuilder: (ctx, i) => PostCard(post: _posts[i]),
                      ),
                      
              // 2. Reposts (Placeholder)
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.repeat, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text("Repostlar yo'q", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
