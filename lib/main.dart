import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'src/Dashboard.dart';
import 'src/Profile.dart';
import 'src/Settings.dart';
import 'src/Themes.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          home: Dashboard(),
          theme: themeProvider.themeData,
          routes: {
            '/dashboard': (context) => Dashboard(),
            '/profile': (context) => ProfilePage(),
            '/settings': (context) => SettingsPage(),
          },
        );
      },
    );
  }
}
