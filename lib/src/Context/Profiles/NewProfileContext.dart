import 'package:flutter/material.dart';
import '../Globals/GlobalContext.dart';
import '../Profiles/ProfileContext.dart';
import '../../Applications/Applications.dart';
import '../../Globals/Globals.dart';
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
  );
}

SingleChildScrollView NewProfileContent(BuildContext context, Profile profile, List<GlobalKey> keys, bool backToProfile) {
  TextEditingController nameController = TextEditingController();
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
                SizedBox(height: standardSizedBoxHeight),
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
          ),
        ),
      ],
    ),
  );
}

