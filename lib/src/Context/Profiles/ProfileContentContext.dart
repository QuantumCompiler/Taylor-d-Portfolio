import 'package:flutter/material.dart';
import '../../Globals/Globals.dart';
import '../../Globals/ProfilesGlobals.dart';
import '../../Utilities/ProfilesUtils.dart';

class ProfileContentEntry extends StatefulWidget {
  final Profile profile;
  final ProfileContentType type;
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
      case ProfileContentType.coverLetter:
        return CoverLetterProfilePitchEntry(profile: widget.profile, key: widget.keyList[0]);
      case ProfileContentType.education:
        return EducationProfileEntry(profile: widget.profile, key: widget.keyList[1]);
      case ProfileContentType.experience:
        return ExperienceProfileEntry(profile: widget.profile, key: widget.keyList[2]);
      case ProfileContentType.projects:
        return ProjectProfileEntry(profile: widget.profile, key: widget.keyList[3]);
      case ProfileContentType.skills:
        return SkillsProjectEntry(profile: widget.profile, key: widget.keyList[4]);
    }
  }
}

AppBar ProfileContentAppBar(BuildContext context, ProfileContentType type, String profileName) {
  String title = '';
  if (profileName == '') {
    profileName = 'New Profile';
  }
  if (type == ProfileContentType.coverLetter) {
    title = 'Cover Letter - $profileName';
  } else if (type == ProfileContentType.education) {
    title = 'Education - $profileName';
  } else if (type == ProfileContentType.experience) {
    title = 'Experience - $profileName';
  } else if (type == ProfileContentType.projects) {
    title = 'Projects - $profileName';
  } else if (type == ProfileContentType.skills) {
    title = 'Skills - $profileName';
  } else {
    title = 'Content - $profileName';
  }
  return AppBar(
    title: Text(
      title,
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
    ),
    leading: IconButton(
      icon: Icon(Icons.arrow_back_ios_new_outlined),
      onPressed: () {
        Navigator.of(context).pop();
      },
    ),
  );
}

BottomAppBar ProfileContentBottomAppBar(BuildContext context, ProfileContentType type, Profile profile, List<GlobalKey> keyList) {
  String finalDir = '';
  if (profile.newProfile == true) {
    finalDir = 'Temp';
  } else if (profile.newProfile == false) {
    finalDir = 'Profiles/${profile.name}';
  }
  String buttonText;
  if (type == ProfileContentType.coverLetter) {
    buttonText = 'Save Pitch';
  } else if (type == ProfileContentType.education) {
    buttonText = 'Save Education';
  } else if (type == ProfileContentType.experience) {
    buttonText = 'Save Experience';
  } else if (type == ProfileContentType.projects) {
    buttonText = 'Save Projects';
  } else if (type == ProfileContentType.skills) {
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
            if (type == ProfileContentType.coverLetter) {
              await profile.WriteContentToJSON<ProfileCLCont>(finalDir, coverLetterJSONFile, profile.coverLetterContList);
            } else if (type == ProfileContentType.education) {
              await profile.WriteContentToJSON<ProfileEduCont>(finalDir, educationJSONFile, profile.eduContList);
            } else if (type == ProfileContentType.experience) {
              await profile.WriteContentToJSON<ProfileExpCont>(finalDir, experienceJSONFile, profile.expContList);
            } else if (type == ProfileContentType.projects) {
              await profile.WriteContentToJSON<ProfileProjCont>(finalDir, projectsJSONFile, profile.projContList);
            } else if (type == ProfileContentType.skills) {
              await profile.WriteContentToJSON<ProfileSkillsCont>(finalDir, skillsJSONFile, profile.skillsContList);
            }
          },
        ),
      ],
    ),
  );
}
