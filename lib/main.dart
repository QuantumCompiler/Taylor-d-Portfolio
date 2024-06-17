import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/Dashboard/Dashboard.dart';
import 'src/Profile/LoadProfile.dart';
import 'src/Profile/NewProfile.dart';
import 'src/Profile/Profile.dart';
import 'src/Settings/Settings.dart';
import 'src/Themes/Themes.dart';

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
            '/loadProfile': (context) => LoadProfilePage(),
            '/newProfile': (context) => NewProfilePage(),
            '/settings': (context) => SettingsPage(),
          },
        );
      },
    );
  }
}
