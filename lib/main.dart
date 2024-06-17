import 'package:flutter/material.dart';
import 'src/Dashboard.dart';
import 'src/Profile.dart';
import 'src/Settings.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Dashboard(),
      theme: ThemeData.dark(),
      routes: {
        '/dashboard': (context) => Dashboard(),
        '/profile': (context) => ProfilePage(),
        '/settings': (context) => SettingsPage(),
      },
    );
  }
}
