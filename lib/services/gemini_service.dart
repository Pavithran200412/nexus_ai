import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';

class GeminiService {
  // Auto-detect: Use localhost if running on same device
  static String get _ollamaUrl {
    // Try localhost first, then network IP
    return 'http://localhost:11434';
    // Change to your IP only if running on different device:
    // return 'http://192.168.1.100:11434';
  }

  static const String _modelName = 'gemma3:4b';

  Future<String> generateInterviewQuestion({
    required String history,
    required String persona,
    String? resumeText,
  }) async {
    final systemPrompt = persona == 'INTERVIEWER'
        ? _getInterviewerPrompt()
        : _getTutorPrompt();

    var userContext = '';
    if (resumeText != null && resumeText.isNotEmpty) {
      userContext += 'RESUME:\n$resumeText\n\n';
    }
    if (history.isNotEmpty) {
      userContext += 'HISTORY:\n$history\n\n';
    }

    userContext += 'Ask next question.';

    return await _generateWithOllama(systemPrompt, userContext);
  }

  String _getInterviewerPrompt() {
    return '''Technical interviewer. Ask ONE short question (max 20 words).

Rules:
- ONE question only
- No explanations
- Clear and direct

Question:''';
  }

  String _getTutorPrompt() {
    return '''Friendly tutor. Give brief help (max 30 words).

Rules:
- Keep SHORT
- Be encouraging
- One point at a time

Response:''';
  }

  Future<String> reviewCode({
    required String language,
    required String code,
  }) async {
    final userPrompt = '''Review this $language code in 2-3 sentences:

$code

Give: 1 strength, 1-2 issues.''';

    return await _generateWithOllama('Code reviewer.', userPrompt);
  }

  Future<String> _generateWithOllama(String system, String prompt) async {
    try {
      // First check if Ollama is reachable
      final testUrl = Uri.parse(_ollamaUrl);
      try {
        final testResponse = await http.get(testUrl).timeout(
          const Duration(seconds: 2),
        );
        if (testResponse.statusCode != 200) {
          return _getConnectionHelp();
        }
      } catch (e) {
        return _getConnectionHelp();
      }

      // Now make the actual request
      final url = Uri.parse('$_ollamaUrl/api/generate');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': _modelName,
          'prompt': '$system\n\n$prompt',
          'stream': false,
          'options': {
            'temperature': 0.7,
            'num_predict': 150,
            'num_ctx': 2048,
          }
        }),
      ).timeout(
        const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response']?.trim() ?? 'No response';
      } else {
        return 'Ollama responded with error: ${response.statusCode}\n${response.body}';
      }
    } on TimeoutException {
      return 'Request timeout. Model might be too slow.\n\nTry: ollama pull phi3:mini';
    } on SocketException {
      return _getConnectionHelp();
    } catch (e) {
      return 'Unexpected error: ${e.toString()}\n\n${_getConnectionHelp()}';
    }
  }

  String _getConnectionHelp() {
    return '''Cannot connect to Ollama at: $_ollamaUrl

QUICK FIX:
1. Open PowerShell
2. Run: ollama serve
3. Keep that window open
4. Try again

Current URL: $_ollamaUrl
Model: $_modelName

If Ollama is running but still fails:
- Change _ollamaUrl to 'http://localhost:11434'
- Make sure model is installed: ollama pull $_modelName''';
  }

  Stream<String> streamResponse(String prompt) async* {
    try {
      final url = Uri.parse('$_ollamaUrl/api/generate');
      final request = http.Request('POST', url);
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'model': _modelName,
        'prompt': prompt,
        'stream': true,
        'options': {'num_predict': 150}
      });

      final streamedResponse = await request.send();

      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        try {
          final lines = chunk.split('\n').where((line) => line.isNotEmpty);
          for (final line in lines) {
            final data = jsonDecode(line);
            if (data['response'] != null) {
              yield data['response'];
            }
          }
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      yield 'Stream error: ${e.toString()}';
    }
  }
}