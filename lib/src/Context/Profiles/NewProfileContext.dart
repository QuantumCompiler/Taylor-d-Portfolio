import 'package:flutter/material.dart';
import '../Profiles/ProfileContext.dart';
import '../Globals/GlobalContext.dart';
import '../../Applications/Applications.dart';
import '../../Dashboard/Dashboard.dart';
import '../../Globals/Globals.dart';
import '../../Profiles/Profiles.dart';
import '../../Utilities/ProfilesUtils.dart';
import '../../Utilities/GlobalUtils.dart';

AppBar NewProfileAppBar(BuildContext context, bool? backToProfile) {
  return AppBar(
    title: Text(
      'Create New Profile',
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
    ),
    leading: IconButton(
      icon: Icon(Icons.arrow_back_ios_new_outlined),
      onPressed: () async {
        await CleanDir('Temp');
        if (backToProfile == true) {
          Navigator.pushAndRemoveUntil(context, LeftToRightPageRoute(page: ProfilePage()), (Route<dynamic> route) => false);
        } else if (backToProfile == false) {
          Navigator.pushAndRemoveUntil(context, LeftToRightPageRoute(page: ApplicationsPage()), (Route<dynamic> route) => false);
        }
      },
    ),
    actions: [
      Row(
        children: [
          IconButton(
            icon: Icon(Icons.dashboard),
            onPressed: () async {
              await CleanDir('Temp');
              Navigator.pushAndRemoveUntil(context, LeftToRightPageRoute(page: Dashboard()), (Route<dynamic> route) => false);
            },
          ),
        ],
      )
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
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: standardSizedBoxHeight),
                ...ProfileOptionsContent(context, profile, keys),
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
        ElevatedButton(
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
