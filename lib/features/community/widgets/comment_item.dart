import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/community_models.dart';
import '../screens/user_profile_screen.dart';

class CommentItem extends StatelessWidget {
  final Comment comment;
  final Function(String commentId) onLike;
  final Function(Comment comment)? onReply;
  final Function(String commentId)? onDelete;
  final bool isReply;
  final bool isParent; // For showing centered/highlighted in thread view

  const CommentItem({
    super.key,
    required this.comment,
    required this.onLike,
    this.onReply,
    this.onDelete,
    this.isReply = false,
    this.isParent = false,
  });

  @override
  Widget build(BuildContext context) {
    if (comment.isMine) {
      return Dismissible(
        key: Key(comment.id),
        direction: DismissDirection.startToEnd,
        background: Container(
          color: Colors.red[50],
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Icon(Icons.delete_outline, color: Colors.red),
        ),
        confirmDismiss: (direction) async {
          if (onDelete == null) return false;
          return await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("O'chirish"),
              content: const Text("Ushbu sharhni o'chirmoqchimisiz?"),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Yo'q")),
                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Ha", style: TextStyle(color: Colors.red))),
              ],
            ),
          );
        },
        onDismissed: (direction) {
          onDelete?.call(comment.id);
        },
        child: _buildContent(context),
      );
    } 
    
    // Swipe to Reply for others
    return Dismissible(
      key: ValueKey("reply_${comment.id}"), // Unique key different from delete key
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        if (onReply != null) {
          onReply!.call(comment);
        }
        return false;
      },
      background: Container(
        color: Colors.blue[50],
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text("Javob berish", style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Icon(Icons.reply, color: AppTheme.primaryBlue),
          ],
        ),
      ),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: isParent ? Colors.grey[50] : Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(
                  authorName: comment.authorName,
                  authorId: comment.authorId,
                  authorUsername: comment.authorUsername,
                  authorAvatar: comment.authorAvatar,
                  authorRole: comment.authorRole ?? "Talaba",
               )));
            },
            child: CircleAvatar(
              backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
              backgroundImage: comment.authorAvatar.isNotEmpty ? NetworkImage(comment.authorAvatar) : null,
              radius: 18,
              child: comment.authorAvatar.isEmpty 
                ? Text(comment.authorName.isNotEmpty ? comment.authorName[0] : "?", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue))
                : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black, fontFamily: 'Inter'),
                    children: [
                      TextSpan(
                        text: comment.authorName, 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)
                      ),
                      const WidgetSpan(child: SizedBox(width: 4)),
                      if (comment.authorUsername.isNotEmpty)
                        TextSpan(
                          text: "@${comment.authorUsername}",
                          style: const TextStyle(color: AppTheme.primaryBlue, height:1.2, fontSize: 13, fontWeight: FontWeight.w500)
                        ),
                    ]
                  )
                ),
                
                 if (comment.replyToUserName != null && !isParent) // Hide reply context if it is the parent being viewed
                   Container(
                     margin: const EdgeInsets.only(top: 4, bottom: 4),
                     padding: const EdgeInsets.only(left: 8),
                     decoration: const BoxDecoration(
                       border: Border(left: BorderSide(color: AppTheme.primaryBlue, width: 2))
                     ),
                     child: Text(
                       "Javob: ${comment.replyToUserName}", 
                       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.primaryBlue)
                     ),
                   ),

                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 4),
                  child: Text(
                    comment.content,
                    style: const TextStyle(fontSize: 14, height: 1.3),
                  ),
                ),

                Row(
                  children: [
                    Text(comment.timeAgo, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    if (!isParent) ...[
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => onReply?.call(comment),
                        child: const Text("Javob berish", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                      ),
                    ],
                    const Spacer(),
                    GestureDetector(
                      onTap: () => onLike(comment.id),
                      child: Row(
                        children: [
                           Icon(
                             comment.isLiked ? Icons.favorite : Icons.favorite_outline, 
                             size: 14, 
                             color: comment.isLiked ? Colors.red : Colors.grey 
                           ),
                           if (comment.likes > 0) ...[
                             const SizedBox(width: 4),
                             Text("${comment.likes}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                           ]
                        ],
                      ),
                    )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
