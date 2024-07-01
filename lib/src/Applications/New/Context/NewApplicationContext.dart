import 'package:flutter/material.dart';
import '../../Globals/ApplicationsGlobals.dart';
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

SingleChildScrollView newApplicationContent(BuildContext context) {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[],
    ),
  );
}
