
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/community_models.dart';
import '../services/community_service.dart';
import '../widgets/post_card.dart';
import 'user_profile_screen.dart'; // ADDED
import 'dart:async';

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final CommunityService _service = CommunityService();
  final TextEditingController _commentController = TextEditingController();
  List<Comment> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;
  late Post _post;
  Timer? _pollingTimer;
  Comment? _replyingTo; // State for reply

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _refreshPost(); // Fetch fresh data immediately
    _loadComments();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _refreshPost();
    });
  }

  Future<void> _refreshPost() async {
    final updatedPost = await _service.getPost(_post.id);
    if (updatedPost != null && mounted) {
      setState(() {
        _post = updatedPost;
      });
    }
  }

  Future<void> _loadComments() async {
    try {
      final comments = await _service.getComments(widget.post.id);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

    Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);
    try {
      // If replying, we should ideally send parentId. Since API might not support it yet,
      // we can prepend "@username" or handle it if backend supports.
      // For now, let's assume we just send text.
      String finalContent = content;
      if (_replyingTo != null) {
        // Mock notification logic
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${_replyingTo!.authorName} ga javob xabari yuborildi 🔔")),
        );
      }

      await _service.createComment(widget.post.id, finalContent);
      _commentController.clear();
      setState(() => _replyingTo = null); // Clear reply state
      _loadComments(); 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Xatolik: $e")),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, 
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.pop(context, _post);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context, _post), 
          ),
          title: const Text("Muhokama", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
        body: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadComments,
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 20),
                  children: [
                    // Main Post
                    PostCard(
                      post: _post, 
                      isDetail: true,
                      onDelete: () {
                        Navigator.pop(context, 'deleted');
                      },
                      onLikeChanged: (isLiked, count) {
                         setState(() {
                           _post = _post.copyWith(isLiked: isLiked, likes: count);
                         });
                      },
                    onRepostChanged: (isReposted, count) {
                       setState(() {
                         _post = _post.copyWith(isRepostedByMe: isReposted, repostsCount: count);
                       });
                    },
                  ),  
                    
                    const Divider(thickness: 1, height: 1),
                    
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Muhokamalar", 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey[800])
                      ),
                    ),
  
                    // Comments List
                     if (_isLoading)
                        const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                     else if (_comments.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text("Hozircha sharhlar yo'q", style: TextStyle(color: Colors.grey[500])),
                          ),
                        )
                     else
                        ..._comments.map((comment) => _buildCommentItem(comment)),
                  ],
                ),
              ),
            ),
  
            // Reply Banner
            if (_replyingTo != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey[100],
                child: Row(
                  children: [
                    Icon(Icons.reply, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "${_replyingTo!.authorName} ga javob yozilmoqda...",
                        style: TextStyle(color: Colors.grey[800], fontSize: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => setState(() => _replyingTo = null),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    )
                  ],
                ),
              ),

            // Input Area
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, -2))
                ]
              ),
              child: SafeArea( 
                child: Row(
                  children: [
                     // User Avatar (Placeholder)
                     CircleAvatar(
                       backgroundColor: Colors.grey[200],
                       radius: 18,
                       child: const Icon(Icons.person, color: Colors.grey, size: 20),
                     ),
                     const SizedBox(width: 12),
                     
                     // Input Field
                     Expanded(
                       child: Container(
                         padding: const EdgeInsets.symmetric(horizontal: 16),
                         decoration: BoxDecoration(
                           color: Colors.grey[100],
                           borderRadius: BorderRadius.circular(24),
                         ),
                         child: TextField(
                           controller: _commentController,
                           decoration: InputDecoration(
                             hintText: _replyingTo != null ? "Javob yozing..." : "Fikringizni yozing...",
                             border: InputBorder.none,
                             contentPadding: const EdgeInsets.symmetric(vertical: 10),
                           ),
                           minLines: 1,
                           maxLines: 4,
                         ),
                       ),
                     ),
                     
                     const SizedBox(width: 8),
                     
                     // Send Button
                     IconButton(
                       onPressed: _isSending ? null : _sendComment,
                       icon: _isSending 
                         ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                         : const CircleAvatar(
                             backgroundColor: AppTheme.primaryBlue,
                             radius: 20,
                             child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                           ),
                     )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCommentItem(Comment comment) {
    // Check if author liked (Assuming verifying logic: if post author liked it)
    // Note: Since we are in mock mode, relying on service 'isLikedByAuthor'
    
    return Dismissible(
      key: Key("reply_${comment.id}"),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        setState(() {
          _replyingTo = comment;
        });
        // Focus input
        Future.delayed(const Duration(milliseconds: 100), () {
           // We might need a FocusNode to focus programmatically, 
           // but for now user sees banner and can tap input.
        });
        return false; // Don't actually dismiss
      },
      background: Container(
        color: Colors.grey[100],
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text("Javob yozish", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Icon(Icons.reply, color: Colors.grey[600]),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey[100]!))
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(
                  authorName: comment.authorName,
                  authorUsername: "@${comment.authorName.toLowerCase().replaceAll(' ', '')}",
                  authorAvatar: comment.authorAvatar,
                  authorRole: comment.authorRole ?? "Talaba",
                )));
              },
              child: CircleAvatar(
                backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                backgroundImage: comment.authorAvatar.isNotEmpty ? NetworkImage(comment.authorAvatar) : null,
                radius: 18,
                child: comment.authorAvatar.isEmpty 
                  ? Text(comment.authorName[0], style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue))
                  : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          comment.authorName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(comment.timeAgo, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(comment.content, style: const TextStyle(fontSize: 14, height: 1.4)),
                  
                  const SizedBox(height: 8),
                  
                  // Footer: Reply, Like, Author Badge
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                           setState(() => _replyingTo = comment);
                        },
                        child: Text("Javob yozish", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                      ),
                      const SizedBox(width: 16),
                      
                      // Like Logic (Mock visual toggle)
                      InkWell(
                        onTap: () {
                          // TODO: Call API
                        },
                        child: Row(
                          children: [
                            Icon(
                              comment.isLiked ? Icons.favorite : Icons.favorite_border,
                              size: 14,
                              color: comment.isLiked ? Colors.red : Colors.grey[500],
                            ),
                            if (comment.likes > 0)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Text("${comment.likes}", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Author Liked Badge
                      if (comment.isLikedByAuthor)
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                           decoration: BoxDecoration(
                             color: Colors.red.withOpacity(0.1),
                             borderRadius: BorderRadius.circular(10),
                             border: Border.all(color: Colors.red.withOpacity(0.2))
                           ),
                           child: Row(
                             children: [
                               CircleAvatar(
                                 radius: 6,
                                 backgroundImage: widget.post.authorAvatar.isNotEmpty ? NetworkImage(widget.post.authorAvatar) : null,
                                 child: widget.post.authorAvatar.isEmpty ? Text(widget.post.authorName[0], style: const TextStyle(fontSize: 6)) : null,
                               ),
                               const SizedBox(width: 4),
                               const Icon(Icons.favorite, size: 8, color: Colors.red),
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
      ),
    );
  }
}
