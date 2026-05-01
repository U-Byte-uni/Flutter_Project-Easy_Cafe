import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ai_service.dart';
import '../controllers/cafe_controller.dart';
import '../theme/app_theme.dart';

class ChatBotOverlay extends StatefulWidget {
  const ChatBotOverlay({super.key});

  @override
  State<ChatBotOverlay> createState() => _ChatBotOverlayState();
}

class _ChatBotOverlayState extends State<ChatBotOverlay> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final AIService _aiService = AIService();
  bool _isTyping = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("AI Coffee Assistant", style: TextStyle(fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final isUser = _messages[index]['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? AppTheme.primaryColor : AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(_messages[index]['message']!, style: const TextStyle(color: Colors.white)),
                  ),
                );
              },
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Ask about the menu...",
                      fillColor: AppTheme.cardColor,
                      filled: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send, color: AppTheme.primaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    
    final userText = _controller.text;
    final products = context.read<CafeController>().products;
    
    setState(() {
      _messages.add({'role': 'user', 'message': userText});
      _isTyping = true;
      _controller.clear();
    });

    try {
      final response = await _aiService.getChatResponse(userText, products);
      if (mounted) {
        setState(() {
          _messages.add({'role': 'ai', 'message': response});
          _isTyping = false;
        });
      }
    } catch (e) {
      debugPrint("Chat AI Error: $e");
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'ai', 
            'message': "Sorry, I'm having trouble connecting to my coffee sensors. Please try again!"
          });
          _isTyping = false;
        });
      }
    }
  }
}
