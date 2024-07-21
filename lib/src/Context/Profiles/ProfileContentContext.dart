import 'package:flutter/material.dart';
import '../../Globals/Globals.dart';
import '../../Globals/ProfilesGlobals.dart';
import '../../Utilities/ProfilesUtils.dart';

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

AppBar ProfileContentAppBar(BuildContext context, ContentType type, String profileName) {
  String title = '';
  if (profileName == '') {
    profileName = 'New Profile';
  }
  if (type == ContentType.coverLetter) {
    title = 'Cover Letter - $profileName';
  } else if (type == ContentType.education) {
    title = 'Education - $profileName';
  } else if (type == ContentType.experience) {
    title = 'Experience - $profileName';
  } else if (type == ContentType.projects) {
    title = 'Projects - $profileName';
  } else if (type == ContentType.skills) {
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
                await profile.WriteContentToJSON<ProfileCLCont>('Temp/', coverLetterJSONFile, profile.coverLetterContList);
              } else if (profile.newProfile == false) {
                await profile.WriteContentToJSON<ProfileCLCont>('Profiles/${profile.name}', coverLetterJSONFile, profile.coverLetterContList);
              }
            } else if (type == ContentType.education) {
              if (profile.newProfile == true) {
                await profile.WriteContentToJSON<ProfileEduCont>('Temp/', educationJSONFile, profile.eduContList);
              } else if (profile.newProfile == false) {
                await profile.WriteContentToJSON<ProfileEduCont>('Profiles/${profile.name}', educationJSONFile, profile.eduContList);
              }
            } else if (type == ContentType.experience) {
              if (profile.newProfile == true) {
                await profile.WriteContentToJSON<ProfileExpCont>('Temp/', experienceJSONFile, profile.expContList);
              } else if (profile.newProfile == false) {
                await profile.WriteContentToJSON<ProfileExpCont>('Profiles/${profile.name}', experienceJSONFile, profile.expContList);
              }
            } else if (type == ContentType.projects) {
              if (profile.newProfile == true) {
                await profile.WriteContentToJSON<ProfileProjCont>('Temp/', projectsJSONFile, profile.projContList);
              } else if (profile.newProfile == false) {
                await profile.WriteContentToJSON<ProfileProjCont>('Profiles/${profile.name}', projectsJSONFile, profile.projContList);
              }
            } else if (type == ContentType.skills) {
              if (profile.newProfile == true) {
                await profile.WriteContentToJSON<ProfileSkillsCont>('Temp/', skillsJSONFile, profile.skillsContList);
              } else if (profile.newProfile == false) {
                await profile.WriteContentToJSON<ProfileSkillsCont>('Profiles/${profile.name}', skillsJSONFile, profile.skillsContList);
              }
            }
          },
        ),
      ],
    ),
  );
}
