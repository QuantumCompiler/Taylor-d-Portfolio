import 'package:flutter/material.dart';
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

BottomAppBar NewProfileBottomAppBar(BuildContext context, Profile newProfile, List<GlobalKey> keyList) {
  return BottomAppBar(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          child: Text('Save Profile'),
          onPressed: () async {
            await newProfile.WriteProfile('Temp', 'Temp');
          },
        ),
      ],
    ),
  );
}
