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
      scaffoldBackgroundColor: isDarkTheme ? Color.fromARGB(255, 0, 0, 0) : Color.fromARGB(255, 233, 233, 233),
      drawerTheme: DrawerThemeData(
        backgroundColor: isDarkTheme ? Color.fromARGB(255, 0, 0, 0) : Color.fromARGB(255, 233, 233, 233),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all<Color>(_isDarkTheme ? Colors.white : Colors.black),
          side: WidgetStateProperty.all<BorderSide>(
            BorderSide(
              color: _isDarkTheme ? Colors.white : Colors.black,
              width: 1.5,
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all<Color>(_isDarkTheme ? Colors.white : Colors.black),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _isDarkTheme ? Colors.black : Colors.white,
        foregroundColor: _isDarkTheme ? Colors.white : Colors.black,
        splashColor: _isDarkTheme ? Colors.white : Colors.black,
        iconSize: 20.0,
        sizeConstraints: BoxConstraints.tightFor(
          width: 50.0,
          height: 30.0,
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
      cardTheme: CardTheme(
        elevation: 50.0,
        shadowColor: Color.fromARGB(51, 0, 213, 255),
      ),
      checkboxTheme: CheckboxThemeData(
        checkColor: WidgetStateProperty.all<Color?>(Colors.white),
        fillColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.black;
            }
            return Colors.transparent;
          },
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(
          color: _isDarkTheme ? Colors.white : Colors.black,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          iconColor: WidgetStateProperty.all<Color?>(
            _isDarkTheme ? Colors.white : Colors.black,
          ),
        ),
      ),
      iconTheme: IconThemeData(
        color: _isDarkTheme ? Colors.white : Colors.black,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: _isDarkTheme ? Colors.white : Colors.black,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Color.fromARGB(128, 0, 213, 255),
        contentTextStyle: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.black;
          }
          return Colors.black;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return Colors.grey;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.black;
          }
          return Colors.black;
        }),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: _isDarkTheme ? const Color.fromARGB(129, 255, 255, 255) : const Color.fromARGB(114, 0, 0, 0),
          border: Border(
            top: BorderSide(width: 2.5),
            left: BorderSide(width: 2.5),
            right: BorderSide(width: 2.5),
            bottom: BorderSide(width: 2.5),
          ),
          borderRadius: BorderRadius.circular(50),
        ),
      ),
    );
  }
}

Color themeTextColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.light ? blackTextColor : whiteTextColor;
}
