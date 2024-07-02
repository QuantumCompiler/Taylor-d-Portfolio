import 'package:flutter/material.dart';
import '../New/NewApplication.dart';
import '../Globals/ApplicationsGlobals.dart';
import '../../Globals/Globals.dart';

AppBar appBar(BuildContext context) {
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
      applicationsTitle,
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

Center applicationsContent(BuildContext context) {
  return Center(
    child: Container(
      width: MediaQuery.of(context).size.width * applicationsTileContainerWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: standardSizedBoxHeight),
          ListTile(
            title: Text(
              createNewApplicationTile,
            ),
            onTap: () => {
              Navigator.push(context, MaterialPageRoute(builder: (context) => NewApplicationPage())),
            },
          ),
        ],
      ),
    ),
  );
}
