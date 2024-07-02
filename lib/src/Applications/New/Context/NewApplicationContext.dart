import 'package:flutter/material.dart';
import '../../Globals/ApplicationsGlobals.dart';
import '../../Utilities/ApplicationsUtils.dart';
import '../../../Globals/Globals.dart';
import '../../../Themes/Themes.dart';

AppBar appBar(BuildContext context) {
  return AppBar(
    leading: IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        Navigator.of(context).pop();
      },
    ),
    actions: <Widget>[
      IconButton(
        icon: Icon(Icons.dashboard),
        onPressed: () {
          if (isDesktop()) {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          } else if (isMobile()) {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          }
        },
      ),
    ],
    title: Text(
      newApplicationTitle,
      style: TextStyle(
        color: themeTextColor(context),
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

BottomAppBar bottomAppBar(BuildContext context, ApplicationContent content, VoidCallback func) {
  return BottomAppBar(
    color: Colors.transparent,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: func,
          child: Text(
            'Clear',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(width: standardSizedBoxWidth),
        ElevatedButton(
          onPressed: () {
            bool valid = verifyValidInput(content);
            print(valid);
          },
          child: Text(
            'Generate Application',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(width: standardSizedBoxWidth),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            'Cancel',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}
