import 'package:flutter/material.dart';
import '../../Globals/Globals.dart';

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

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> GenSnackBar(BuildContext context, String content) {
  return ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            content,
          ),
        ],
      ),
      duration: Duration(seconds: 1),
    ),
  );
}
