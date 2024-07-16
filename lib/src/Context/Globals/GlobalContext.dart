import 'package:flutter/material.dart';
import '../../Globals/Globals.dart';

AlertDialog GenAlertDialog(String title, String content) {
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

AppBar GenAppBar(BuildContext context, String title) {
  return AppBar(
    leading: IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        if (isDesktop()) {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        } else if (isMobile()) {
          Navigator.of(context).pop();
        }
      },
    ),
    title: Text(
      title,
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

AppBar GenAppBarWithDashboard(BuildContext context, String title, int backPop) {
  return AppBar(
    leading: IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        Navigator.of(context).pop();
      },
    ),
    actions: [
      IconButton(
        icon: Icon(Icons.dashboard),
        onPressed: () {
          if (isDesktop()) {
            for (int i = 0; i < backPop; i++) {
              Navigator.of(context).pop();
            }
          } else if (isMobile()) {
            for (int i = 0; i < backPop - 1; i++) {
              Navigator.of(context).pop();
            }
          }
        },
      ),
    ],
    title: Text(
      title,
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

AppBar GenAppBarWithDashboardObject(BuildContext context, String title, String emptyTitle, int backPop, final obj, Function state) {
  return AppBar(
    leading: IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        Navigator.of(context).pop();
      },
    ),
    actions: [
      IconButton(
        icon: Icon(Icons.dashboard),
        onPressed: () {
          if (isDesktop()) {
            for (int i = 0; i < backPop; i++) {
              Navigator.of(context).pop();
            }
          } else if (isMobile()) {
            for (int i = 0; i < backPop - 1; i++) {
              Navigator.of(context).pop();
            }
          }
        },
      ),
    ],
    title: Text(
      obj.isEmpty ? emptyTitle : title,
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
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

ListTile GenListTileWithRoute(BuildContext context, String title, dynamic obj) {
  return ListTile(
    title: Text(title),
    onTap: () {
      Navigator.push(context, MaterialPageRoute(builder: (context) => obj));
    },
  );
}

ListTile GenListTileWithFunc(BuildContext context, String title, dynamic obj, Future<void> Function(BuildContext context, dynamic obj) mainFunc) {
  return ListTile(
    title: Text(title),
    onTap: () async {
      await mainFunc(context, obj);
    },
  );
}

ListTile GenListTileWithDelFunc(
    BuildContext context, String title, dynamic obj, Widget Function() dialogFunction, Future<void> Function(BuildContext context, dynamic obj) mainFunc, Function setState) {
  return ListTile(
    title: Text(title),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'Delete - ${obj.name}',
          child: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return dialogFunction();
                },
              );
            },
          ),
        ),
      ],
    ),
    onTap: () async {
      await mainFunc(context, obj);
      setState(() {});
    },
  );
}
