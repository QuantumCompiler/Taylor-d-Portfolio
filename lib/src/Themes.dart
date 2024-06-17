import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkTheme = false;
  bool get isDarkTheme => _isDarkTheme;
  ThemeProvider() {
    _loadTheme();
  }
  void _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkTheme = prefs.getBool('isDarkTheme') ?? false;
    notifyListeners();
  }

  void toggleTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkTheme = !_isDarkTheme;
    prefs.setBool('isDarkTheme', _isDarkTheme);
    notifyListeners();
  }

  ThemeData get themeData {
    return ThemeData(
      brightness: _isDarkTheme ? Brightness.dark : Brightness.light,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all<Color>(_isDarkTheme ? Color.fromARGB(255, 0, 213, 255) : Colors.white),
            foregroundColor: WidgetStateProperty.all<Color>(_isDarkTheme ? Color.fromARGB(255, 0, 213, 255) : Colors.white)),
      ),
    );
  }
}
