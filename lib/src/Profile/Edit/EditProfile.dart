import 'package:flutter/material.dart';
import '../../Globals/Globals.dart';
import '../Utilities/ProfileUtils.dart';

class EditProfilePage extends StatelessWidget {
  // Profile Name
  final String profileName;
  const EditProfilePage({required this.profileName, super.key});
  @override
  // Main Widget
  Widget build(BuildContext context) {
    Profile prevProfile = Profile(name: profileName);
    prevProfile.LoadProfileData();
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
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Profile Name
            ...ProfileEntry(context, profileNameTitle, prevProfile.nameCont, '', lines: 1),
            // Education
            ...ProfileEntry(context, profileEduTitle, prevProfile.eduCont, ''),
            // Experience
            ...ProfileEntry(context, profileExpTitle, prevProfile.expCont, ''),
            // Extracurricular
            ...ProfileEntry(context, profileExtTitle, prevProfile.extCont, ''),
            // Honors
            ...ProfileEntry(context, profileHonTitle, prevProfile.honCont, ''),
            // Projects
            ...ProfileEntry(context, profileProjTitle, prevProfile.projCont, ''),
            // References
            ...ProfileEntry(context, profileRefTitle, prevProfile.refCont, ''),
            // Skills
            ...ProfileEntry(context, profileSkillsTitle, prevProfile.skillsCont, ''),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
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
                child: Text('Overwrite'),
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
      ),
    );
  }
}
