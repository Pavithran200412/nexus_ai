import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';
import '../services/voice_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final VoiceService _voiceService = VoiceService();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initVoice();
  }

  void _initVoice() async {
    await _voiceService.init();
  }

  void _toggleListening() async {
    if (_isListening) {
      await _voiceService.stopListening();
      setState(() => _isListening = false);
    } else {
      final available = await _voiceService.startListening(
        onResult: (text) {
          setState(() {
            _controller.text = text;
          });
        },
        onStatus: (status) {
            if (status == 'notListening') {
              setState(() => _isListening = false);
            }
        },
      );
      if (available) {
        setState(() => _isListening = true);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    context.read<ChatProvider>().sendMessage(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nexus AI'),
        actions: [
          Consumer<ChatProvider>(
            builder: (context, provider, _) => TextButton(
              onPressed: provider.togglePersona,
              child: Text(provider.persona + ' MODE'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, provider, _) {
                if (provider.messages.isEmpty) {
                  return const Center(
                    child: Text('Start your interview'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.messages.length,
                  itemBuilder: (context, index) {
                    return MessageBubble(
                      message: provider.messages[index],
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Message...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.red : null,
                  ),
                  onPressed: _toggleListening,
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}