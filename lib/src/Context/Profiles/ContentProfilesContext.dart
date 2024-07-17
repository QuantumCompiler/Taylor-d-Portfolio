import 'package:flutter/material.dart';
import '../../Utilities/ProfilesUtils.dart';
import '../../Globals/Globals.dart';
import '../../Globals/ProfilesGlobals.dart';

class ProfileContentEntry extends StatefulWidget {
  final Profile profile;
  final ContentType type;
  final List<GlobalKey> keyList;
  const ProfileContentEntry({
    super.key,
    required this.profile,
    required this.type,
    required this.keyList,
  });

  @override
  ProfileContentEntryState createState() => ProfileContentEntryState();
}

class ProfileContentEntryState extends State<ProfileContentEntry> {
  @override
  Widget build(BuildContext context) {
    switch (widget.type) {
      case ContentType.coverLetter:
        return CoverLetterProfilePitchEntry(profile: widget.profile, key: widget.keyList[0]);
      case ContentType.education:
        return EducationProfileEntry(profile: widget.profile, key: widget.keyList[1]);
      case ContentType.experience:
        return ExperienceProfileEntry(profile: widget.profile, key: widget.keyList[2]);
      case ContentType.projects:
        return ProjectProfileEntry(profile: widget.profile, key: widget.keyList[3]);
      case ContentType.skills:
        return SkillsProjectEntry(profile: widget.profile, key: widget.keyList[4]);
    }
  }
}

BottomAppBar ProfileContentBottomAppBar(BuildContext context, ContentType type, Profile profile, List<GlobalKey> keyList) {
  String buttonText;
  if (type == ContentType.coverLetter) {
    buttonText = 'Save Pitch';
  } else if (type == ContentType.education) {
    buttonText = 'Save Education';
  } else if (type == ContentType.experience) {
    buttonText = 'Save Experience';
  } else if (type == ContentType.projects) {
    buttonText = 'Save Projects';
  } else if (type == ContentType.skills) {
    buttonText = 'Save Skills';
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
            if (type == ContentType.coverLetter) {
              if (profile.newProfile == true) {
                await profile.WriteContentToJSON('Temp/', coverLetterJSONFile, profile.coverLetterContList);
              }
            } else if (type == ContentType.education) {
              if (profile.newProfile == true) {
                await profile.WriteContentToJSON('Temp/', educationJSONFile, profile.eduContList);
              }
            } else if (type == ContentType.experience) {
              if (profile.newProfile == true) {
                await profile.WriteContentToJSON('Temp/', experienceJSONFile, profile.expContList);
              }
            } else if (type == ContentType.projects) {
              if (profile.newProfile == true) {
                await profile.WriteContentToJSON('Temp/', projectsJSONFile, profile.projContList);
              }
            } else if (type == ContentType.skills) {
              if (profile.newProfile == true) {
                await profile.WriteContentToJSON('Temp/', skillsJSONFile, profile.skillsContList);
              }
            }
          },
        ),
      ],
    ),
  );
}
