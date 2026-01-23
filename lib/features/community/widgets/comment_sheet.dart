import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart'; // For Haptics
import '../../../../core/theme/app_theme.dart';
import '../models/community_models.dart';
import '../services/community_service.dart';
import '../screens/user_profile_screen.dart';

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
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Comment> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;
  // State for Optimistic Updates
  // We need current user info (Avatar/Name) to make it look REAL
  String _currentUserName = "Men"; 
  String _currentUserAvatar = "";
  String _currentUserId = ""; // NEW
  
  // Variables needed for logic
  Comment? _replyingTo;
  Post? _currentPost;

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post; // Initial state
    _loadCurrentUser(); // Pre-fetch user for optimistic UI
    _refreshAll();
  }

  Future<void> _loadCurrentUser() async {
    final user = await CommunityService().getCurrentUser(); // We need to expose this via Community or Auth
    if (user != null && mounted) {
      setState(() {
        _currentUserName = user.fullName;
        _currentUserAvatar = user.imageUrl ?? "";
        _currentUserId = user.id.toString(); // NEW
      });
    }
  }

  Future<void> _refreshAll() async {
    if (_comments.isEmpty) setState(() => _isLoading = true);
    
    // 1. Load Comments FIRST (Priority)
    await _loadComments();
    
    if (mounted) setState(() => _isLoading = false);

    // 2. Load Post Details in Background (don't block UI)
    _loadPostDetails(); 
  }

  Future<void> _loadPostDetails() async {
    try {
      final updatedPost = await _service.getPost(widget.post.id);
      if (updatedPost != null && mounted) {
        setState(() => _currentPost = updatedPost);
      }
    } catch (e) {
      print("Error loading post details: $e");
    }
  }

  Future<void> _loadComments() async {
    try {
      final comments = await _service.getComments(widget.post.id);
      if (mounted) {
        setState(() {
          _comments = comments;
        });
      }
    } catch (e) {
      print("Error loading comments: $e");
    }
  }

  // ... (loadPostDetails and loadComments remain same)

  Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    // Pro UX: Haptic Feedback
    HapticFeedback.mediumImpact(); 

    setState(() => _isSending = true);
    
    // OPTIMISTIC UPDATE
    // Use REAL user details now
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final tempComment = Comment(
      id: "temp_$tempId",
      postId: widget.post.id,
      authorId: _currentUserId.isNotEmpty ? _currentUserId : "0", // NEW
      authorName: _currentUserName, 
      authorAvatar: _currentUserAvatar, 
      content: content,
      timeAgo: "Hozirgina",
      createdAt: DateTime.now(),
      likes: 0,
      isLiked: false,
      isLikedByAuthor: false,
      authorRole: "Talaba",
      replyToUserName: _replyingTo?.authorName,
      replyToContent: _replyingTo?.content,
      isMine: true, // Optimistically MINE
    );

    setState(() {
      _comments.add(tempComment);
      _commentController.clear();
      // Keep replyingTo for a moment? No, clear it.
    });

    // Scroll immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100, 
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    final replyId = _replyingTo?.id;
    setState(() => _replyingTo = null); // Clear reply state from UI

    try {
      // 1. Send to server and GET the real comment back
      final realComment = await _service.createComment(widget.post.id, content, replyToId: replyId);
      
      // 2. Replace temporary comment with real one
      if (mounted) {
        setState(() {
          final index = _comments.indexWhere((c) => c.id == "temp_$tempId");
          if (index != -1) {
            _comments[index] = realComment;
          } else {
             _comments.add(realComment);
          }
        });
        
        // 3. Update parent counter (using LOCAL count, not fetching)
        widget.onCommentCountChanged?.call(_comments.length);
      }
      
    } catch (e) {
      // Rollback on error
      if (mounted) {
        setState(() {
          _comments.removeWhere((c) => c.id == "temp_$tempId");
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Xatolik: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _toggleCommentLike(String commentId) async {
    final index = _comments.indexWhere((c) => c.id == commentId);
    if (index == -1) return;

    final oldComment = _comments[index];
    // Backend logic: if liked, count-1. if not, count+1.
    final bool newLiked = !oldComment.isLiked;
    final int newCount = newLiked ? oldComment.likes + 1 : oldComment.likes - 1;

    setState(() {
      _comments[index] = oldComment.copyWith(
        isLiked: newLiked,
        likes: newCount
      );
    });

    final success = await _service.likeComment(commentId);
    
    if (!success && mounted) {
      setState(() {
        _comments[index] = oldComment; // Rollback
      });
    }
  }

  Map<String, List<Comment>> _getRepliesMap() {
    final Map<String, List<Comment>> map = {};
    for (var c in _comments) {
      if (c.replyToCommentId != null && c.replyToCommentId != "0" && c.replyToCommentId != "null") {
         map.putIfAbsent(c.replyToCommentId!, () => []).add(c);
      }
    }
    // Sort replies: Oldest First (Chronological)
    for (var list in map.values) {
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    return map;
  }

  List<Comment> _getRoots() {
     return _comments.where((c) => c.replyToCommentId == null || c.replyToCommentId == "0" || c.replyToCommentId == "null").toList();
  }

  Widget _buildThreadRecursively(Comment comment, Map<String, List<Comment>> repliesMap, int depth) {
    final List<Comment>? directReplies = repliesMap[comment.id];
    final bool hasReplies = directReplies != null && directReplies.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCommentItem(comment, isReply: depth > 0),
        
        if (hasReplies)
          Padding(
            // Only indent the first level of replies. Deep replies stay flat.
            padding: EdgeInsets.only(left: depth == 0 ? 16.0 : 0.0), 
            child: IntrinsicHeight( 
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Connector Line (Only for Root's direct children)
                  if (depth == 0) 
                  Container(
                    width: 20,
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Colors.grey[300]!, width: 2),
                      )
                    ),
                  ),

                  // The Replies Stack
                  Expanded(
                    child: Column(
                      children: directReplies.map((reply) => 
                        _buildThreadRecursively(reply, repliesMap, depth + 1) 
                      ).toList(),
                    ),
                  )
                ],
              ),
            ),
          )
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final roots = _getRoots();
    final repliesMap = _getRepliesMap();

    return DraggableScrollableSheet(
      initialChildSize: 0.75, // Open at 75% height
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
              // 1. Header (Handle + Title)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!))
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2)
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Sharhlar (${_comments.length})", 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                    ),
                  ],
                ),
              ),

              // 2. Main Post (Pinned)
              _buildPostHeader(),

              const Divider(height: 1, thickness: 1),

              // 3. Comments List (Scrollable)
              Expanded(
                child: _isLoading && _comments.isEmpty
                  ? const Center(child: CircularProgressIndicator()) // Initial load
                  : RefreshIndicator(
                      onRefresh: _refreshAll,
                      color: AppTheme.primaryBlue,
                      child: _comments.isEmpty
                        ? SingleChildScrollView(child: _buildEmptyState()) // Wrap with ScrollView for pull-to-refresh on empty
                        : ListView.builder(
                            controller: scrollController, // Important for drag behavior
                            itemCount: roots.length,
                            padding: const EdgeInsets.only(bottom: 20),
                            itemBuilder: (context, index) => _buildThreadRecursively(roots[index], repliesMap, 0),
                          ),
                    ),
              ),

              // 3. Reply Preview
              if (_replyingTo != null) _buildReplyPreview(),

              // 4. Input Area (Fixed at bottom of sheet)
              _buildInputArea(),
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
                      Text(
                        "@${post.authorUsername}", 
                        style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w500, fontSize: 11)
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  post.content, 
                  maxLines: 3, 
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, height: 1.3)
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      post.isLiked ? Icons.favorite : Icons.favorite_border, 
                      size: 14, 
                      color: post.isLiked ? Colors.red : Colors.grey[400]
                    ),
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
          Text(
            "Hozircha sharhlar yo'q", 
            style: TextStyle(color: Colors.grey[500], fontSize: 14)
          ),
          Text(
            "Birinchi bo'lib fikr bildiring!", 
            style: TextStyle(color: Colors.grey[400], fontSize: 12)
          ),
        ],
      ),
    );
  }


  Widget _buildReplyPreview() {
    return Container(
      color: const Color(0xFFF5F7FA),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.reply, size: 20, color: AppTheme.primaryBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Javob: ${_replyingTo!.authorName}",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue, fontSize: 12),
                ),
                Text(
                  _replyingTo!.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _replyingTo = null),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          )
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 16, 
        right: 16, 
        top: 8, 
        bottom: MediaQuery.of(context).viewInsets.bottom + 16 // Keyboard padding
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, -2))
        ]
      ),
      child: Row(
        children: [
           CircleAvatar(
             backgroundColor: Colors.grey[200],
             radius: 18,
             child: const Icon(Icons.person, color: Colors.grey, size: 20),
           ),
           const SizedBox(width: 12),
           
           Expanded(
             child: Container(
               padding: const EdgeInsets.symmetric(horizontal: 16),
               decoration: BoxDecoration(
                 color: const Color(0xFFF5F5F5),
                 borderRadius: BorderRadius.circular(24),
               ),
               child: TextField(
                 controller: _commentController,
                 decoration: const InputDecoration(
                   hintText: "Fikringizni yozing...",
                   border: InputBorder.none,
                   contentPadding: EdgeInsets.symmetric(vertical: 10),
                   isDense: true,
                 ),
                 minLines: 1,
                 maxLines: 4,
               ),
             ),
           ),
           
           const SizedBox(width: 8),
           
           IconButton(
             onPressed: _isSending ? null : _sendComment,
             icon: _isSending 
               ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
               : const CircleAvatar(
                   backgroundColor: AppTheme.primaryBlue,
                   radius: 20,
                   child: Icon(Icons.send_rounded, color: Colors.white, size: 18),
                 ),
           )
        ],
      ),
    );
  }

  String _getShortName(String fullName) {
    // "RAHIMXONOV JAVOHIRXON ..." -> "Javohirxon"
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      // Return 2nd word (First Name assuming Surname First format)
      // Capitalize first letter, lower others for nicer look?
      // User input seems to be ALL CAPS. Let's fix that too eventually, but for now just take the word.
      return parts[1];
    }
    return parts.isNotEmpty ? parts[0] : "Talaba";
  }

  Widget _buildCommentItem(Comment comment, {bool isReply = false}) {
    // Only apply Swipe-to-Reply here. Nesting indentation is handled by list builder.
    return Dismissible(
      key: ValueKey("reply_${comment.id}"),
      direction: DismissDirection.endToStart, // Swipe Left to Reply
      confirmDismiss: (direction) async {
        HapticFeedback.lightImpact();
        setState(() {
          _replyingTo = comment;
        });
        return false; // Don't actually dismiss
      },
      background: Container(
        color: Colors.blue[50], // Reply Color
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.white, // comment.id == _replyingTo?.id ? Colors.blue[50] : Colors.white, // Highlight if replying
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
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
            const SizedBox(width: 10),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + Username Row (Blue)
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
                  
                  // Comment Content
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 4),
                    child: Text(
                      comment.content,
                      style: const TextStyle(fontSize: 14, height: 1.3),
                    ),
                  ),

                  // Footer: Time + Reply + Likes
                   Row(
                      children: [
                        Text(comment.timeAgo, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                             HapticFeedback.lightImpact();
                             setState(() => _replyingTo = comment);
                          },
                          child: const Text("Javob berish", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                        ),
                        const Spacer(),
                         GestureDetector(
                          onTap: () => _toggleCommentLike(comment.id),
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
      ),
    );
  }

  void _deleteComment(String commentId) async {
    // Optimistic Delete
    final deletedComment = _comments.firstWhere((c) => c.id == commentId);
    setState(() {
      _comments.removeWhere((c) => c.id == commentId);
    });
    widget.onCommentCountChanged?.call(_comments.length);

    final success = await _service.deleteComment(commentId);
    
    if (!success) {
      // Rollback
      setState(() {
         // This puts it at the end, sorting might be messed up but at least data is back
         // Ideally we should reload
        _comments.add(deletedComment);
      });
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("O'chirishda xatolik bo'ldi")),
        );
      }
    }
  }
}
