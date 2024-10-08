import 'package:flutter/material.dart';
import '../../Context/Globals/GlobalContext.dart';
import '../../Globals/Globals.dart';
import '../../Globals/ProfilesGlobals.dart';
import '../../Utilities/ProfilesUtils.dart';

class ProfileContentEntry extends StatefulWidget {
  final Profile profile;
  final ProfileContentType type;
  final List<GlobalKey> keyList;
  final bool viewing;
  const ProfileContentEntry({
    super.key,
    required this.profile,
    required this.type,
    required this.keyList,
    required this.viewing,
  });

  @override
  ProfileContentEntryState createState() => ProfileContentEntryState();
}

class ProfileContentEntryState extends State<ProfileContentEntry> {
  @override
  Widget build(BuildContext context) {
    switch (widget.type) {
      case ProfileContentType.coverLetter:
        return CoverLetterProfilePitchEntry(profile: widget.profile, key: widget.keyList[0], viewing: widget.viewing);
      case ProfileContentType.education:
        return EducationProfileEntry(profile: widget.profile, key: widget.keyList[1], viewing: widget.viewing);
      case ProfileContentType.experience:
        return ExperienceProfileEntry(profile: widget.profile, key: widget.keyList[2], viewing: widget.viewing);
      case ProfileContentType.projects:
        return ProjectProfileEntry(profile: widget.profile, key: widget.keyList[3], viewing: widget.viewing);
      case ProfileContentType.skills:
        return SkillsProjectEntry(profile: widget.profile, key: widget.keyList[4], viewing: widget.viewing);
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
        TextButton(
          child: Text(buttonText),
          onPressed: () async {
            if (type == ProfileContentType.coverLetter) {
              try {
                await profile.WriteContentToJSON<ProfileCLCont>(finalDir, coverLetterJSONFile, profile.coverLetterContList);
                GenSnackBar(context, 'Cover Letter Content Written Successfully');
              } catch (e) {
                throw ('Error occurred: $e');
              }
            } else if (type == ProfileContentType.education) {
              try {
                await profile.WriteContentToJSON<ProfileEduCont>(finalDir, educationJSONFile, profile.eduContList);
                GenSnackBar(context, 'Education Content Written Successfully');
              } catch (e) {
                throw ('Error occurred: $e');
              }
            } else if (type == ProfileContentType.experience) {
              try {
                await profile.WriteContentToJSON<ProfileExpCont>(finalDir, experienceJSONFile, profile.expContList);
                GenSnackBar(context, 'Experience Content Written Successfully');
              } catch (e) {
                throw ('Error occurred: $e');
              }
            } else if (type == ProfileContentType.projects) {
              try {
                await profile.WriteContentToJSON<ProfileProjCont>(finalDir, projectsJSONFile, profile.projContList);
                GenSnackBar(context, 'Projects Content Written Successfully');
              } catch (e) {
                throw ('Error occurred: $e');
              }
            } else if (type == ProfileContentType.skills) {
              try {
                await profile.WriteContentToJSON<ProfileSkillsCont>(finalDir, skillsJSONFile, profile.skillsContList);
                GenSnackBar(context, 'Skills Content Written Successfully');
              } catch (e) {
                throw ('Error occurred: $e');
              }
            }
          },
        ),
      ],
    ),
  );
}
