import 'package:flutter/material.dart';
import '../../Globals/Globals.dart';

AlertDialog GenAlertDialog(String title, String content) {
  return AlertDialog(
    title: Text(
      title,
      style: TextStyle(
        fontSize: secondaryTitles,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    ),
    content: Text(
      content,
      style: TextStyle(
        fontSize: secondaryTitles,
      ),
      textAlign: TextAlign.center,
    ),
  );
}

AlertDialog GenAlertDialogWithIcon(String title, String content, IconData? icon) {
  return AlertDialog(
    title: Text(
      title,
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    ),
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 100.0,
        ),
        SizedBox(height: standardSizedBoxHeight),
        Text(content),
      ],
    ),
  );
}

AlertDialog GenAlertDialogWithFunctions(String title, String content, String button1, String button2, Function button1Func, Future<void> Function() button2Func, Function state) {
  return AlertDialog(
    title: Text(
      title,
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    ),
    content: Text(
      content,
      style: TextStyle(
        fontSize: secondaryTitles,
      ),
      textAlign: TextAlign.center,
    ),
    actions: <Widget>[
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            child: Text(button1),
            onPressed: () {
              button1Func();
            },
          ),
          SizedBox(width: standardSizedBoxWidth),
          ElevatedButton(
            child: Text(button2),
            onPressed: () async {
              await button2Func();
              button1Func();
              state(() {});
            },
          ),
        ],
      )
    ],
  );
}

Future<DateTime?> SelectDate(BuildContext context) async {
  final DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(1900),
    lastDate: DateTime(3000),
  );
  if (pickedDate != null) {
    return DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
  }
  return DateTime.now();
}
