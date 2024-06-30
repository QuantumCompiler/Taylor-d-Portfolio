import 'dart:io';
import 'package:flutter/material.dart';
import '../../Globals/ProfileGlobals.dart';
import '../../Utilities/ProfileUtils.dart';
import '../../../Globals/Globals.dart';
import '../../../Themes/Themes.dart';

/*  appBar - AppBar for the new profile page
      Input:
        context: BuildContext of the page
      Algorithm:
          * Create a back button to return to the previous page
          * Modify the navigation based on the device type
          * Add a title to the AppBar
      Output:
        Returns an AppBars
*/
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
      createNewProfilePrompt,
      style: TextStyle(
        color: themeTextColor(context),
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

/*  newProfileContent - Body content for the new profile page
      Input:
        context: BuildContext of the page
        newProfile: Profile object of the new profile
      Algorithm:
          * Create a SingleChildScrollView to allow for scrolling
          * Populate the SingleChildScrollView with a column of profile options
      Output:
        Returns a SingleChildScrollView with a column of profile options
*/
SingleChildScrollView newProfileContent(BuildContext context, Profile newProfile) {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        // Education
        ...ProfileEntry(context, newProfile.eduTitle, newProfile.eduCont, educationHint),
        // Experience
        ...ProfileEntry(context, newProfile.expTitle, newProfile.expCont, experienceHint),
        // Extracurricular
        ...ProfileEntry(context, newProfile.extTitle, newProfile.extCont, experienceHint),
        // Honors
        ...ProfileEntry(context, newProfile.honTitle, newProfile.honCont, honorsHint),
        // Projects
        ...ProfileEntry(context, newProfile.projTitle, newProfile.projCont, projectsHint),
        // References
        ...ProfileEntry(context, newProfile.refTitle, newProfile.refCont, referencesHint),
        // Skills
        ...ProfileEntry(context, newProfile.skiTitle, newProfile.skillsCont, skillsHint),
      ],
    ),
  );
}

/*  bottomAppBar - BottomAppBar for the new profile page
      Input:
        context: BuildContext of the page
        newProfile: Profile object of the new profile
      Algorithm:
          * Modify the navigation based on the device type
          * Create a button to save the profile
      Output:
        Returns a BottomAppBar
*/
BottomAppBar bottomAppBar(BuildContext context, Profile newProfile) {
  return BottomAppBar(
    color: Colors.transparent,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        // Save Profile
        if (isDesktop()) ...[
          desktopButton(context, newProfile),
        ] else if (isMobile()) ...[
          mobileIconButton(context, newProfile),
        ]
      ],
    ),
  );
}

/*  desktopButton - ElevatedButton for the desktop version of the new profile page
      Input:
        context: BuildContext of the page
        newProfile: Profile object of the new profile
      Algorithm:
          * Show a dialog to enter the profile name
          * Create a new profile with the entered name
      Output:
        Returns an ElevatedButton
*/
ElevatedButton desktopButton(BuildContext context, Profile newProfile) {
  return ElevatedButton(
    onPressed: () async {
      // Show Dialog
      await showDialog(
        context: context,
        builder: (context) {
          // Alert Dialog
          return AlertDialog(
            title: Text(
              enterProfileNamePrompt,
              style: TextStyle(
                fontSize: appBarTitle,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: TextField(
              controller: newProfile.nameCont,
              decoration: InputDecoration(hintText: profileNameHint),
            ),
            actions: <Widget>[
              // Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ElevatedButton(
                    child: Text(cancelButton),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  SizedBox(width: 20),
                  ElevatedButton(
                    child: Text(saveButton),
                    onPressed: () async {
                      final dir = await newProfile.profsDir;
                      final currDir = Directory('${dir.path}/${newProfile.nameCont.text}');
                      if (!currDir.existsSync()) {
                        newProfile.CreateNewProfile(newProfile.nameCont.text);
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).pop();
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(
                                profileAlreadyExists,
                                style: TextStyle(
                                  fontSize: appBarTitle,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              content: Text(
                                chooseDifferentName,
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                        );
                        newProfile.nameCont.text = '';
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
    child: Text(saveProfileButton),
  );
}

/*  mobileIconButton - IconButton for the mobile version of the new profile page
      Input:
        context: BuildContext of the page
        newProfile: Profile object of the new profile
      Algorithm:
          * Show a dialog to enter the profile name
          * Create a new profile with the entered name
      Output:
        Returns an IconButton
*/
IconButton mobileIconButton(BuildContext context, Profile newProfile) {
  return IconButton(
    onPressed: () async {
      // Show Dialog
      await showDialog(
        context: context,
        builder: (context) {
          // Alert Dialog
          return AlertDialog(
            title: Text(
              enterProfileNamePrompt,
              style: TextStyle(
                fontSize: appBarTitle,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: TextField(
              controller: newProfile.nameCont,
              decoration: InputDecoration(hintText: profileNameHint),
            ),
            actions: <Widget>[
              // Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: Icon(Icons.cancel),
                  ),
                  SizedBox(width: 20),
                  IconButton(
                    icon: Icon(Icons.save),
                    onPressed: () async {
                      final dir = await newProfile.profsDir;
                      final currDir = Directory('${dir.path}/${newProfile.nameCont.text}');
                      if (!currDir.existsSync()) {
                        newProfile.CreateNewProfile(newProfile.nameCont.text);
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).pop();
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(
                                profileAlreadyExists,
                                style: TextStyle(
                                  fontSize: appBarTitle,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              content: Text(
                                chooseDifferentName,
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                        );
                        newProfile.nameCont.text = '';
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
    icon: Icon(Icons.save),
  );
}
