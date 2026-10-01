import 'dart:convert';
import 'package:http/http.dart' as http;

/// Structured response from Kimi K3 for intent classification
class IntentClassification {
  final String intent;
  final String? confidence;
  final Map<String, dynamic> extractedFields;
  final String? rawResponse;

  IntentClassification({
    required this.intent,
    this.confidence,
    required this.extractedFields,
    this.rawResponse,
  });

  factory IntentClassification.fromJson(Map<String, dynamic> json) {
    return IntentClassification(
      intent: json['intent'] ?? 'general',
      confidence: json['confidence'],
      extractedFields: json['extractedFields'] ?? {},
      rawResponse: json['rawResponse'],
    );
  }
}

/// Kimi K3 API service for structured intent classification
/// Uses OpenAI-compatible endpoint (Moonshot AI)
class KimiApiService {
  static const String baseUrl = 'https://api.moonshot.ai/v1';

  final String apiKey;
  final String model;

  KimiApiService({required this.apiKey, this.model = 'kimi-k3-20260915-tiny'});

  /// Classify user intent and extract structured fields
  /// Returns IntentClassification with intent type and extracted data
  Future<IntentClassification> classifyIntent(String userInput) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {
            'role': 'system',
            'content': _intentClassificationSystemPrompt,
          },
          {
            'role': 'user',
            'content': userInput,
          },
        ],
        'temperature': 0.1,
        'response_format': {
          'type': 'json_schema',
          'json_schema': {
            'name': 'intent_classification',
            'strict': true,
            'schema': {
              'type': 'object',
              'properties': {
                'intent': {
                  'type': 'string',
                  'enum': ['task', 'calendar', 'note', 'planning', 'general']
                },
                'confidence': {
                  'type': 'string',
                  'enum': ['high', 'medium', 'low']
                },
                'extractedFields': {
                  'type': 'object',
                  'properties': {
                    'title': {'type': 'string'},
                    'dueDate': {'type': 'string'},
                    'priority': {'type': 'string'},
                    'description': {'type': 'string'},
                    'location': {'type': 'string'},
                    'reminderTime': {'type': 'string'},
                    'tags': {'type': 'array', 'items': {'type': 'string'}},
                  },
                },
              },
              'required': ['intent', 'confidence', 'extractedFields'],
            },
          },
        },
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      final parsed = jsonDecode(content);
      return IntentClassification(
        intent: parsed['intent'],
        confidence: parsed['confidence'],
        extractedFields: parsed['extractedFields'] ?? {},
        rawResponse: content,
      );
    } else {
      throw Exception(
        'Kimi API error: ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// Generate a response for general Q&A (conversational mode)
  Future<String> generateResponse(
    String userInput,
    List<Map<String, String>> conversationHistory,
  ) async {
    final messages = [
      {'role': 'system', 'content': _generalQaSystemPrompt},
      ...conversationHistory.map((msg) {
        return {
          'role': msg['role'] == 'user' ? 'user' : 'assistant',
          'content': msg['content'],
        };
      }),
      {'role': 'user', 'content': userInput},
    ];

    final response = await http.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 1024,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception(
        'Kimi API error: ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// System prompt for intent classification
  static const String _intentClassificationSystemPrompt = '''
You are PRAVIN, a personal AI assistant that classifies user intents and extracts structured fields.

Classify each user input into one of these intents:
- "task": Create/edit/delete tasks, mark tasks complete
- "calendar": Create/view calendar events, check schedule
- "note": Create/edit/delete notes, quick capture
- "planning": Request daily/weekly planning, suggest task order
- "general": Anything else (questions, chat, non-action queries)

Extract these fields based on the intent:
- title: The main subject or name of the task/event/note
- dueDate: Any date mentioned (natural language like "tomorrow", "Friday 6pm")
- priority: "high", "medium", or "low" (if explicitly stated or implied)
- description: Detailed description if provided
- location: Any location mentioned for events
- reminderTime: Time for reminders if specified
- tags: Any categories or labels mentioned

Return ONLY valid JSON matching the schema above. No markdown, no explanations.
If a field is not applicable, omit it or set to null.
''';

  /// System prompt for general Q&A
  static const String _generalQaSystemPrompt = '''
You are PRAVIN, a helpful personal AI assistant.
Answer the user's questions clearly and concisely.
If the question is about tasks, calendar, or notes, acknowledge it but focus on providing helpful information.
For non-action queries, provide helpful, accurate information.
''';
}