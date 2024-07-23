import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Globals/Globals.dart';

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
          backgroundColor: WidgetStateProperty.all<Color>(_isDarkTheme ? cyanButtonColor : cyanButtonColor),
          foregroundColor: WidgetStateProperty.all<Color>(_isDarkTheme ? Colors.black : Colors.black),
          textStyle: WidgetStateProperty.all<TextStyle>(
            TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        color: Colors.transparent,
      ),
      bottomAppBarTheme: BottomAppBarTheme(
        color: Colors.transparent,
        elevation: 0,
        height: 60,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Color.fromARGB(128, 0, 213, 255),
        contentTextStyle: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 50.0,
        shadowColor: Color.fromARGB(51, 0, 213, 255),
      ),
    );
  }
}

Color themeTextColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.light ? blackTextColor : whiteTextColor;
}
