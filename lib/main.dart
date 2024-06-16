import 'package:flutter/material.dart';
import 'src/Dashboard.dart';
import 'src/GenResume.dart';
import 'src/GenCoverLetter.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Dashboard(),
      theme: ThemeData.dark(),
      routes: {
        '/dashboard': (context) => Dashboard(),
        '/genresume': (context) => GenResumePage(),
        '/gencoverletter': (context) => GenCoverLetterPage(),
      },
    );
  }
}
