import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../Profiles/ProfileContext.dart';
import '../Globals/GlobalContext.dart';
import '../../Dashboard/Dashboard.dart';
import '../../Globals/Globals.dart';
import '../../Profiles/Profiles.dart';
import '../../Utilities/ProfilesUtils.dart';
import '../../Utilities/GlobalUtils.dart';

AppBar NewProfileAppBar(BuildContext context) {
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
        Navigator.pushAndRemoveUntil(context, LeftToRightPageRoute(page: ProfilePage()), (Route<dynamic> route) => false);
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
            width: MediaQuery.of(context).size.width * titleContainerWidth,
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

BottomAppBar NewProfileBottomAppBar(BuildContext context, Profile profile) {
  TextEditingController nameController = TextEditingController();
  return BottomAppBar(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          child: Text('Save Profile'),
          onPressed: () async {
            await showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text(
                    'Save New Profile',
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
                        'Choose A Name For Your New Profile',
                        style: TextStyle(
                          fontSize: secondaryTitles,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      TextFormField(
                        controller: nameController,
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
                          child: Text('Save Profile'),
                          onPressed: () async {
                            final masterDir = await getApplicationDocumentsDirectory();
                            final currDir = Directory('${masterDir.path}/Profiles/${nameController.text}');
                            if (await currDir.exists()) {
                              Navigator.of(context).pop();
                              await showDialog(
                                context: context,
                                builder: (context) {
                                  return GenAlertDialogWithIcon(
                                    "Profile ${nameController.text} Already Exists!",
                                    "Please select a different name for this profile",
                                    Icons.error,
                                  );
                                },
                              );
                            } else {
                              try {
                                await profile.CreateProfile(nameController.text);
                                Navigator.pushAndRemoveUntil(context, LeftToRightPageRoute(page: ProfilePage()), (Route<dynamic> route) => false);
                                await showDialog(
                                    context: context,
                                    builder: (context) {
                                      return GenAlertDialogWithIcon(
                                        'Profile ${profile.name}',
                                        'Written Successfully',
                                        Icons.check_circle_outline,
                                      );
                                    });
                              } catch (e) {
                                await showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text('Error'),
                                      content: Text('An error occurred while creating the profile. Please try again. $e'),
                                      actions: [
                                        ElevatedButton(
                                          child: Text('OK'),
                                          onPressed: () => Navigator.of(context).pop(),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
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
