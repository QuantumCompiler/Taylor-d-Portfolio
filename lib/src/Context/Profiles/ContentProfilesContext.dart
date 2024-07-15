import 'package:flutter/material.dart';
// import '../../Context/Globals/GlobalContexts.dart';
// import '../../Globals/ProfilesGlobals.dart';
import '../../Utilities/ProfilesUtils.dart';
import '../../Globals/Globals.dart';

class ProfileContentEntry extends StatefulWidget {
  final Profile newProfile;
  final ContentType contentType;

  ProfileContentEntry({
    required this.newProfile,
    required this.contentType,
  });

  @override
  ProfileContentEntryState createState() => ProfileContentEntryState();
}

class ProfileContentEntryState extends State<ProfileContentEntry> {
  @override
  Widget build(BuildContext context) {
    switch (widget.contentType) {
      case ContentType.education:
        return EducationProfileEntry(newProfile: widget.newProfile);
    }
  }
}

BottomAppBar ProfileContentBottomAppBar(BuildContext context) {
  return BottomAppBar(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
    ),
  );
}
