import 'package:flutter/material.dart';
import 'src/Dashboard.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Dashboard(),
      theme: ThemeData.dark(),
    );
  }
}