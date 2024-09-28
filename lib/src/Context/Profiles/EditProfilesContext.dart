import 'package:flutter/material.dart';
import '../../Applications/Applications.dart';
import '../../Context/Globals/GlobalContext.dart';
import '../../Context/Profiles/ProfileContext.dart';
import '../../Dashboard/Dashboard.dart';
import '../../Globals/Globals.dart';
import '../../Settings/Settings.dart';
import '../../Utilities/ProfilesUtils.dart';

AppBar EditProfileAppBar(BuildContext context, String profileName, bool backToProfile) {
  return AppBar(
    title: Text(
      'Edit Profile $profileName',
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
    ),
    leading: NavToPage(context, 'Applications', Icon(Icons.arrow_back_ios_new_outlined), ApplicationsPage(), false, false),
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

SingleChildScrollView EditProfileContent(BuildContext context, Profile profile, List<GlobalKey> keys) {
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
                ...ProfileOptionsContent(context, profile, keys, false),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

BottomAppBar EditProfileBottomAppBar(BuildContext context, Profile profile, bool? backToProfile, List<GlobalKey> keyList) {
  return BottomAppBar(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          child: Text('Overwrite Profile'),
          onPressed: () async {
            await showDialog(
              context: context,
              builder: (context) {
                return EditProfileDialog(context, profile, backToProfile);
              },
            );
          },
        ),
      ],
    ),
  );
}
