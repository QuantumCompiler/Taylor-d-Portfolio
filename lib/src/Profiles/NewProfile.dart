import 'package:flutter/material.dart';
import '../Context/Globals/GlobalContext.dart';
import '../Globals/ProfilesGlobals.dart';
import '../Context/Profiles/NewProfileContext.dart';
import '../Utilities/ProfilesUtils.dart';

class NewProfilePage extends StatelessWidget {
  late List<GlobalKey> keyList;
  NewProfilePage({super.key}) {
    keyList = [];
  }
  @override
  Widget build(BuildContext context) {
    Profile newProfile = Profile();
    final GlobalKey<CoverLetterProfilePitchEntryState> coverLetterProfileKey = GlobalKey<CoverLetterProfilePitchEntryState>();
    final GlobalKey<EducationProfileEntryState> educationProfileKey = GlobalKey<EducationProfileEntryState>();
    final GlobalKey<ExperienceProfileEntryState> experienceProfileKey = GlobalKey<ExperienceProfileEntryState>();
    final GlobalKey<ProjectProfileEntryState> projectProfileKey = GlobalKey<ProjectProfileEntryState>();
    final GlobalKey<SkillsProjectEntryState> skillsProfileKey = GlobalKey<SkillsProjectEntryState>();
    keyList.add(coverLetterProfileKey);
    keyList.add(educationProfileKey);
    keyList.add(experienceProfileKey);
    keyList.add(projectProfileKey);
    keyList.add(skillsProfileKey);
    return Scaffold(
      appBar: GenAppBarWithDashboard(context, createNewProfilePrompt, 3),
      body: NewProfileContent(context, newProfile, keyList),
      bottomNavigationBar: NewProfileBottomAppBar(context, newProfile, keyList),
    );
  }
}
