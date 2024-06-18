import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/Profile/EditProfile.dart';
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
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          home: Dashboard(),
          theme: themeProvider.themeData,
          routes: {
            '/dashboard': (context) => Dashboard(),
            // '/editProfile': (context) => EditProfilePage(),
            '/loadProfile': (context) => LoadProfilePage(),
            '/newProfile': (context) => NewProfilePage(),
            '/profile': (context) => ProfilePage(),
            '/settings': (context) => SettingsPage(),
          },
        );
      },
    );
  }
}
