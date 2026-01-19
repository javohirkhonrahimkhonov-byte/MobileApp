import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/community_models.dart';
import 'package:talabahamkor_mobile/features/community/screens/post_detail_screen.dart';
import 'package:share_plus/share_plus.dart';
import '../screens/user_profile_screen.dart';

import '../services/community_service.dart';

class PostCard extends StatefulWidget {
  // ... (keep class definition)
  final Post post;
  final bool isDetail;
  final Function(bool isLiked, int count)? onLikeChanged;
  final VoidCallback? onDelete; // New callback

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
  // ... (state vars)
  late bool _isLiked;
  late int _likeCount;
  late int _repostCount;
  late bool _isReposted;
  List<int>? _pollVotes;
  int? _userVote;
  final CommunityService _communityService = CommunityService();

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _likeCount = widget.post.likes;
    _repostCount = widget.post.repostsCount;
    _isReposted = widget.post.isRepostedByMe;
    _pollVotes = widget.post.pollVotes != null ? List.from(widget.post.pollVotes!) : null;
    _userVote = widget.post.userVote;
  }
  
  bool _isExpanded = false;
  
  // ... (votePoll)
  void _votePoll(int index) {
    if (_userVote != null) return; 
    setState(() {
      _userVote = index;
      _pollVotes![index]++;
    });
  }

  Future<void> _toggleLike() async {
    // Optimistic Update
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
    
    if (widget.onLikeChanged != null) {
      widget.onLikeChanged!(_isLiked, _likeCount);
    }

    try {
      final result = await _communityService.likePost(widget.post.id);
      if (result == null) {
        // Revert if failed
        if (mounted) {
           setState(() {
              _isLiked = !_isLiked;
              _likeCount += _isLiked ? 1 : -1;
           });
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Xatolik: Like bosilmadi")));
        }
      } else {
         // Sync with server count if needed
         if (mounted) {
             setState(() {
               _likeCount = result['count'] ?? _likeCount;
               // _isLiked is already toggled, but we could double check: result['liked']
             });
             // Update parent again with authoritative count
             if (widget.onLikeChanged != null) {
                widget.onLikeChanged!(_isLiked, _likeCount);
             }
         }
      }
    } catch (e) {
      if (mounted) {
           setState(() {
              _isLiked = !_isLiked;
              _likeCount += _isLiked ? 1 : -1;
           });
      }
    }
  }

  Future<void> _toggleRepost() async {
    setState(() {
      _isReposted = !_isReposted;
      _repostCount += _isReposted ? 1 : -1;
    });

    try {
      final result = await _communityService.repostPost(widget.post.id);
      if (result == null) {
         if (mounted) {
            setState(() {
               _isReposted = !_isReposted;
               _repostCount += _isReposted ? 1 : -1;
            });
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Xatolik: Repost qilinmadi")));
         }
      } else {
         if (mounted) {
            setState(() {
               _repostCount = result['count'] ?? _repostCount;
            });
         }
      }
    } catch (e) {
      if (mounted) {
         setState(() {
            _isReposted = !_isReposted;
            _repostCount += _isReposted ? 1 : -1;
         });
      }
    }
  }

  void _sharePost() {
    Share.share(
      " ${widget.post.authorName} dan yangi post:\n\n${widget.post.content}\n\nTalaba Hamkor ilovasi orqali yuborildi.",
      subject: "Choyxona Posti"
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Postni o'chirib yuborish"),
        content: const Text("Haqiqatan ham bu postni o'chirmoqchimisiz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Bekor qilish")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await _communityService.deletePost(widget.post.id);
              if (success && mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Post o'chirildi")));
                 // Ideally trigger a refresh in parent, but for now we rely on next poll/refresh
              } else if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Xatolik: Post o'chirilmayapti")));
              }
            }, 
            child: const Text("O'chirish", style: TextStyle(color: Colors.red))
          ),
        ],
      )
    );
  }

  void _showEditDialog() {
    final controller = TextEditingController(text: widget.post.content);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Postni tahrirlash"),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Bekor qilish")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await _communityService.editPost(widget.post.id, controller.text);
              if (success && mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Post yangilandi")));
                 // Ideally trigger refresh
              } else if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Xatolik: Post yangilanmadi")));
              }
            }, 
            child: const Text("Saqlash")
          ),
        ],
      )
    );
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
                  radius: 22,
                  backgroundImage: widget.post.authorAvatar.isNotEmpty ? NetworkImage(widget.post.authorAvatar) : null,
                  backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                  child: widget.post.authorAvatar.isEmpty 
                    ? Text(widget.post.authorName[0], style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold))
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.post.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: Colors.blue, size: 16),
                        ],
                      ],
                    ),
                    Text(
                      "${widget.post.authorUsername} • ${widget.post.timeAgo}",
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (widget.post.isMine)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: Colors.grey),
                  onSelected: (value) {
                    if (value == 'edit') _showEditDialog();
                    if (value == 'delete') _showDeleteDialog();
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Text('Tahrirlash'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('O\'chirib yuborish', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          ),
          
          // Body content
          Padding(
             padding: const EdgeInsets.only(left: 56), // Align with text start
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 const SizedBox(height: 4),
                 const SizedBox(height: 4),
                 _buildFoldableContent(),
                 
                 // Tags
                 if (widget.post.tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 8,
                        children: widget.post.tags.map((tag) => Text(tag, style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 13))).toList(),
                      ),
                    ),

                 // Media Grid
                 if (widget.post.mediaUrls.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildMediaGrid(),
                    ),

                 // Poll
                 if (widget.post.pollOptions != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildPoll(),
                    ),

                 const SizedBox(height: 12),
                 
                 // Actions
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                      _buildAction(
                        icon: Icons.chat_bubble_outline_rounded, 
                        count: widget.post.commentsCount, 
                        color: Colors.grey,
                        onTap: () {
                           if (!widget.isDetail) {
                               _openDetail();
                           }
                        }
                      ),
                      _buildAction(
                        icon: _isReposted ? Icons.repeat_rounded : Icons.repeat_rounded, 
                        count: _repostCount, 
                        color: _isReposted ? Colors.green : Colors.grey,
                        onTap: _toggleRepost
                      ),
                      _buildAction(
                        icon: _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, 
                        count: _likeCount, 
                        color: _isLiked ? Colors.pink : Colors.grey,
                        onTap: _toggleLike
                      ),
                      _buildAction(
                        icon: Icons.share_rounded, 
                        count: null, // Share usually doesn't show count locally unless API provided
                        color: Colors.grey,
                        onTap: _sharePost
                      ),
                   ],
                 )
               ],
             ),
          )
        ],
      ),
    );

    if (widget.isDetail) return content;

    return InkWell(
      onTap: _openDetail,
      child: content,
    );
  }

  Future<void> _openDetail() async {
    final currentPost = widget.post.copyWith(
         isLiked: _isLiked,
         likes: _likeCount,
         isRepostedByMe: _isReposted,
         repostsCount: _repostCount,
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(post: currentPost),
      ),
    );
    
    if (result == 'deleted') {
       if (widget.onDelete != null) widget.onDelete!();
       return;
    }

    if (result != null && result is Post) {
      // Sync back any changes from Detail Screen
      bool changed = false;
      if (result.isLiked != _isLiked || result.likes != _likeCount) {
         _isLiked = result.isLiked;
         _likeCount = result.likes;
         changed = true;
      }
      if (result.isRepostedByMe != _isReposted || result.repostsCount != _repostCount) {
         _isReposted = result.isRepostedByMe;
         _repostCount = result.repostsCount;
         changed = true;
      }

      if (changed) {
         setState(() {});
         // Optionally notify parent
         if (widget.onLikeChanged != null) {
            widget.onLikeChanged!(_isLiked, _likeCount);
         }
      }
    }
  }

  Widget _buildMediaGrid() {
    final urls = widget.post.mediaUrls;
    if (urls.isEmpty) return const SizedBox.shrink();

    // Simple implementation: Just show first image rounded
    // In real app, would use GridView or StaggeredGrid
    // Since mock data only has 1 url usually, we keep it simple.
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16/9,
        child: Image.network(
           urls.first, 
           fit: BoxFit.cover,
           errorBuilder: (ctx, _, __) => Container(
             color: Colors.grey[200],
             child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
           ),
        ),
      ),
    );
  }

  Widget _buildAction({required IconData icon, int? count, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            if (count != null && count > 0) ...[
               const SizedBox(width: 4),
               Text("$count", style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.normal))
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildPoll() {
     // (Re-using existing Poll Logic but styled lighter)
    int totalVotes = _pollVotes!.reduce((a, b) => a + b);
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
    final content = widget.post.content;
    final lines = content.split('\n');
    final hasTitle = lines.length > 1;
    final title = lines.isNotEmpty ? lines.first : "";
    final body = lines.length > 1 ? lines.sublist(1).join('\n').trim() : "";
    
    // Define thresholds
    const maxLines = 4;
    
    // Check if we need to fold
    final shouldFold = content.length > 150 || content.split('\n').length > 5;

    if (!shouldFold || widget.isDetail || _isExpanded) {
       return Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           if (hasTitle)
             Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 1.4, color: Colors.black)),
           if (hasTitle && body.isNotEmpty)
             const SizedBox(height: 4),
           Text(
             hasTitle ? body : title, 
             style: TextStyle(
               fontWeight: hasTitle ? FontWeight.normal : (lines.length == 1 ? FontWeight.bold : FontWeight.normal),
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
                 child: Text("Kamroq o'qish", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
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
             Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 1.4, color: Colors.black)),
           if (hasTitle && body.isNotEmpty)
             const SizedBox(height: 4),
           
           Text(
             hasTitle ? body : title,
             style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87),
             maxLines: maxLines,
             overflow: TextOverflow.ellipsis,
           ),
           GestureDetector(
             onTap: () => setState(() => _isExpanded = true),
             child: const Padding(
               padding: EdgeInsets.only(top: 4),
               child: Text("Ko'proq o'qish", style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 13)),
             ),
           )
         ],
       );
    }
  }
}
