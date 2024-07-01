import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Make sure to import this

class OpenAIService {
  final String apiKey;

  OpenAIService({required this.apiKey});

  Future<String> getEinsteinQuote() async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'system', 'content': 'You are a helpful assistant.'},
          {'role': 'user', 'content': 'Give me a random quote from Albert Einstein.'}
        ],
        'max_tokens': 1000,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'].trim();
    } else {
      print('Failed with status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to get quote');
    }
  }
}

class EinsteinQuoteGenerator extends StatefulWidget {
  @override
  _EinsteinQuoteGeneratorState createState() => _EinsteinQuoteGeneratorState();
}

class _EinsteinQuoteGeneratorState extends State<EinsteinQuoteGenerator> {
  late OpenAIService _openAIService;
  String _quote = '';

  @override
  void initState() {
    super.initState();
    _openAIService = OpenAIService(apiKey: dotenv.env['OPENAI_API_KEY']!);
  }

  void _getQuote() async {
    try {
      final quote = await _openAIService.getEinsteinQuote();
      setState(() {
        _quote = quote;
      });
    } catch (e) {
      setState(() {
        _quote = 'Failed to get quote: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'API Test',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _getQuote,
              child: Text('Get Einstein Quote'),
            ),
            SizedBox(height: 20),
            Text(
              _quote,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
