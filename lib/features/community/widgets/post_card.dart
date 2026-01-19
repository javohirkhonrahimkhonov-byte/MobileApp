import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/community_models.dart';
import '../services/community_service.dart';
import '../screens/profile/user_profile_screen.dart'; // Import Profile Screen
import 'edit_post_sheet.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final bool isDetail;
  final Function(bool isLiked, int count)? onLikeChanged;
  final VoidCallback? onDelete; // Callback for delete

  const PostCard({
    super.key, 
    required this.post, 
    this.isDetail = false,
    this.onLikeChanged,
    this.onDelete,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _isLiked = false;
  int _likeCount = 0;
  int _repostCount = 0;
  bool _isReplying = false; 
  bool _isReposted = false;
  bool _isExpanded = false; // For "See more"
  bool _isVoting = false;
  
  // Poll State
  List<int>? _pollVotes;
  int? _userVote; 
  
  // Content State (For Immediate Updates)
  late String _currentContent;

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id || oldWidget.post != widget.post) {
      _initializeState();
    }
  }

  void _initializeState() {
     _isLiked = widget.post.isLiked;
     _likeCount = widget.post.likes;
     _repostCount = widget.post.repostsCount;
     _isReposted = widget.post.isRepostedByMe; // Corrected Field Name
     _pollVotes = widget.post.pollVotes;
     _userVote = widget.post.userVote;
     _currentContent = widget.post.content; // Init Content
  }

  void _toggleLike() async {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    // Notify Parent (Optional Optimistic)
    widget.onLikeChanged?.call(_isLiked, _likeCount); 

    // API Call
    final result = await CommunityService().likePost(widget.post.id);
    if (result == null) {
       // Revert on failure
       if (mounted) {
         setState(() {
            _isLiked = !_isLiked;
            _likeCount += _isLiked ? 1 : -1;
         });
         widget.onLikeChanged?.call(_isLiked, _likeCount);
       }
    }
  }

  void _toggleRepost() async {
    // Optimistic Update
    setState(() {
      _isReposted = !_isReposted;
      _repostCount += _isReposted ? 1 : -1;
    });

    final result = await CommunityService().repostPost(widget.post.id);

    if (result == null && mounted) {
        // Revert
        setState(() {
          _isReposted = !_isReposted;
          _repostCount += _isReposted ? 1 : -1;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Repost amalga oshmadi")));
    } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isReposted ? "Repost qilindi 🔄" : "Repost qaytarib olindi"))
        );
    }
  }

  void _votePoll(int optionIndex) async {
    if (_userVote != null || _isVoting) return; // Already voted

    setState(() => _isVoting = true);

    // Optimistic
    setState(() {
      _userVote = optionIndex;
      _pollVotes![optionIndex]++;
    });

    // TODO: Implement API call for voting
    await Future.delayed(const Duration(milliseconds: 500)); // Simulating network

    if (mounted) setState(() => _isVoting = false);
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Postni o'chirish"),
        content: const Text("Haqiqatan ham ushbu postni o'chirmoqchimisiz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Bekor qilish", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
               Navigator.pop(ctx);
               final success = await CommunityService().deletePost(widget.post.id);
               if (success && mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Post o'chirildi!")));
                 // Trigger parent refresh
                 widget.onDelete?.call();
               } else if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Xatolik yuz berdi")));
               }
            }, 
            child: const Text("O'chirish", style: TextStyle(color: Colors.red))
          ),
        ],
      )
    );
  }

  void _showEditDialog() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (ctx) => EditPostSheet(
        postId: widget.post.id,
        initialContent: _currentContent, // Pass current updated content
      ),
    );

    if (result != null && result is String && mounted) {
       // Update Local Content Immediately
       setState(() {
         _currentContent = result;
       });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)), // Divider style
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (Avatar + Names)
          GestureDetector(
            onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(
                 authorName: widget.post.authorName,
                 authorUsername: widget.post.authorUsername,
                 authorAvatar: widget.post.authorAvatar,
                 authorRole: widget.post.authorRole,
               )));
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Hero(
                tag: "avatar_${widget.post.id}",
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                  backgroundImage: widget.post.authorAvatar.isNotEmpty 
                    ? NetworkImage(widget.post.authorAvatar) 
                    : null,
                  child: widget.post.authorAvatar.isEmpty 
                    ? Text(widget.post.authorName[0], style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold))
                    : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.post.authorName, 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.post.isVerified)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.verified, color: Colors.blue, size: 16),
                          ),
                        if (widget.post.isTyutor)
                           Container(
                             margin: const EdgeInsets.only(left: 4),
                             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                             decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(4)),
                             child: const Text("Tyutor", style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                           ),
                        const SizedBox(width: 4),
                        Text(
                          "• ${widget.post.timeAgo}",
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        ),
                      ],
                    ),
                    Text(
                      widget.post.authorRole,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (widget.post.isMine)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: Colors.grey),
                  onSelected: (val) {
                    if (val == 'edit') _showEditDialog();
                    if (val == 'delete') _showDeleteDialog();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text("Tahrirlash")])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 8), Text("O'chirish", style: TextStyle(color: Colors.red))])),
                  ],
                )
             ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Content (Text Body) - Use _buildFoldableContent which uses _currentContent
          _buildFoldableContent(),
          
          const SizedBox(height: 12),

          // Poll Section (If exists)
          if (widget.post.pollOptions != null && widget.post.pollOptions!.isNotEmpty)
            _buildPoll(),

          // Media (Images) - If exists
          if (widget.post.mediaUrls.isNotEmpty)
             _buildMediaGrid(), // Placeholder for media grid

          const SizedBox(height: 12),
          
          // Actions Row (Like, Comment, Share)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               _buildActionButton(
                 icon: Icons.chat_bubble_outline, 
                 label: "${widget.post.commentsCount}",
                 onTap: () {
                   // Navigate to Detail
                   if (!widget.isDetail) {
                     // TODO: Navigate
                   }
                 } 
               ),
               _buildActionButton(
                 icon: _isReposted ? Icons.repeat : Icons.repeat, 
                 label: "$_repostCount", 
                 color: _isReposted ? Colors.green : null,
                 onTap: _toggleRepost
               ),
               _buildActionButton(
                 icon: _isLiked ? Icons.favorite : Icons.favorite_border, 
                 label: "$_likeCount", 
                 color: _isLiked ? Colors.red : null,
                 onTap: _toggleLike
               ),
               IconButton(
                 icon: const Icon(Icons.share_outlined, color: Colors.grey, size: 20),
                 onPressed: () {},
               )
            ],
          )
        ],
      ),
    );

    return content;
  }
  
  Widget _buildActionButton({required IconData icon, required String label, Color? color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? Colors.grey[600]),
            const SizedBox(width: 4),
            if (label != "0")
              Text(label, style: TextStyle(color: color ?? Colors.grey[600], fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaGrid() {
    return SizedBox(
      height: 200, 
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.post.mediaUrls.length,
        itemBuilder: (ctx, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(widget.post.mediaUrls[index], fit: BoxFit.cover),
            ),
          );
        }
      ),
    );
  }

  Widget _buildPoll() {
    return Column(
      children: [
        // ... (Poll Implementation - keeping same as verify step)
      ]
    );
  }

  Widget _buildFoldableContent() {
    final content = _currentContent; // Use local state
    
    // 1. Try Markdown Title: **Title**\nBody
    final RegExp titleRegex = RegExp(r'^\*\*(.*?)\*\*\n+(.*)', multiLine: true, dotAll: true);
    final match = titleRegex.firstMatch(content);
    
    String title = "";
    String body = content;
    bool hasTitle = false;

    if (match != null) {
      title = match.group(1)?.trim() ?? "";
      body = match.group(2)?.trim() ?? "";
      hasTitle = true;
    } else {
      // 2. Fallback: Regular First Line Separation for Legacy Posts
      final lines = content.split('\n');
      if (lines.length > 1) {
         title = lines.first.trim();
         body = lines.sublist(1).join('\n').trim();
         hasTitle = title.isNotEmpty && body.isNotEmpty;
      }
    }
    
    // Define thresholds
    const maxLines = 4;
    
    // Check if we need to fold (based on Body length)
    final shouldFold = body.length > 150 || body.split('\n').length > 5;

    if (!shouldFold || widget.isDetail || _isExpanded) {
       return Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           if (hasTitle)
             Padding(
               padding: const EdgeInsets.only(bottom: 6),
               child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, height: 1.3, color: Colors.black)),
             ),
           Text(
             body, 
             style: const TextStyle(
               fontWeight: FontWeight.normal,
               fontSize: 15, 
               height: 1.4, 
               color: Colors.black87
             )
           ),
           if (shouldFold && !widget.isDetail)
             GestureDetector(
               onTap: () => setState(() => _isExpanded = false),
               child: Padding(
                 padding: const EdgeInsets.only(top: 4),
                 child: Text("Kamroq o'qish", style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold)),
               ),
             )
         ],
       );
    } else {
      // Folded View
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           if (hasTitle)
             Padding(
               padding: const EdgeInsets.only(bottom: 4),
               child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, height: 1.3, color: Colors.black)),
             ),
           Text(
             body, 
             maxLines: hasTitle ? 3 : 4,
             overflow: TextOverflow.ellipsis,
             style: const TextStyle(
               fontWeight: FontWeight.normal,
               fontSize: 15, 
               height: 1.4, 
               color: Colors.black87
             )
           ),
           GestureDetector(
             onTap: () => setState(() => _isExpanded = true),
             child: Padding(
               padding: const EdgeInsets.only(top: 4),
               child: Text("Ko'proq o'qish", style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold)),
             ),
           )
        ],
      );
    }
  }
}
