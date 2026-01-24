import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/community_models.dart';
import '../services/chat_service.dart';
import 'chat_detail_screen.dart';
import '../widgets/user_search_delegate.dart'; // NEW

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _service = ChatService(); // CHANGED

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Xabarlar", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<List<Chat>>(
        future: _service.getChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final chats = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: chats.length,
            separatorBuilder: (ctx, i) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final chat = chats[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatDetailScreen(chat: chat),
                    ),
                  );
                },
                leading: Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                      child: Text(
                        chat.partnerName[0],
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                      ),
                    ),
                    if (chat.isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            border: Border.all(color: Colors.white, width: 2),
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                  ],
                ),
                title: Text(
                  chat.formattedName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  chat.isLastMessageMine ? "Siz: ${chat.lastMessage}" : chat.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: (chat.unreadCount > 0 && !chat.isLastMessageMine) ? Colors.black87 : Colors.grey,
                    fontWeight: (chat.unreadCount > 0 && !chat.isLastMessageMine) ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      chat.timeAgo,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    if (chat.unreadCount > 0 && !chat.isLastMessageMine) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          "${chat.unreadCount}",
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      )
                    ]
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showSearch(
            context: context,
            delegate: UserSearchDelegate(
              onUserSelected: (student) async {
                // Show loading handled by async gap or we can show dialog
                final chat = await _service.startChat(student.id.toString());
                if (chat != null && mounted) {
                  // In delegate we did: `if (onUserSelected != null) { onUserSelected!(); return; }`
                  // We didn't close it there!
                  // Let's modify delegate to close itself OR we close it here.
                  // showSearch usage:
                  // The callback executes inside the `buildResults` or `buildSuggestions` context of SearchDelegate?
                  // No, `onTap` executes.
                  // If we want to replace the Search Screen with Chat Screen, we should `Navigator.pop` (close search) then `push`.
                  // But `context` in callback might be SearchDelegate's context?
                  // Actually, `onUserSelected` is called with `student`.
                  // Inside delegate: `onUserSelected!(student);`
                  // If we want to close search, we should do it here if possible, but we don't have search context easily.
                  // BETTER: delegate handles closing if `onUserSelected` returns? 
                  // OR `onUserSelected` logic:
                  // 1. `Navigator.pop(context)` (closes search? No, context is ChatListScreen context due to closure?)
                  // No, the closure is defined in ChatListScreen, so `context` refers to ChatListScreen context.
                  // But to close search, we need to pop the Top Route.
                  // So `Navigator.of(context).pop()` might work if the Search is on top.
                  // BUT `showSearch` pushes a route.
                  
                  // Let's rely on `Navigator.pop(context)` inside the callback? 
                  // Wait, context in `onUserSelected`? No, we use `context` from `build`.
                  // `Navigator.of(context).pop()` (pops search) -> `Navigator.push`...
                  
                  // Actually, safer pattern:
                  // In Delegate:
                  // `onUserSelected!(student); close(context, null);`
                  // Let's Check Delegate again.
                }
              }
            ),
          );
        },
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.add_comment_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mark_chat_unread_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "Xabarlar yo'q",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          const Text(
            "Do'stlaringizga birinchi bo'lib yozing!",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
