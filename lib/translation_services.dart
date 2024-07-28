import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  final String _baseUrl = 'https://libretranslate.com/translate';

  Future<String> translate(String text, String targetLanguage) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'q': text,
        'source': 'auto',
        'target': targetLanguage,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['translatedText'];
    } else {
      throw Exception('Failed to translate text');
    }
  }
}
