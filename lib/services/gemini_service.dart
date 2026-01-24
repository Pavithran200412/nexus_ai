import 'package:http/http.dart' as http;
import 'dart:convert';

class GeminiService {
  // Replace with your actual Gemini API key
  static const String _apiKey = 'AIzaSyCFXTVGQ7z_kVikQOpYwiy9el5HMtdzB8A';

  Future<String> generateInterviewQuestion({
    required String history,
    required String persona,
    String? resumeText,
  }) async {
    final role = persona == 'INTERVIEWER'
        ? 'Strict Technical Interviewer'
        : 'Friendly Coding Tutor';

    var prompt = 'Role: ' + role + '\n\n';
    if (resumeText != null && resumeText.isNotEmpty) {
      prompt += 'RESUME:\n' + resumeText + '\n\n';
    }
    if (history.isNotEmpty) {
      prompt += 'HISTORY:\n' + history + '\n\n';
    }
    prompt += 'Generate next interview question.';

    return await _generateContent(prompt);
  }

  Future<String> reviewCode({
    required String language,
    required String code,
  }) async {
    final prompt = 'Review this ' + language + ' code:\n\n' + code;
    return await _generateContent(prompt);
  }

  Future<String> _generateContent(String prompt) async {
    // Try multiple model names in order
    final models = [
      'gemini-1.5-flash-latest',
      'gemini-1.5-flash-001',
      'gemini-1.5-pro-latest',
      'gemini-pro',
    ];

    for (final modelName in models) {
      try {
        final url = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$_apiKey'
        );

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.7,
              'maxOutputTokens': 2048,
            }
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          if (data['candidates'] != null && data['candidates'].isNotEmpty) {
            final text = data['candidates'][0]['content']['parts'][0]['text'];
            print('Success with model: ' + modelName);
            return text ?? 'No response generated';
          }
        } else {
          print('Failed with $modelName: ${response.statusCode}');
          continue; // Try next model
        }
      } catch (e) {
        print('Error with $modelName: ' + e.toString());
        continue; // Try next model
      }
    }

    return 'All models failed. Please check:\n1. Your API key is valid\n2. You have API access enabled\n3. Visit: https://aistudio.google.com/app/apikey';
  }

  Stream<String> streamResponse(String prompt) async* {
    yield await _generateContent(prompt);
  }
}