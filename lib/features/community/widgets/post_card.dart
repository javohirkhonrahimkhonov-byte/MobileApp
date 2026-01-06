import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/community_models.dart';
import '../screens/post_detail_screen.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final bool isDetail;

  const PostCard({super.key, required this.post, this.isDetail = false});

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration( // ... style 
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
                tag: "avatar_${post.id}",
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                  child: Text(
                    post.authorName.isNotEmpty ? post.authorName[0] : "?",
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
                            post.authorName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (post.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: Colors.blue, size: 16),
                        ],
                        if (post.isTyutor) ...[
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
                      "${post.authorRole} • ${post.timeAgo}",
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (post.usefulScore > 10) 
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                   decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
                   child: Row(
                     children: [
                       const Icon(Icons.show_chart, size: 14, color: Colors.green),
                       const SizedBox(width: 4),
                       Text("Top so'rov", style: TextStyle(fontSize: 10, color: Colors.green[700], fontWeight: FontWeight.bold)),
                     ],
                   ),
                 )
              else 
                 const Icon(Icons.more_horiz, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          
          // Content
          Text(post.content, style: const TextStyle(fontSize: 15, height: 1.4)),
          
          const SizedBox(height: 12),
          
          // Tags
          if (post.tags.isNotEmpty)
            Wrap(
              spacing: 8,
              children: post.tags.map((tag) => Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAction(Icons.favorite_border_rounded, "${post.likes}"),
              _buildAction(Icons.chat_bubble_outline_rounded, "${post.commentsCount}"),
              _buildAction(Icons.share_rounded, "Ulashish"),
            ],
          )
        ],
      ),
    );

    if (isDetail) return content;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(post: post),
          ),
        );
      },
      child: content,
    );
  }

  Widget _buildAction(IconData icon, String label) {
    return InkWell(
      onTap: () {}, // TODO: Implement interaction
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
