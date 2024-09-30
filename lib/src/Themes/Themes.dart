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
      scaffoldBackgroundColor: isDarkTheme ? Color.fromARGB(255, 0, 0, 0) : customWhite,
      drawerTheme: DrawerThemeData(
        backgroundColor: isDarkTheme ? Color.fromARGB(255, 0, 0, 0) : customWhite,
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
      dialogBackgroundColor: _isDarkTheme ? Colors.black : customWhite,
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _isDarkTheme ? Colors.black : Colors.white,
        foregroundColor: _isDarkTheme ? Colors.white : Colors.black,
        splashColor: _isDarkTheme ? Colors.white : Colors.black,
        iconSize: 20.0,
        sizeConstraints: BoxConstraints.tightFor(
          width: 50.0,
          height: 30.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: BorderSide(
            color: _isDarkTheme ? Colors.white : Colors.black,
            width: 1.5,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        color: _isDarkTheme ? Colors.black : customWhite,
        titleTextStyle: TextStyle(
          fontSize: appBarTitle,
          fontWeight: FontWeight.bold,
          color: _isDarkTheme ? Colors.white : Colors.black,
        ),
        centerTitle: true,
      ),
      bottomAppBarTheme: BottomAppBarTheme(
        color: _isDarkTheme ? Colors.black : customWhite,
        elevation: 0,
        height: 60,
      ),
      cardTheme: CardTheme(
        elevation: 50.0,
        shadowColor: _isDarkTheme ? Color.fromARGB(86, 255, 255, 255) : Color.fromARGB(142, 0, 0, 0),
        color: _isDarkTheme ? Colors.black : customWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: BorderSide(
            color: _isDarkTheme ? Colors.white : Colors.black,
            width: 1.5,
          ),
        ),
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
      datePickerTheme: DatePickerThemeData(
        backgroundColor: _isDarkTheme ? Colors.black : customWhite,
        dayBackgroundColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.green;
            } else {
              return _isDarkTheme ? Colors.black : Colors.white;
            }
          },
        ),
        todayBackgroundColor: WidgetStateProperty.all<Color>(_isDarkTheme ? Colors.white : Colors.black),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(
          color: _isDarkTheme ? Colors.white : Colors.black,
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all<Color>(_isDarkTheme ? Colors.black : Colors.black),
          shape: WidgetStateProperty.all<OutlinedBorder>(
            RoundedRectangleBorder(
              side: BorderSide(
                color: _isDarkTheme ? Colors.white : Colors.black,
                width: 0.5,
              ),
            ),
          ),
        ),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: _isDarkTheme ? Colors.black : customWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        collapsedIconColor: _isDarkTheme ? Colors.white : Colors.black,
        iconColor: Colors.green,
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
        tileColor: _isDarkTheme ? Colors.black : customWhite,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: _isDarkTheme ? Colors.black : customWhite,
        modalBarrierColor: Color.fromARGB(175, 0, 0, 0),
        dragHandleColor: _isDarkTheme ? Colors.white : Colors.black,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.transparent,
        contentTextStyle: TextStyle(
          color: _isDarkTheme ? Colors.white : Colors.black,
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
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: _isDarkTheme ? Colors.white : Colors.black,
        ),
      ),
      tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: _isDarkTheme ? Color.fromARGB(0, 0, 0, 0) : Color.fromARGB(0, 0, 0, 0),
            border: Border(
              top: BorderSide(
                width: 2.5,
                color: _isDarkTheme ? Colors.white : Colors.black,
              ),
              left: BorderSide(
                width: 2.5,
                color: _isDarkTheme ? Colors.white : Colors.black,
              ),
              right: BorderSide(
                width: 2.5,
                color: _isDarkTheme ? Colors.white : Colors.black,
              ),
              bottom: BorderSide(
                width: 2.5,
                color: _isDarkTheme ? Colors.white : Colors.black,
              ),
            ),
            borderRadius: BorderRadius.circular(50),
          ),
          textStyle: TextStyle(
            color: _isDarkTheme ? Colors.white : Colors.black,
            fontSize: 12.0,
          )),
    );
  }
}

Color themeTextColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.light ? blackTextColor : whiteTextColor;
}
