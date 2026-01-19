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
  late TextEditingController _controller;
  bool _isLoading = false;
  bool _hasChanges = false;
  final CommunityService _communityService = CommunityService();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
    _controller.addListener(_checkChanges);
  }

  void _checkChanges() {
    final hasChanges = _controller.text.trim() != widget.initialContent.trim();
    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_hasChanges) return;

    setState(() => _isLoading = true);
    // Unfocus keyboard
    FocusScope.of(context).unfocus();

    final success = await _communityService.editPost(widget.postId, _controller.text.trim());

    if (mounted) {
      if (success) {
        Navigator.pop(context, true); // Return TRUE to signal success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Post muvaffaqiyatli yangilandi! ✅")),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Xatolik: Postni saqlab bo'lmadi ❌"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Chiqib ketish"),
        content: const Text("Saqlanmagan o'zgarishlar bor. Haqiqatan ham chiqib ketmoqchimisiz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Yo'q, qaytish"),
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: TextButton(
          onPressed: () async {
            if (await _onWillPop()) {
              Navigator.pop(context);
            }
          },
          child: const Text(
            "Bekor",
            style: TextStyle(fontSize: 16, color: Colors.red),
          ),
        ),
        leadingWidth: 80,
        title: const Text(
          "Postni tahrirlash",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: (_hasChanges && !_isLoading) ? _handleSave : null,
              child: _isLoading 
                ? const SizedBox(
                    height: 16, 
                    width: 16, 
                    child: CircularProgressIndicator(strokeWidth: 2)
                  )
                : Text(
                    "Saqlash",
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold,
                      color: (_hasChanges && !_isLoading) ? AppTheme.primaryBlue : Colors.grey
                    ),
                  ),
            ),
          )
        ],
      ),
      body: PopScope(
        canPop: !_hasChanges,
        onPopInvoked: (didPop) async {
          if (didPop) return;
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.pop(context);
          }
        },
        child: Column(
          children: [
            const Divider(height: 1),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(fontSize: 18, height: 1.5),
                  decoration: const InputDecoration(
                    hintText: "Nimalarni o'zgartirmoqchisiz...",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
