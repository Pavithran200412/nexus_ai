import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _isInitialized = false;
  bool get isListening => _speech.isListening;

  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize TTS
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);

    // Initialize STT
    // Note: initialize() returns true if successful
    await _speech.initialize(
      onError: (val) => print('STT Error: $val'),
      onStatus: (val) => print('STT Status: $val'),
    );
    
    _isInitialized = true;
  }

  Future<bool> startListening({
    required Function(String) onResult,
    required Function(String) onStatus,
  }) async {
    if (!_isInitialized) await init();

    // Check permissions
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
      if (!status.isGranted) return false;
    }

    final available = await _speech.initialize();
    if (available) {
      _speech.listen(
        onResult: (val) => onResult(val.recognizedWords),
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );
      return true;
    }
    return false;
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  Future<void> speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }
}
