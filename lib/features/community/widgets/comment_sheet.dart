import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart'; // For Haptics
import '../../../../core/theme/app_theme.dart';
import '../models/community_models.dart';
import '../services/community_service.dart';
import 'comment_item.dart';
import 'comment_input.dart';
import 'reply_thread_sheet.dart';

class CommentSheet extends StatefulWidget {
  final Post post;
  final Function(int newCount)? onCommentCountChanged;

  const CommentSheet({
    super.key, 
    required this.post,
    this.onCommentCountChanged
  });

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  final CommunityService _service = CommunityService();
  final ScrollController _scrollController = ScrollController();
  
  List<Comment> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;
  
  // State for Optimistic Updates
  String _currentUserName = "Men"; 
  String _currentUserAvatar = "";
  String _currentUserId = "";

  Comment? _replyingTo;
  Post? _currentPost;

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post; 
    _loadCurrentUser(); 
    _refreshAll();
  }

  Future<void> _loadCurrentUser() async {
    final user = await CommunityService().getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _currentUserName = user.fullName;
        _currentUserAvatar = user.imageUrl ?? "";
        _currentUserId = user.id.toString();
      });
    }
  }

  Future<void> _refreshAll() async {
    if (_comments.isEmpty) setState(() => _isLoading = true);
    await _loadComments();
    if (mounted) setState(() => _isLoading = false);
    _loadPostDetails(); 
  }

  Future<void> _loadPostDetails() async {
    try {
      final updatedPost = await _service.getPost(widget.post.id);
      if (updatedPost != null && mounted) setState(() => _currentPost = updatedPost);
    } catch (e) { print("Error loading post: $e"); }
  }

  Future<void> _loadComments() async {
    try {
      final comments = await _service.getComments(widget.post.id);
      if (mounted) setState(() => _comments = comments);
    } catch (e) { print("Error loading comments: $e"); }
  }

  Future<void> _sendComment(String content) async {
    HapticFeedback.mediumImpact(); 
    setState(() => _isSending = true);
    
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final tempComment = Comment(
      id: "temp_$tempId",
      postId: widget.post.id,
      authorId: _currentUserId.isNotEmpty ? _currentUserId : "0", 
      authorName: _currentUserName, 
      authorAvatar: _currentUserAvatar, 
      content: content,
      timeAgo: "Hozirgina",
      createdAt: DateTime.now(),
      likes: 0,
      isLiked: false,
      isLikedByAuthor: false,
      authorRole: "Talaba",
      // If we are replying to someone in Main Sheet, we usually just reply to thread or create new thread?
      // For now, let's keep it simple: Replying here targets the Parent (Post).
      // Unless _replyingTo is set (which is only for swipes).
      replyToCommentId: _replyingTo?.id, 
      replyToUserName: _replyingTo?.authorName, 
      isMine: true,
    );

    setState(() {
      _comments.add(tempComment);
      _replyingTo = null; // Clear reply context
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100, 
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      final realComment = await _service.createComment(
        widget.post.id, 
        content, 
        replyToId: tempComment.replyToCommentId
      );
      
      if (mounted) {
        setState(() {
          final index = _comments.indexWhere((c) => c.id == "temp_$tempId");
          if (index != -1) _comments[index] = realComment;
          else _comments.add(realComment);
        });
        widget.onCommentCountChanged?.call(_comments.length);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _comments.removeWhere((c) => c.id == "temp_$tempId"));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Xatolik: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _toggleCommentLike(String commentId) async {
    final index = _comments.indexWhere((c) => c.id == commentId);
    if (index == -1) return;

    final oldComment = _comments[index];
    setState(() {
      _comments[index] = oldComment.copyWith(
        isLiked: !oldComment.isLiked,
        likes: !oldComment.isLiked ? oldComment.likes + 1 : oldComment.likes - 1
      );
    });

    final success = await _service.likeComment(commentId);
    if (!success && mounted) setState(() => _comments[index] = oldComment);
  }

  void _deleteComment(String commentId) async {
    final deletedComment = _comments.firstWhere((c) => c.id == commentId);
    setState(() => _comments.removeWhere((c) => c.id == commentId));
    widget.onCommentCountChanged?.call(_comments.length);

    final success = await _service.deleteComment(commentId);
    if (!success && mounted) {
      setState(() => _comments.add(deletedComment)); // Restore
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("O'chirishda xatolik bo'ldi")));
    }
  }

  // --- Nesting Logic Helpers ---
  Map<String, List<Comment>> _getRepliesMap() {
    final Map<String, List<Comment>> map = {};
    for (var c in _comments) {
      if (c.replyToCommentId != null && c.replyToCommentId != "0" && c.replyToCommentId != "null") {
         map.putIfAbsent(c.replyToCommentId!, () => []).add(c);
      }
    }
    // Sort Oldest -> Newest
    for (var list in map.values) list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return map;
  }

  List<Comment> _getRoots() => _comments.where((c) => c.replyToCommentId == null || c.replyToCommentId == "0" || c.replyToCommentId == "null").toList();

  @override
  Widget build(BuildContext context) {
    final roots = _getRoots();
    final repliesMap = _getRepliesMap();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!))
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Sharhlar (${_comments.length})", 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                    ),
                  ],
                ),
              ),

              _buildPostHeader(),
              const Divider(height: 1, thickness: 1),

              // Comments List
              Expanded(
                child: _isLoading && _comments.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _refreshAll,
                      color: AppTheme.primaryBlue,
                      child: _comments.isEmpty
                        ? SingleChildScrollView(child: _buildEmptyState())
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: roots.length,
                            padding: const EdgeInsets.only(bottom: 20),
                            itemBuilder: (context, index) {
                              final root = roots[index];
                              final replies = repliesMap[root.id] ?? [];
                              
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CommentItem(
                                    comment: root,
                                    onLike: _toggleCommentLike,
                                    onReply: (c) => setState(() => _replyingTo = c),
                                    onDelete: _deleteComment,
                                  ),
                                  
                                  // "View replies" Button Logic (YouTube Style)
                                  if (replies.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 60, bottom: 8),
                                      child: GestureDetector(
                                        onTap: () async {
                                          HapticFeedback.lightImpact();
                                          // Navigate to Reply Thread
                                          // We pass all comments to thread, but only those belonging to this root will be shown initially.
                                          // Currently custom ReplyThreadSheet takes `initialReplies`.
                                          final updatedReplies = await Navigator.push(
                                            context, 
                                            MaterialPageRoute(builder: (_) => ReplyThreadSheet(
                                              parentComment: root,
                                              initialReplies: replies,
                                              onReplyCountChanged: (count) {
                                                 // Optional: Refresh count locally if needed
                                              },
                                            ))
                                          );
                                          
                                          // When coming back, we might receive updated list of replies. 
                                          // We need to merge them back into _comments.
                                          if (updatedReplies is List<Comment>) {
                                            bool changed = false;
                                            setState(() {
                                              for (var r in updatedReplies) {
                                                final idx = _comments.indexWhere((c) => c.id == r.id);
                                                if (idx == -1) {
                                                   _comments.add(r); // Add new
                                                   changed = true;
                                                } else {
                                                   if (_comments[idx].likes != r.likes || _comments[idx].isLiked != r.isLiked) {
                                                      _comments[idx] = r; // Update existing
                                                      changed = true;
                                                   }
                                                }
                                              }
                                              // Loop to find deleted ones?
                                              // Simple way: _loadComments(). Optimistic merging is complex if deletes happened.
                                              // Let's just create a Set of IDs from updatedReplies and remove those from _comments that are in this thread but not in update?
                                              // No, updatedReplies only contains REPLIES to this thread.
                                              // So we should remove all replies to this thread from _comments, then add all from updatedReplies.
                                            });
                                            // Ideally we should reload to get deletions correctly synced if logic is complex.
                                            _loadComments(); 
                                          } else {
                                             _loadComments();
                                          }
                                        },
                                        child: Text(
                                          "${replies.length} ta javobni ko'rish",
                                          style: const TextStyle(
                                            color: AppTheme.primaryBlue, 
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12
                                          ),
                                        ),
                                      ),
                                    )
                                ],
                              );
                            },
                          ),
                    ),
              ),

              CommentInput(
                onSend: _sendComment,
                isSending: _isSending,
                replyToName: _replyingTo?.authorName,
                onCancelReply: () => setState(() => _replyingTo = null),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildPostHeader() {
    final post = _currentPost ?? widget.post;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border(bottom: BorderSide(color: Colors.grey[200]!))
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: post.authorAvatar.isNotEmpty ? NetworkImage(post.authorAvatar) : null,
            child: post.authorAvatar.isEmpty ? Text(post.authorName[0]) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    if (post.authorUsername.isNotEmpty)
                      Text("@${post.authorUsername}", style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w500, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(post.content, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, height: 1.3)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(post.isLiked ? Icons.favorite : Icons.favorite_border, size: 14, color: post.isLiked ? Colors.red : Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text("${post.likes}", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(width: 12),
                    Icon(Icons.remove_red_eye, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text("Ko'rildi", style: TextStyle(fontSize: 12, color: Colors.grey[600])), 
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
     return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("Hozircha sharhlar yo'q", style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          Text("Birinchi bo'lib fikr bildiring!", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ],
      ),
    );
  }
}
