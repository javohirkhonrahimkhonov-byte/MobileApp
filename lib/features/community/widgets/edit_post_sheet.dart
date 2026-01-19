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
            child: const Text("O'zgarishlarga qaytish"),
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
    // Determine bottom padding for keyboard
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Postni tahrirlash",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () async {
                    if (await _onWillPop()) {
                       Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
            const Divider(),
            
            // Input Area
            Flexible(
              child: TextField(
                controller: _controller,
                maxLines: null,
                minLines: 5,
                autofocus: true,
                style: const TextStyle(fontSize: 16, height: 1.5),
                decoration: InputDecoration(
                  hintText: "Fikringizni yozing...",
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  fillColor: Colors.grey[50],
                  filled: true,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5)
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Save Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: (_hasChanges && !_isLoading) ? _handleSave : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  disabledForegroundColor: Colors.grey[500],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading 
                  ? const SizedBox(
                      height: 24, 
                      width: 24, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                  : const Text("Saqlash", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
