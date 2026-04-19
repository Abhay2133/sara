import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sara/services/gemma_service.dart';
import 'dart:ui';

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

final messagesProvider = StateProvider<List<ChatMessage>>((ref) => []);
final isProcessingProvider = StateProvider<bool>((ref) => false);

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<String> _handleToolCall(String name, Map<String, dynamic> args) async {
    // Basic tool implementation logic
    switch (name) {
      case 'get_battery_level':
        return "85% (Simulated)";
      case 'get_current_time':
        return DateTime.now().toString();
      case 'toggle_flashlight':
        final state = args['state'];
        return "Flashlight turned $state (Simulated)";
      default:
        return "Tool not found";
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    ref.read(messagesProvider.notifier).update((state) => [...state, ChatMessage(text: text, isUser: true)]);
    ref.read(isProcessingProvider.notifier).state = true;
    _scrollToBottom();

    final gemma = ref.read(gemmaServiceProvider);
    
    String currentAiResponse = "";
    final aiMessageIndex = ref.read(messagesProvider).length;
    ref.read(messagesProvider.notifier).update((state) => [...state, ChatMessage(text: "", isUser: false)]);

    try {
      await for (final chunk in gemma.sendMessage(text, _handleToolCall)) {
        currentAiResponse += chunk;
        final currentMessages = [...ref.read(messagesProvider)];
        currentMessages[aiMessageIndex] = ChatMessage(text: currentAiResponse, isUser: false);
        ref.read(messagesProvider.notifier).state = currentMessages;
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint("Error sending message: $e");
    } finally {
      ref.read(isProcessingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesProvider);
    final isProcessing = ref.watch(isProcessingProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'SARA',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            fontSize: 24,
          ),
        ),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withAlpha(51)),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              Color(0xFF1A1230),
              Color(0xFF0D0D0D),
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(top: 120, bottom: 20, left: 16, right: 16),
                itemCount: messages.length,
                itemBuilder: (context, index) => ChatBubble(message: messages[index]),
              ),
            ),
            if (isProcessing)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  color: Color(0xFF00E5FF),
                ),
              ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Talk to Sara...',
                    filled: true,
                    fillColor: Colors.white.withAlpha(13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send_rounded),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF673AB7),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: message.isUser ? const Radius.circular(0) : const Radius.circular(20),
            bottomLeft: message.isUser ? const Radius.circular(20) : const Radius.circular(0),
          ),
          gradient: message.isUser
              ? const LinearGradient(colors: [Color(0xFF673AB7), Color(0xFF512DA8)])
              : LinearGradient(colors: [Colors.white.withAlpha(26), Colors.white.withAlpha(13)]),
          border: Border.all(color: Colors.white.withAlpha(26)),
        ),
        child: Text(
          message.text,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
