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
    // 1. Try Markdown Parsing
    final RegExp titleRegex = RegExp(r'^\*\*(.*?)\*\*\n+(.*)', multiLine: true, dotAll: true);
    final match = titleRegex.firstMatch(widget.initialContent);

    if (match != null) {
      _originalTitle = match.group(1)?.trim() ?? "";
      _originalBody = match.group(2)?.trim() ?? "";
    } else {
      // 2. Fallback: Split by newline if multiple lines
      final lines = widget.initialContent.split('\n');
      if (lines.length > 1) {
        _originalTitle = lines.first.trim();
        _originalBody = lines.sublist(1).join('\n').trim();
      } else {
        _originalTitle = "";
        _originalBody = widget.initialContent;
      }
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
    
    // Validate
    if (_contentController.text.trim().isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Iltimos, matn yozing!")));
       return;
    }

    setState(() => _isLoading = true);
    final newTitle = _titleController.text.trim();
    final newBody = _contentController.text.trim();
    
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
            const SnackBar(content: Text("Post muvaffaqiyatli saqlandi ✅")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Xatolik: Post saqlanmadi ❌")),
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
        content: const Text("Chiqib ketsangiz o'zgarishlaringiz yo'qoladi."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Qolish", style: TextStyle(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Chiqish", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // Mimic CreatePostScreen layout but as a Sheet
    // We use a specific height (e.g. 90%) to show the app behind
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) Navigator.pop(context);
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9, // 90% Height
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () async {
                       final shouldPop = await _onWillPop();
                       if (shouldPop && context.mounted) Navigator.pop(context);
                    },
                  ),
                  const Text("Postni Tahrirlash", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 48), // Spacer to balance Close button
                ],
              ),
            ),
            const Divider(height: 1),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Title
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: "Sarlavha (Ixtiyoriy)",
                        border: InputBorder.none,
                        hintStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    // Body
                    Expanded(
                      child: TextField(
                        controller: _contentController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          hintText: "Bu yerga yozing...",
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Save Button
            SafeArea(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                ),
                child: SizedBox(
                   height: 50,
                   child: ElevatedButton(
                    onPressed: (_hasChanges && !_isLoading) ? _handleSave : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("SAQLASH", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
