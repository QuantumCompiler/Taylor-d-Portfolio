import 'package:flutter/material.dart';
import '../Globals/GlobalContext.dart';
import '../Profiles/ProfileContext.dart';
import '../../Applications/Applications.dart';
import '../../Dashboard/Dashboard.dart';
import '../../Globals/Globals.dart';
import '../../Settings/Settings.dart';
import '../../Utilities/ProfilesUtils.dart';

AppBar NewProfileAppBar(BuildContext context, bool backToProfile) {
  return AppBar(
    title: Text(
      'Create New Profile',
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
    ),
    leading: NavToPage(context, 'Applications', Icon(Icons.arrow_back_ios_new_outlined), ApplicationsPage(), false, true),
    actions: [
      Row(
        children: [
          NavToPage(context, 'Applications', Icon(Icons.task), ApplicationsPage(), true, true),
          NavToPage(context, 'Settings', Icon(Icons.settings), SettingsPage(), true, true),
          NavToPage(context, 'Dashboard', Icon(Icons.dashboard), Dashboard(), true, true),
        ],
      ),
    ],
  );
}

SingleChildScrollView NewProfileContent(BuildContext context, Profile profile, List<GlobalKey> keys) {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: standardSizedBoxHeight),
                ...ProfileOptionsContent(context, profile, keys, false),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

BottomAppBar NewProfileBottomAppBar(BuildContext context, Profile profile, bool? backToProfile) {
  TextEditingController nameController = TextEditingController();
  return BottomAppBar(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          child: Text('Save Profile'),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                return NewProfileDialog(context, profile, backToProfile, nameController);
              },
            );
          },
        ),
      ],
    ),
  );
}
