import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../Context/Globals/GlobalContext.dart';
import '../../Globals/Globals.dart';
import '../../Profiles/ContentProfile.dart';
import '../../Utilities/ProfilesUtils.dart';

SingleChildScrollView EditProfileContent(BuildContext context, Profile previousProfile, List<GlobalKey> keys) {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * titleContainerWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                GenListTileWithFunc(
                  context,
                  'Cover Letter Pitch',
                  previousProfile,
                  (context, previousProfile) async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfileContentPage(profile: previousProfile, title: 'Cover Letter Pitch', type: ContentType.coverLetter, keyList: keys)),
                    );
                  },
                ),
                GenListTileWithFunc(
                  context,
                  'Education',
                  previousProfile,
                  (context, previousProfile) async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfileContentPage(profile: previousProfile, title: 'Education Entries', type: ContentType.education, keyList: keys)),
                    );
                  },
                ),
                GenListTileWithFunc(
                  context,
                  'Experience',
                  previousProfile,
                  (context, previousProfile) async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfileContentPage(profile: previousProfile, title: 'Experience Entries', type: ContentType.experience, keyList: keys)),
                    );
                  },
                ),
                GenListTileWithFunc(
                  context,
                  'Projects',
                  previousProfile,
                  (context, previousProfile) async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfileContentPage(profile: previousProfile, title: 'Project Entries', type: ContentType.projects, keyList: keys)),
                    );
                  },
                ),
                GenListTileWithFunc(
                  context,
                  'Skills',
                  previousProfile,
                  (context, previousProfile) async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfileContentPage(profile: previousProfile, title: 'Skills Entries', type: ContentType.skills, keyList: keys)),
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

BottomAppBar EditProfileBottomAppBar(BuildContext context, Profile previousProfile, List<GlobalKey> keyList, Function setState) {
  TextEditingController nameController = TextEditingController(text: previousProfile.name);
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
                          child: Text('Overwrite Profile'),
                          onPressed: () async {
                            final masterDir = await getApplicationDocumentsDirectory();
                            final currDir = Directory('${masterDir.path}/Profiles/${nameController.text}');
                            if (currDir.existsSync()) {
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
                              nameController.text = previousProfile.name;
                            } else {
                              try {
                                await previousProfile.CreateProfile(nameController.text);
                                Navigator.of(context).pop();
                                Navigator.of(context).pop();
                                setState(() {});
                                await showDialog(
                                  context: context,
                                  builder: (context) {
                                    return GenAlertDialogWithIcon(
                                      "Profile ${previousProfile.name}",
                                      "Written Successfully",
                                      Icons.check_circle_outline,
                                    );
                                  },
                                );
                              } catch (e) {
                                throw ("Error occurred in overwriting ${nameController.text} profile");
                              }
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
