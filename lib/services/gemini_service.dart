import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:dio/dio.dart';
import 'dart:convert';

class GeminiService {
  // API Keys - Replace with your actual keys
  static const String _deepSeekApiKey = 'sk-be9f3818d7a0408d9bdd74c360fdc016';
  static const String _geminiApiKey = 'YOUR_GEMINI_API_KEY'; // Optional backup

  late final GenerativeModel? _flashModel;
  late final Dio _dio;

  GeminiService() {
    // Setup Dio for DeepSeek Official API
    _dio = Dio(BaseOptions(
      baseUrl: 'https://api.deepseek.com/v1',
      headers: {
        'Authorization': 'Bearer ' + _deepSeekApiKey,
        'Content-Type': 'application/json',
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    // Optional Gemini fallback
    try {
      if (_geminiApiKey != 'YOUR_GEMINI_API_KEY') {
        _flashModel = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: _geminiApiKey,
        );
      } else {
        _flashModel = null;
      }
    } catch (e) {
      _flashModel = null;
    }
  }

  // DeepSeek Official API (OpenAI-Compatible)
  Future<String> _generateWithDeepSeek({
    required String prompt,
    required String systemPrompt,
    bool stream = false,
  }) async {
    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': 'deepseek-chat',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.7,
          'max_tokens': 2048,
          'stream': false,
        },
      );

      if (response.data != null && response.data['choices'] != null) {
        final choices = response.data['choices'] as List;
        if (choices.isNotEmpty) {
          final content = choices[0]['message']['content'];
          return content.toString().trim();
        }
      }

      return '';
    } catch (e) {
      print('DeepSeek API error: ' + e.toString());
      return '';
    }
  }

  Future<String> generateInterviewQuestion({
    required String history,
    required String persona,
    String? resumeText,
  }) async {
    final systemPrompt = persona == 'INTERVIEWER'
        ? 'You are a strict technical interviewer. Ask one clear, specific technical question at a time. Keep responses concise and professional.'
        : 'You are a friendly coding tutor. Help students learn with encouragement and clear explanations. Be supportive and concise.';

    var userPrompt = '';
    if (resumeText != null && resumeText.isNotEmpty) {
      userPrompt += 'CANDIDATE RESUME:\n' + resumeText + '\n\n';
    }
    if (history.isNotEmpty) {
      userPrompt += 'CONVERSATION HISTORY:\n' + history + '\n\n';
    }
    userPrompt += 'Generate the next interview question based on the context above.';

    // Try DeepSeek Official API (primary)
    final deepSeekResponse = await _generateWithDeepSeek(
      prompt: userPrompt,
      systemPrompt: systemPrompt,
    );

    if (deepSeekResponse.isNotEmpty) {
      return deepSeekResponse;
    }

    // Fallback to Gemini if available
    if (_flashModel != null) {
      try {
        final prompt = systemPrompt + '\n\n' + userPrompt;
        final response = await _flashModel!.generateContent([
          Content.text(prompt)
        ]);
        return response.text ?? 'Error generating question';
      } catch (e) {
        print('Gemini fallback error: ' + e.toString());
      }
    }

    return 'AI service unavailable. Please check your DeepSeek API key.';
  }

  Future<String> reviewCode({
    required String language,
    required String code,
  }) async {
    final systemPrompt = 'You are an expert ' + language +
        ' code reviewer. Provide brief, actionable feedback on code quality, ' +
        'potential bugs, and best practices. Be constructive and specific.';

    final prompt = 'Review this code:\n\n' + code;

    // Try DeepSeek first
    final deepSeekResponse = await _generateWithDeepSeek(
      prompt: prompt,
      systemPrompt: systemPrompt,
    );

    if (deepSeekResponse.isNotEmpty) {
      return deepSeekResponse;
    }

    // Fallback to Gemini
    if (_flashModel != null) {
      try {
        final fullPrompt = systemPrompt + '\n\n' + prompt;
        final response = await _flashModel!.generateContent([
          Content.text(fullPrompt)
        ]);
        return response.text ?? 'No feedback available';
      } catch (e) {
        print('Gemini fallback error: ' + e.toString());
      }
    }

    return 'Code review unavailable. Please check your API keys.';
  }

  // Streaming support (Gemini only for now)
  Stream<String> streamResponse(String prompt) async* {
    if (_flashModel != null) {
      try {
        final response = _flashModel!.generateContentStream([
          Content.text(prompt)
        ]);

        await for (final chunk in response) {
          yield chunk.text ?? '';
        }
      } catch (e) {
        yield 'Error: ' + e.toString();
      }
    } else {
      yield 'Streaming not available without Gemini API key';
    }
  }
}