import 'dart:async';
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

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  final CommunityService _service = CommunityService();
  late TabController _tabController;
  Timer? _pollTimer;

  // State Management for Silent Updates
  final Map<String, List<Post>> _posts = {
    'university': [],
    'specialty': [],
    'faculty': [],
  };
  final Map<String, bool> _isLoading = {
    'university': true,
    'specialty': true,
    'faculty': true,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _tabController.addListener(_handleTabSelection);
    
    // Initial Load
    _loadAllScopes();
    
    // Start Polling (Real-time Simulation)
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {}); // Rebuild to show correct scope
      _fetchPosts(_getCurrentScope(), isSilent: false); // Force refresh on tab switch
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        // Refresh ONLY the active scope to save bandwidth
        _fetchPosts(_getCurrentScope(), isSilent: true);
      }
    });
  }

  Future<void> _loadAllScopes() async {
    await Future.wait([
      _fetchPosts('university'),
      _fetchPosts('specialty'),
      _fetchPosts('faculty'),
    ]);
  }

  Future<void> _fetchPosts(String scope, {bool isSilent = false}) async {
    if (!isSilent) {
      setState(() {
        _isLoading[scope] = true;
      });
    }

    try {
      final newPosts = await _service.getPosts(scope: scope);
      if (mounted) {
        setState(() {
          _posts[scope] = newPosts;
          _isLoading[scope] = false;
        });
      }
    } catch (e) {
      if (mounted && !isSilent) {
        setState(() {
          _isLoading[scope] = false;
        });
      }
      debugPrint("Polling Error: $e");
    }
  }

  String _getCurrentScope() {
    switch (_tabController.index) {
      case 0: return 'university';
      case 1: return 'specialty';
      case 2: return 'faculty';
      default: return 'university';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppTheme.backgroundWhite,
        appBar: AppBar(
          title: const Text("Choyxona", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey[600],
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))
                  ]
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelPadding: EdgeInsets.zero,
                tabs: const [
                  Tab(child: Text("Universitet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  Tab(child: Text("Yo'nalish", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  Tab(child: Text("Fakultet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                ],
              ),
            ),
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
                       child: Center(
                         child: Text(
                             "1", 
                             style: TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.bold)
                         ),
                       ),
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
          controller: _tabController,
          children: [
            _buildFeed("university"),
            _buildFeed("specialty"),
            _buildFeed("faculty"),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CreatePostScreen(initialScope: _getCurrentScope())),
            );
            if (result == true) {
              _fetchPosts(_getCurrentScope(), isSilent: false); // Immediate refresh
            }
          },
          backgroundColor: AppTheme.primaryBlue,
          child: const Icon(Icons.edit, color: Colors.white),
        ),
      );
  }

  Widget _buildFeed(String scope) {
    if (_isLoading[scope] == true && (_posts[scope] == null || _posts[scope]!.isEmpty)) {
      return ListView.builder(
         padding: const EdgeInsets.all(16),
         itemCount: 3,
         itemBuilder: (ctx, i) => const ShimmerPost(),
      );
    }
    
    final posts = _posts[scope] ?? [];
    
    if (posts.isEmpty) {
       return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _fetchPosts(scope, isSilent: false);
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          return PostCard(post: posts[index]);
        },
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
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreatePostScreen(initialScope: _getCurrentScope())),
                );
                if (result == true) {
                   _fetchPosts(_getCurrentScope(), isSilent: false);
                }
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
