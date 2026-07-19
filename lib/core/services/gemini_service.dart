import 'package:cloud_functions/cloud_functions.dart';

class ChatMessage {
  final String role; // 'user' | 'model'
  final String text;
  const ChatMessage(this.role, this.text);
}

/// Calls the secure `geminiChat` Cloud Function. The Gemini API key and the
/// role-aware system prompt live server-side only.
class GeminiService {
  static Future<String> send(List<ChatMessage> history,
      {String documentText = ''}) async {
    final callable =
        FirebaseFunctions.instance.httpsCallable('geminiChat');
    final res = await callable.call<Map<String, dynamic>>({
      'messages': history.map((m) => {'role': m.role, 'text': m.text}).toList(),
      if (documentText.isNotEmpty) 'documentText': documentText,
    });
    return (res.data['text'] ?? '') as String;
  }
}
