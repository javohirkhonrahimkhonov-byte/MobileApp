
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/data_service.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DataService _dataService = DataService();
  
  final List<Map<String, String>> _messages = [
    {"role": "assistant", "content": "Assalomu alaykum! Men TalabaHamkor AI yordamchisiman. Sizga qanday yordam bera olaman?"}
  ];
  
  bool _isTyping = false;

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    _controller.clear();
    setState(() {
      _messages.add({"role": "user", "content": text});
      _isTyping = true;
    });
    _scrollToBottom();
    
    // Call API
    final response = await _dataService.sendAiMessage(text);
    
    if (mounted) {
      setState(() {
        _isTyping = false;
        if (response != null) {
          _messages.add({"role": "assistant", "content": response});
        } else {
           _messages.add({"role": "assistant", "content": "⚠️ Kechirasiz, xatolik yuz berdi. Iltimos qayta urinib ko'ring."});
        }
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent, 
          duration: const Duration(milliseconds: 300), 
          curve: Curves.easeOut
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text("AI Chat", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                   return _buildTypingIndicator();
                }
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return _buildMessageBubble(msg['content']!, isUser);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primaryBlue : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
          ),
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
          ]
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 15,
            height: 1.4
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
       alignment: Alignment.centerLeft,
       child: Container(
         margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
         decoration: BoxDecoration(
           color: Colors.white,
           borderRadius: BorderRadius.circular(16),
         ),
         child: Row(
           mainAxisSize: MainAxisSize.min,
           children: [
             SizedBox(
               width: 14, height: 14, 
               child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBlue.withOpacity(0.6))
             ),
             const SizedBox(width: 8),
             const Text("Yozmoqda...", style: TextStyle(color: Colors.grey, fontSize: 12)),
           ],
         ),
       ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: "Xabar yozing...",
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: AppTheme.backgroundWhite,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
