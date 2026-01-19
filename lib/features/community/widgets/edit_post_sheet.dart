import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../services/community_service.dart';

class EditPostSheet extends StatefulWidget {
  final String postId;
  final String initialContent;

  const EditPostSheet({
    super.key,
    required this.postId,
    required this.initialContent,
  });

  @override
  State<EditPostSheet> createState() => _EditPostSheetState();
}

class _EditPostSheetState extends State<EditPostSheet> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isLoading = false;
  bool _hasChanges = false;
  String? _originalTitle;
  String? _originalBody;

  @override
  void initState() {
    super.initState();
    _parseInitialContent();
    _titleController = TextEditingController(text: _originalTitle);
    _contentController = TextEditingController(text: _originalBody);

    _titleController.addListener(_checkForChanges);
    _contentController.addListener(_checkForChanges);
  }

  void _parseInitialContent() {
    // Logic: If content starts with **Title**, extract it.
    // Regex look for **Title** at start, followed by newlines.
    final RegExp titleRegex = RegExp(r'^\*\*(.*?)\*\*\n+(.*)', multiLine: true, dotAll: true);
    final match = titleRegex.firstMatch(widget.initialContent);

    if (match != null) {
      _originalTitle = match.group(1)?.trim() ?? "";
      _originalBody = match.group(2)?.trim() ?? "";
    } else {
      _originalTitle = "";
      _originalBody = widget.initialContent;
    }
  }

  void _checkForChanges() {
    final newTitle = _titleController.text.trim();
    final newBody = _contentController.text.trim();
    final hasChanges = newTitle != _originalTitle || newBody != _originalBody;
    
    if (_hasChanges != hasChanges) {
      setState(() => _hasChanges = hasChanges);
    }
  }

  Future<void> _handleSave() async {
    if (!_hasChanges) return;

    setState(() => _isLoading = true);
    final newTitle = _titleController.text.trim();
    final newBody = _contentController.text.trim();
    
    // Combine back: **Title**\n\nBody
    String finalContent = newBody;
    if (newTitle.isNotEmpty) {
      finalContent = "**$newTitle**\n\n$newBody";
    }

    try {
      final success = await CommunityService().editPost(widget.postId, finalContent);
      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Post muvaffaqiyatli o'zgartirildi ✅")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Xatolik: Post o'zgartirilmadi ❌")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Xatolik: $e")),
          );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Saqlanmagan o'zgarishlar"),
        content: const Text("Haqiqatan ham chiqib ketmoqchimisiz? O'zgarishlar yo'qoladi."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Yo'q", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Ha, chiqish", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // Use PopScope for Android Back button protection
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent, // Important for overlay effect
        body: Stack(
          children: [
            // Barrier (Dismiss on tap)
            GestureDetector(
              onTap: () async {
                 final shouldPop = await _onWillPop();
                 if (shouldPop && context.mounted) Navigator.pop(context);
              },
              child: Container(color: Colors.transparent),
            ),
            
            // Central Dialog Card
            Center(
              child: GestureDetector(
                onTap: () {}, // Prevent tap propagation to barrier
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.7,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
                  ),
                  child: Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () async {
                                final shouldPop = await _onWillPop();
                                if (shouldPop && context.mounted) Navigator.pop(context);
                              },
                              child: const Text("Bekor qilish", style: TextStyle(color: Colors.grey, fontSize: 16)),
                            ),
                            const Text("Postni tahrirlash", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            _isLoading 
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                              : TextButton(
                                  onPressed: _hasChanges ? _handleSave : null,
                                  child: Text("Saqlash", style: TextStyle(
                                    color: _hasChanges ? AppTheme.primaryBlue : Colors.grey, 
                                    fontSize: 16, 
                                    fontWeight: FontWeight.bold
                                  )),
                                ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      
                      // Content Fields
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title Field
                              TextField(
                                controller: _titleController,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                decoration: const InputDecoration(
                                  hintText: "Mavzu (ixtiyoriy)",
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.normal),
                                  contentPadding: EdgeInsets.zero,
                                ),
                                maxLines: 1,
                              ),
                              const SizedBox(height: 12),
                              // Body Field
                              TextField(
                                controller: _contentController,
                                style: const TextStyle(fontSize: 16, height: 1.5),
                                decoration: const InputDecoration(
                                  hintText: "Izoh...",
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(color: Colors.grey),
                                  contentPadding: EdgeInsets.zero,
                                ),
                                maxLines: null, // Infinite
                                minLines: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
