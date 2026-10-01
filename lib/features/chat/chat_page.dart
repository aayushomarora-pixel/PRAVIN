import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pravin/core/services/intent_router.dart';
import 'package:pravin/core/services/voice_service.dart';

/// Chat interface for general Q&A with Kimi K3 (Phase 3)
/// Implements the intent router for classifying user input
/// Phase 4: Voice input/output integration
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final IntentRouter _intentRouter = IntentRouter();
  final VoiceService _voiceService = VoiceService();

  final List<Map<String, String>> _conversationHistory = [];
  bool _isVoiceListening = false;

  @override
  void initState() {
    super.initState();
    _initializeVoiceService();
  }

  Future<void> _initializeVoiceService() async {
    await _voiceService.initialize();
    _voiceService.onTextCaptured = (text) {
      setState(() {
        _controller.text = text;
        _focusNode.requestFocus();
      });
    };
    _voiceService.onSpeakingStarted = (text) {
      // Could show visual indicator for speaking
    };
    _voiceService.onSpeakingCompleted = (text) {
      // Could clear indicator after speaking
    };
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _voiceService.stopListening();
    super.dispose();
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = text.trim();
    _controller.clear();
    _focusNode.requestFocus();

    setState(() {
      _conversationHistory.add({'role': 'user', 'content': userMessage});
    });

    await _intentRouter.processInput(
      input: userMessage,
      context: context,
      conversationHistory: jsonEncode(_conversationHistory),
    );
  }

  Future<void> _toggleVoiceListening() async {
    if (_isVoiceListening) {
      await _voiceService.stopListening();
      setState(() {
        _isVoiceListening = false;
      });
      // Send captured text as message
      final capturedText = _voiceService.capturedText;
      if (capturedText.isNotEmpty) {
        _sendMessage(capturedText);
        _voiceService.clearText();
      }
    } else {
      setState(() {
        _isVoiceListening = true;
      });
      await _voiceService.startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with PRAVIN'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _conversationHistory.length,
              reverse: true,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final message = _conversationHistory[_conversationHistory.length - 1 - index];
                final isUser = message['role'] == 'user';
                return ChatMessageWidget(
                  message: message['content'] ?? '',
                  isUser: isUser,
                );
              },
            ),
          ),
          _buildInputField(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleVoiceListening,
        tooltip: _isVoiceListening ? 'Stop Listening' : 'Start Voice Input',
        child: Icon(_isVoiceListening ? Icons.mic : Icons.mic_none),
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          IconButton(
            onPressed: () => _sendMessage(_controller.text),
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}

class ChatMessageWidget extends StatelessWidget {
  final String message;
  final bool isUser;

  const ChatMessageWidget({super.key, required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.topRight : Alignment.topLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isUser
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}