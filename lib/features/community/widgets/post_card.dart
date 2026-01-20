import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/role_mapper.dart';
import '../models/community_models.dart';
import '../services/community_service.dart';
import '../screens/user_profile_screen.dart'; 
import 'edit_post_sheet.dart';
import 'comment_sheet.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final bool isDetail;
  final Function(bool isLiked, int count)? onLikeChanged;
  final Function(bool isReposted, int count)? onRepostChanged; // Added this back
  final VoidCallback? onDelete; 

  const PostCard({
    super.key, 
    required this.post, 
    this.isDetail = false,
    this.onLikeChanged,
    this.onRepostChanged, // Added this back
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
  bool _isExpanded = false; 
  bool _isVoting = false;
  
  List<int>? _pollVotes;
  int? _userVote; 
  
  late int _commentCount;
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
     _commentCount = widget.post.commentsCount;
     _repostCount = widget.post.repostsCount;
     _isReposted = widget.post.isRepostedByMe; 
     _pollVotes = widget.post.pollVotes;
     _userVote = widget.post.userVote;
     _currentContent = widget.post.content; 
  }

  void _toggleLike() async {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    widget.onLikeChanged?.call(_isLiked, _likeCount); 

    final result = await CommunityService().likePost(widget.post.id);
    if (result == null) {
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
    setState(() {
      _isReposted = !_isReposted;
      _repostCount += _isReposted ? 1 : -1;
    });

    widget.onRepostChanged?.call(_isReposted, _repostCount); // Notify Parent

    final result = await CommunityService().repostPost(widget.post.id);

    if (result == null && mounted) {
        setState(() {
          _isReposted = !_isReposted;
          _repostCount += _isReposted ? 1 : -1;
        });
        widget.onRepostChanged?.call(_isReposted, _repostCount);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Repost amalga oshmadi")));
    } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isReposted ? "Repost qilindi 🔄" : "Repost qaytarib olindi"))
        );
    }
  }

  void _votePoll(int optionIndex) async {
    if (_userVote != null || _isVoting) return; 

    setState(() => _isVoting = true);

    setState(() {
      _userVote = optionIndex;
      _pollVotes![optionIndex]++;
    });

    await Future.delayed(const Duration(milliseconds: 500)); 

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

  Color _getCategoryColor(String type) {
    if (type == 'university') return Colors.blue;
    if (type == 'faculty') return Colors.orange;
    if (type == 'specialty') return Colors.green;
    return Colors.grey;
  }

  String _getCategoryLabel(String type) {
    if (type == 'university') return "Universitet";
    if (type == 'faculty') return "Fakultet";
    if (type == 'specialty') return "Yo'nalish";
    return "";
  }



  void _showEditDialog() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (ctx) => EditPostSheet(
        postId: widget.post.id,
        initialContent: _currentContent, 
      ),
    );

    if (result != null && result is String) {
       // 1. Optimistic Update (Immediate)
       final previousContent = _currentContent;
       setState(() {
         _currentContent = result;
       });

       // 2. Background API Call (Fire & Forget logic moved to here)
       try {
         final success = await CommunityService().editPost(widget.post.id, result);
         if (!success && mounted) {
           // Revert on failure
           setState(() => _currentContent = previousContent);
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Xatolik: O'zgarishlar saqlanmadi ❌")),
           );
         } else if (success && mounted) {
            // Optional: Silent success or small indicator
         }
       } catch (e) {
         if (mounted) {
           setState(() => _currentContent = previousContent);
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("Xatolik: $e")),
           );
         }
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
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
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                          ],
                        ),
                        // Username or Role Line
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            // If username exists, show it
                            if (widget.post.authorUsername.isNotEmpty) ...[
                               Text(
                                 "@${widget.post.authorUsername}",
                                 style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
                               ),
                               const SizedBox(width: 6),
                               const Text("•", style: TextStyle(color: Colors.grey, fontSize: 10)),
                               const SizedBox(width: 6),
                            ],
                            
                            Text(
                              RoleMapper.getLabel(widget.post.authorRole),
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ),
                        const SizedBox(width: 8),
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                           decoration: BoxDecoration(
                             color: _getCategoryColor(widget.post.scope ?? 'university').withOpacity(0.1),
                             borderRadius: BorderRadius.circular(4),
                             border: Border.all(color: _getCategoryColor(widget.post.scope ?? 'university').withOpacity(0.3), width: 0.5)
                           ),
                           child: Text(
                             _getCategoryLabel(widget.post.scope ?? 'university'),
                             style: TextStyle(color: _getCategoryColor(widget.post.scope ?? 'university'), fontSize: 10, fontWeight: FontWeight.bold),
                           ),
                         ),
                        const SizedBox(width: 4),
                        Text(
                          "• ${widget.post.timeAgo}",
                          style: TextStyle(color: Colors.grey[400], fontSize: 13),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              if (widget.post.isMine)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey), 
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
          
          // Content 
          _buildFoldableContent(),
          
          const SizedBox(height: 12),

          if (widget.post.pollOptions != null && widget.post.pollOptions!.isNotEmpty)
            _buildPoll(),

          if (widget.post.mediaUrls.isNotEmpty)
             _buildMediaGrid(), 

          const SizedBox(height: 12),
          
          // Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               _buildActionButton(
                 icon: Icons.chat_bubble_outline, 
                 label: "$_commentCount",
                 onTap: () {
                   showModalBottomSheet(
                     context: context,
                     isScrollControlled: true,
                     backgroundColor: Colors.transparent,
                     builder: (context) => CommentSheet(
                       post: widget.post,
                       onCommentCountChanged: (newCount) {
                         setState(() => _commentCount = newCount);
                       },
                     )
                   );
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
  
  // Keep original _buildPoll same as removed for brevity in overwrite but implied presence
  Widget _buildPoll() {
     if (widget.post.pollOptions == null) return const SizedBox.shrink();
     
     int totalVotes = 0;
     if (_pollVotes != null) {
       totalVotes = _pollVotes!.fold(0, (p, c) => p + c);
     }
     if (totalVotes == 0) totalVotes = 1; 

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50], 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(widget.post.pollOptions!.length, (index) {
          final option = widget.post.pollOptions![index];
          final votes = _pollVotes![index];
          final percent = votes / totalVotes;
          final isSelected = _userVote == index;
          final showResults = _userVote != null;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: InkWell(
              onTap: () => _votePoll(index),
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  if (showResults)
                    Container(
                      height: 36,
                      width: MediaQuery.of(context).size.width * percent * 0.7, // 70% width max inside layout
                      decoration: BoxDecoration(
                         color: isSelected ? AppTheme.primaryBlue.withOpacity(0.2) : Colors.grey[200],
                         borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryBlue : Colors.grey[300]!,
                        width: isSelected ? 2 : 1
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(option, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
                        if (showResults)
                          Text("${(percent * 100).toStringAsFixed(0)}%", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isSelected ? AppTheme.primaryBlue : Colors.grey[600]))
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFoldableContent() {
    final content = _currentContent; 
    
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
      final lines = content.split('\n');
      if (lines.length > 1) {
         title = lines.first.trim();
         body = lines.sublist(1).join('\n').trim();
         hasTitle = title.isNotEmpty && body.isNotEmpty;
      }
    }
    
    const maxLines = 4;
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
               child: Text("Davomi", style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold)),
             ),
           )
        ],
      );
    }
  }
}
