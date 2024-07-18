import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../Globals/GlobalContext.dart';
import '../../Globals/Globals.dart';
import '../../Profiles/ContentProfile.dart';
import '../../Utilities/ProfilesUtils.dart';

SingleChildScrollView NewProfileContent(BuildContext context, Profile newProfile, List<GlobalKey> keys) {
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
                GenListTileWithFunc(
                  context,
                  'Cover Letter Pitch',
                  newProfile,
                  (context, newProfile) async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileContentPage(profile: newProfile, title: 'Cover Letter Pitch', type: ContentType.coverLetter, keyList: keys),
                      ),
                    );
                  },
                ),
                GenListTileWithFunc(
                  context,
                  'Education',
                  newProfile,
                  (context, newProfile) async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileContentPage(profile: newProfile, title: 'Education Entries', type: ContentType.education, keyList: keys),
                      ),
                    );
                  },
                ),
                GenListTileWithFunc(
                  context,
                  'Experience',
                  newProfile,
                  (context, newProfile) async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileContentPage(profile: newProfile, title: 'Experience Entries', type: ContentType.experience, keyList: keys),
                      ),
                    );
                  },
                ),
                GenListTileWithFunc(
                  context,
                  'Projects',
                  newProfile,
                  (context, newProfile) async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileContentPage(profile: newProfile, title: 'Project Entries', type: ContentType.projects, keyList: keys),
                      ),
                    );
                  },
                ),
                GenListTileWithFunc(
                  context,
                  'Skills',
                  newProfile,
                  (context, newProfile) async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileContentPage(profile: newProfile, title: 'Skills Entries', type: ContentType.skills, keyList: keys),
                      ),
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

BottomAppBar NewProfileBottomAppBar(BuildContext context, Profile newProfile) {
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
                                await newProfile.CreateProfile(nameController.text);
                                Navigator.of(context).pop();
                                Navigator.of(context).pop();
                                await showDialog(
                                    context: context,
                                    builder: (context) {
                                      return GenAlertDialogWithIcon(
                                        'Profile ${newProfile.name}',
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
