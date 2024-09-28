import 'package:flutter/material.dart';
import '../../Applications/ViewApplication.dart';
import '../../Applications/Applications.dart';
import '../../Context/Globals/GlobalContext.dart';
import '../../Context/Profiles/ProfileContext.dart';
import '../../Dashboard/Dashboard.dart';
import '../../Globals/Globals.dart';
import '../../Settings/Settings.dart';
import '../../Utilities/ApplicationsUtils.dart';
import '../../Utilities/ProfilesUtils.dart';

AppBar ViewProfileAppBar(BuildContext context, String profileName, Application app) {
  return AppBar(
    title: Text(
      'View Content For $profileName',
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
    ),
    leading: NavToPage(context, app.name, Icon(Icons.arrow_back_ios_new_outlined), ViewApplicationPage(app: app), false, false),
    actions: [
      Row(
        children: [
          NavToPage(context, 'Applications', Icon(Icons.task), ApplicationsPage(), true, false),
          NavToPage(context, 'Settings', Icon(Icons.settings), SettingsPage(), true, false),
          NavToPage(context, 'Dashboard', Icon(Icons.dashboard), Dashboard(), true, false),
        ],
      ),
    ],
  );
}

SingleChildScrollView ViewProfileContent(BuildContext context, Profile profile, List<GlobalKey> keys) {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ...ProfileOptionsContent(context, profile, keys, true),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
