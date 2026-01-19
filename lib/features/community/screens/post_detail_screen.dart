
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/community_models.dart';
import '../services/community_service.dart';
import '../widgets/post_card.dart';

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

  @override
  void initState() {
    super.initState();
    _loadComments();
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
      await _service.createComment(widget.post.id, content);
      _commentController.clear();
      _loadComments(); // Refresh list
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
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
                  PostCard(post: widget.post, isDetail: true),
                  
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
            child: SafeArea( // For iPhone bottom bar
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
                         decoration: const InputDecoration(
                           hintText: "Fikringizni yozing...",
                           border: InputBorder.none,
                           contentPadding: EdgeInsets.symmetric(vertical: 10),
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
    );
  }

  Widget _buildCommentItem(Comment comment) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!))
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey[300],
            radius: 18,
            child: Text(comment.authorName[0], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(comment.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(comment.timeAgo, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.content, style: const TextStyle(fontSize: 14, height: 1.4)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
