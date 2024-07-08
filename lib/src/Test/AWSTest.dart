import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<String> fetchMessage() async {
  final response = await http.get(Uri.parse('http://18.222.120.48:3000'));

  if (response.statusCode == 200) {
    var decodedResponse = jsonDecode(response.body);
    return decodedResponse['message'];
  } else {
    throw Exception('Failed to load message');
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<String> message;

  @override
  void initState() {
    super.initState();
    message = fetchMessage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hello, Taylor'),
      ),
      body: Center(
        child: FutureBuilder<String>(
          future: message,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              return Text(snapshot.data ?? 'No message');
            }
          },
        ),
      ),
    );
  }
}
