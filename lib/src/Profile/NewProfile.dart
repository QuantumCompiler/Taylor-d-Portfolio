import 'dart:io';

import 'package:flutter/material.dart';
import '../Globals/Globals.dart';
import 'ProfileUtils.dart';
import '../Themes/Themes.dart';

class NewProfilePage extends StatelessWidget {
  const NewProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    Profile newProfile = Profile(init: true);
    return Scaffold(
      appBar: AppBar(
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
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
          ),
        ],
        title: Text(
          profileCreateNew,
          style: TextStyle(
            color: themeTextColor(context),
            fontSize: appBarTitle,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            // Education
            ...ProfileEntry(context, newProfile.educationTitle, newProfile.eduCont, profileEduHint),
            // Experience
            ...ProfileEntry(context, newProfile.experienceTitle, newProfile.expCont, profileExpHint),
            // Extracurricular
            ...ProfileEntry(context, newProfile.extracurricularTitle, newProfile.extCont, profileExpHint),
            // Honors
            ...ProfileEntry(context, newProfile.honorsTitle, newProfile.honCont, profileHonHint),
            // Projects
            ...ProfileEntry(context, newProfile.projectsTitle, newProfile.projCont, profileProjHint),
            // References
            ...ProfileEntry(context, newProfile.referencesTitle, newProfile.refCont, profileRefHint),
            // Skills
            ...ProfileEntry(context, newProfile.skillsTitle, newProfile.skillsCont, profileSkillsHint),
          ],
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Save Profile
            ElevatedButton(
              onPressed: () async {
                // Show Dialog
                await showDialog(
                  context: context,
                  builder: (context) {
                    // Alert Dialog
                    return AlertDialog(
                      title: Text(
                        'Enter Name Of Current Profile',
                        style: TextStyle(
                          fontSize: appBarTitle,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: TextField(
                        controller: newProfile.nameCont,
                        decoration: InputDecoration(hintText: "Profile Name"),
                      ),
                      actions: <Widget>[
                        // Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            ElevatedButton(
                              child: Text('Cancel'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            SizedBox(width: 20),
                            ElevatedButton(
                              child: Text('Save'),
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
                                          'Profile Already Exists',
                                          style: TextStyle(
                                            fontSize: appBarTitle,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        content: Text(
                                          'Please choose a different name for this profile.',
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
              child: Text('Save Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
