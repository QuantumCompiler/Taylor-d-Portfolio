import 'package:flutter/material.dart';
import '../../Globals/ProfileGlobals.dart';
import '../../Utilities/ProfileUtils.dart';
import '../../../Globals/Globals.dart';

/*  appBar - AppBar for the edit profile page
      Input:
        context: BuildContext of the page
        prevProfile: Profile object of the previous profile
      Algorithm:
          * Create a back button to return to the previous page
          * Modify the navigation based on the device type
          * Add a title to the AppBar
      Output:
        Returns an AppBar
*/
AppBar appBar(BuildContext context, Profile prevProfile) {
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
            Navigator.of(context).pop();
          } else if (isMobile()) {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          }
        },
      ),
    ],
    title: Text(
      prevProfile.name,
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

/* editProfileContent - Body content for the edit profile page
      Input:
        context: BuildContext of the page
        prevProfile: Profile object of the previous profile
      Algorithm:
          * Create a SingleChildScrollView to allow for scrolling
          * Populate the SingleChildScrollView with a column of profile options
      Output:
        Returns a SingleChildScrollView with a column of profile options
*/
SingleChildScrollView editProfileContent(BuildContext context, Profile prevProfile) {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Profile Name
        ...ProfileEntry(context, profileNameTitle, prevProfile.nameCont, '', lines: 1),
        // Education
        ...ProfileEntry(context, educationTitle, prevProfile.eduCont, ''),
        // Experience
        ...ProfileEntry(context, experienceTitle, prevProfile.expCont, ''),
        // Extracurricular
        ...ProfileEntry(context, extracurricularTitle, prevProfile.extCont, ''),
        // Honors
        ...ProfileEntry(context, honorsTitle, prevProfile.honCont, ''),
        // Projects
        ...ProfileEntry(context, projectsTitle, prevProfile.projCont, ''),
        // References
        ...ProfileEntry(context, referencesTitle, prevProfile.refCont, ''),
        // Skills
        ...ProfileEntry(context, skillsTitle, prevProfile.skillsCont, ''),
      ],
    ),
  );
}

/*  bottomAppBar - BottomAppBar for the edit profile page
      Input:
        context: BuildContext of the page
        prevProfile: Profile object of the previous profile
      Algorithm:
          * Create a row of buttons for the BottomAppBar
          * Modify the buttons based on the device type
      Output:
        Returns a BottomAppBar
*/
BottomAppBar bottomAppBar(BuildContext context, Profile prevProfile) {
  return BottomAppBar(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isDesktop()) ...[
          ElevatedButton(
            onPressed: () {
              prevProfile.setOverwriteFiles();
              Navigator.of(context).pop();
            },
            child: Text(overwriteButton),
          ),
          SizedBox(width: standardSizedBoxWidth),
          ElevatedButton(
            onPressed: () => {},
            child: Text('Set As Primary'),
          ),
          SizedBox(width: standardSizedBoxWidth),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
        ] else if (isMobile()) ...[
          IconButton(
            onPressed: () {
              prevProfile.setOverwriteFiles();
              Navigator.of(context).pop();
            },
            icon: Icon(Icons.save),
          ),
          SizedBox(width: standardSizedBoxWidth),
          IconButton(
            onPressed: () => {},
            icon: Icon(Icons.check),
          ),
          SizedBox(width: standardSizedBoxWidth),
          IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: Icon(Icons.cancel),
          ),
          SizedBox(width: standardSizedBoxWidth),
        ]
      ],
    ),
  );
}
