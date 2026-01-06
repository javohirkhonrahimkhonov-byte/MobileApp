import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/community_models.dart';
import '../screens/post_detail_screen.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final bool isDetail;

  const PostCard({super.key, required this.post, this.isDetail = false});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool _isLiked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _likeCount = widget.post.likes;
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
    // TODO: Call service to update backend
  }

  void _sharePost() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Havola nusxalandi! (Mock)")),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Hero(
                tag: "avatar_${widget.post.id}",
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                  child: Text(
                    widget.post.authorName.isNotEmpty ? widget.post.authorName[0] : "?",
                    style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                  ),
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.post.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: Colors.blue, size: 16),
                        ],
                        if (widget.post.isTyutor) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(4)),
                            child: const Text("Tyutor", style: TextStyle(fontSize: 10, color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                          )
                        ]
                      ],
                    ),
                    Text(
                      "${widget.post.authorRole} • ${widget.post.timeAgo}",
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (widget.post.usefulScore > 10) 
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                   decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
                   child: Row(
                     children: [
                       const Icon(Icons.show_chart, size: 14, color: Colors.green),
                       const SizedBox(width: 4),
                       Text("Top", style: TextStyle(fontSize: 10, color: Colors.green[700], fontWeight: FontWeight.bold)),
                     ],
                   ),
                 )
              else 
                 const Icon(Icons.more_horiz, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          
          // Content
          Text(widget.post.content, style: const TextStyle(fontSize: 15, height: 1.4)),
          
          const SizedBox(height: 12),
          
          // Tags
          if (widget.post.tags.isNotEmpty)
            Wrap(
              spacing: 8,
              children: widget.post.tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(tag, style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 12)),
              )).toList(),
            ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Row(
                 children: [
                    _buildInteractiveAction(
                      icon: _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: _isLiked ? Colors.red : Colors.grey[600]!,
                      label: "$_likeCount",
                      onTap: _toggleLike,
                    ),
                    const SizedBox(width: 16),
                    _buildInteractiveAction(
                      icon: Icons.chat_bubble_outline_rounded,
                      color: Colors.grey[600]!,
                      label: "${widget.post.commentsCount}",
                      onTap: () {
                         if (!widget.isDetail) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(post: widget.post)));
                         }
                      },
                    ),
                    const SizedBox(width: 16),
                    _buildInteractiveAction(
                      icon: Icons.share_rounded,
                      color: Colors.grey[600]!,
                      label: "Ulashish",
                      onTap: _sharePost,
                    ),
                 ],
               ),
               // View Count
               Row(
                 children: [
                   Icon(Icons.remove_red_eye_outlined, size: 16, color: Colors.grey[400]),
                   const SizedBox(width: 4),
                   Text("${widget.post.views > 0 ? widget.post.views : 100+widget.post.likes*5}", style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                 ],
               )
            ],
          )
        ],
      ),
    );

    if (widget.isDetail) return content;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(post: widget.post),
          ),
        );
      },
      child: content,
    );
  }

  Widget _buildInteractiveAction({
    required IconData icon, 
    required Color color, 
    required String label, 
    required VoidCallback onTap
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
