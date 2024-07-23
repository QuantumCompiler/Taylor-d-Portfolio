import 'package:flutter/material.dart';
import '../../Applications/Applications.dart';
import '../../Context/Globals/GlobalContext.dart';
import '../../Context/Profiles/ProfileContext.dart';
import '../../Dashboard/Dashboard.dart';
import '../../Globals/Globals.dart';
import '../../Profiles/Profiles.dart';
import '../../Utilities/GlobalUtils.dart';
import '../../Utilities/ProfilesUtils.dart';

AppBar EditProfileAppBar(BuildContext context, String profileName, bool? backToProfile) {
  return AppBar(
    title: Text(
      'Edit Profile $profileName',
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
    ),
    leading: IconButton(
      icon: Icon(Icons.arrow_back_ios_new_outlined),
      onPressed: () {
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
            onPressed: () {
              Navigator.pushAndRemoveUntil(context, LeftToRightPageRoute(page: Dashboard()), (Route<dynamic> route) => false);
            },
          ),
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
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ...ProfileOptionsContent(context, profile, keys),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

BottomAppBar EditProfileBottomAppBar(BuildContext context, Profile profile, List<GlobalKey> keyList) {
  return BottomAppBar(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          child: Text('Overwrite Profile'),
          onPressed: () async {
            await showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text(
                    'Overwrite Profile',
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
                      Text(
                        'Choose A Name For Your Profile',
                        style: TextStyle(
                          fontSize: secondaryTitles,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: standardSizedBoxHeight),
                      TextFormField(
                        controller: profile.nameController,
                        keyboardType: TextInputType.multiline,
                        maxLines: 1,
                        decoration: InputDecoration(hintText: 'Enter name here...'),
                      ),
                    ],
                  ),
                  actions: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          child: Text('Cancel'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        SizedBox(width: standardSizedBoxWidth),
                        ElevatedButton(
                          child: Text('Overwrite Profile'),
                          onPressed: () async {
                            try {
                              await profile.CreateProfile(profile.nameController.text);
                              Navigator.pushAndRemoveUntil(context, LeftToRightPageRoute(page: ProfilePage()), (Route<dynamic> route) => false);
                              await showDialog(
                                context: context,
                                builder: (context) {
                                  return GenAlertDialogWithIcon(
                                    "Profile ${profile.name}",
                                    "Written Successfully",
                                    Icons.check_circle_outline,
                                  );
                                },
                              );
                            } catch (e) {
                              throw ("Error occurred in overwriting ${profile.nameController.text} profile");
                            }
                          },
                        ),
                      ],
                    )
                  ],
                );
              },
            );
          },
        ),
      ],
    ),
  );
}
