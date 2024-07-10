import 'package:flutter/material.dart';
import '../Globals/ApplicationsGlobals.dart';
import '../Globals/Globals.dart';
import '../Utilities/ApplicationsUtils.dart';
// import '../Jobs/EditJob.dart';

AppBar appBar(BuildContext context, final apps, Function state) {
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
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          }
        },
      ),
    ],
    title: Text(
      apps.isEmpty ? 'No Applications' : 'Load Application',
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

Center loadAppsContent(BuildContext context, final apps, Function state) {
  return Center(
    child: Container(
      width: MediaQuery.of(context).size.width * applicationsContainerWidth,
      child: ListView.builder(
        itemCount: apps.length,
        itemBuilder: (context, index) {
          return StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
            return Tooltip(
              message: 'Click To Edit ${apps[index].path.split('/').last}',
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: ListTile(
                  title: Text(apps[index].path.split('/').last),
                  onTap: () => {},
                ),
              ),
            );
          });
        },
      ),
    ),
  );
}
