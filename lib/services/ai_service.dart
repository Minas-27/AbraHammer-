import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String _apiKey = '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';
  static const String _apiUrl = 'https://openrouter.ai/api/v1/chat/completions';

  // List of available free models that should work
  static const List<String> _availableModels = [
    'mistralai/mistral-7b-instruct:free',
    'meta-llama/llama-3.1-8b-instruct:free',
    'nousresearch/hermes-3-llama-3.1-8b:free',
    'huggingfaceh4/zephyr-7b-beta:free',
    'openchat/openchat-7b:free',
    'gryphe/mythomist-7b:free',
  ];

  static Future<bool> testConnection() async {
    try {
      print('🔑 Testing OpenRouter API connection...');

      final response = await http.get(
        Uri.parse('https://openrouter.ai/api/v1/models'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'HTTP-Referer': 'https://dailyreportapp.com',
          'X-Title': 'Daily Report Generator',
        },
      );

      print('📡 API Test Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ API Connection Successful!');
        final data = jsonDecode(response.body);
        print('📊 Available models: ${data['data'].length}');
        return true;
      } else {
        print('❌ API Connection Failed: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ API Test Error: $e');
      return false;
    }
  }

  static Future<String?> enhanceReportWithAI(String reportContent) async {
    print('🚀 Starting REAL AI enhancement...');

    // First test the connection
    final isConnected = await testConnection();
    if (!isConnected) {
      print('❌ Cannot connect to AI service');
      return null;
    }

    // Try each model until one works
    for (final model in _availableModels) {
      print('🔄 Trying model: $model');
      final result = await _tryModel(model, reportContent);
      if (result != null) {
        print('✅ Success with model: $model');
        return result;
      }
      print('❌ Failed with model: $model, trying next...');
    }

    print('🚫 All models failed, no AI available');
    return null;
  }

  static Future<String?> _tryModel(String model, String reportContent) async {
    try {
      // Safe substring - don't go beyond content length
      final safeContent = reportContent.length > 2000
          ? reportContent.substring(0, 2000)
          : reportContent;

      print('📝 Content length: ${reportContent.length}, Safe length: ${safeContent.length}');

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://dailyreportapp.com',
          'X-Title': 'Daily Report Generator',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {
              'role': 'user',
              'content': '''
Analyze this daily work report and provide genuine insights based on the actual content. Be specific and avoid generic templates.

DAILY REPORT CONTENT:
$safeContent

Please provide three sections:
1. SUMMARY: A genuine summary of what was actually done
2. ACHIEVEMENTS: Real achievements based on the specific content  
3. SUGGESTIONS: Practical suggestions specific to this report

Format your response EXACTLY as:
SUMMARY: [your real summary here]
ACHIEVEMENTS: [actual achievements from content]
SUGGESTIONS: [specific suggestions for this report]

Analyze the actual text and be authentic.'''
            }
          ],
          'max_tokens': 1500,
          'temperature': 0.8,
        }),
      );

      print('📥 Response for $model: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        print('✅ REAL AI Response received from $model!');
        print('Content preview: ${content.substring(0, min(100, content.length))}...');
        return content;
      } else {
        print('❌ $model Error: ${response.statusCode}');
        print('Error details: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ $model Request Error: $e');
      return null;
    }
  }

  static (String?, String?, String?) parseAIResponse(String response) {
    try {
      print('🧠 Parsing REAL AI response...');

      String? summary;
      String? achievements;
      String? suggestions;

      final lines = response.split('\n');

      for (final line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.startsWith('SUMMARY:')) {
          summary = trimmedLine.substring(8).trim();
        } else if (trimmedLine.startsWith('ACHIEVEMENTS:')) {
          achievements = trimmedLine.substring(13).trim();
        } else if (trimmedLine.startsWith('SUGGESTIONS:')) {
          suggestions = trimmedLine.substring(12).trim();
        }
      }

      // If we didn't find the expected format, use the whole response
      if (summary == null && response.isNotEmpty) {
        summary = response;
      }

      print('✅ Parsed REAL AI response');
      return (summary, achievements, suggestions);
    } catch (e) {
      print('❌ Error parsing AI response: $e');
      return (null, null, null);
    }
  }

  static int min(int a, int b) => a < b ? a : b;
}