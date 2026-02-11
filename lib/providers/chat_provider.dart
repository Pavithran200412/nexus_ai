import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../services/gemini_service.dart';
import '../services/voice_service.dart';

class ChatProvider with ChangeNotifier {
  final List<Message> _messages = [];
  final GeminiService _geminiService = GeminiService();
  bool _isLoading = false;
  String _persona = 'INTERVIEWER';

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  String get persona => _persona;

  void togglePersona() {
    _persona = _persona == 'INTERVIEWER' ? 'TUTOR' : 'INTERVIEWER';
    notifyListeners();
  }

  void addMessage({
    required Sender sender,
    required String text,
  }) {
    _messages.add(Message(
      id: const Uuid().v4(),
      sender: sender,
      text: text,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    addMessage(sender: Sender.user, text: text);

    // Add immediate "thinking" indicator
    final thinkingId = const Uuid().v4();
    _messages.add(Message(
      id: thinkingId,
      sender: Sender.ai,
      text: '...',
      timestamp: DateTime.now(),
    ));

    _isLoading = true;
    notifyListeners();

    try {
      final recent = _messages.length > 6
          ? _messages.sublist(_messages.length - 6)
          : _messages;

      final history = recent
          .where((m) => m.id != thinkingId)  // Exclude thinking message
          .map((m) => m.sender.name + ': ' + m.text)
          .join('\n');

      final response = await _geminiService.generateInterviewQuestion(
        history: history,
        persona: _persona,
      );

      // Remove thinking indicator
      _messages.removeWhere((m) => m.id == thinkingId);

      _isLoading = false;
      addMessage(sender: Sender.ai, text: response);
      
      // Speak the response
      final voiceService = VoiceService();
      await voiceService.init();
      await voiceService.speak(response);
      
    } catch (e) {
      _messages.removeWhere((m) => m.id == thinkingId);
      _isLoading = false;
      addMessage(sender: Sender.system, text: 'Error: ' + e.toString());
    }
  }
}