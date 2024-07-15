import 'package:flutter/material.dart';
// import '../../Context/Globals/GlobalContexts.dart';
// import '../../Globals/ProfilesGlobals.dart';
import '../../Utilities/ProfilesUtils.dart';
import '../../Globals/Globals.dart';

class ProfileContentEntry extends StatefulWidget {
  final Profile newProfile;
  final ContentType contentType;
  final List<GlobalKey> keyList;
  const ProfileContentEntry({
    super.key,
    required this.newProfile,
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
        return EducationProfileEntry(newProfile: widget.newProfile, key: widget.keyList[0]);
    }
  }
}

BottomAppBar ProfileContentBottomAppBar(BuildContext context, ContentType type, Profile newProfile, List<GlobalKey> keyList) {
  return BottomAppBar(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          child: Text('Save Content'),
          onPressed: () {
            newProfile.CreateEduContJSON();
          },
        ),
      ],
    ),
  );
}
