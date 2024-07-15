import 'package:flutter/material.dart';
// import '../../Context/Globals/GlobalContexts.dart';
// import '../../Globals/ProfilesGlobals.dart';
import '../../Utilities/ProfilesUtils.dart';
import '../../Globals/Globals.dart';

class ProfileContentEntry extends StatefulWidget {
  final Profile profile;
  final ContentType contentType;
  final List<GlobalKey> keyList;
  const ProfileContentEntry({
    super.key,
    required this.profile,
    required this.contentType,
    required this.keyList,
  });

  @override
  ProfileContentEntryState createState() => ProfileContentEntryState();
}

class ProfileContentEntryState extends State<ProfileContentEntry> {
  @override
  Widget build(BuildContext context) {
    switch (widget.contentType) {
      case ContentType.education:
        return EducationProfileEntry(profile: widget.profile, key: widget.keyList[0]);
      case ContentType.experience:
        return ExperienceProfileEntry(profile: widget.profile, key: widget.keyList[1]);
    }
  }
}

BottomAppBar ProfileContentBottomAppBar(BuildContext context, ContentType type, Profile profile, List<GlobalKey> keyList) {
  String buttonText;
  if (type == ContentType.education) {
    buttonText = 'Save Education';
  } else if (type == ContentType.experience) {
    buttonText = 'Save Experience';
  } else {
    buttonText = 'Save Content';
  }
  return BottomAppBar(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          child: Text(buttonText),
          onPressed: () async {
            if (type == ContentType.education) {
              await profile.CreateEduContJSON();
            } else if (type == ContentType.experience) {
              await profile.CreateExpContJSON();
            }
          },
        ),
      ],
    ),
  );
}
