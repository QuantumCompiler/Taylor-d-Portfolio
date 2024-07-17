import 'package:flutter/material.dart';
import '../Context/Globals/GlobalContext.dart';
import '../Globals/ProfilesGlobals.dart';
import '../Context/Profiles/NewProfileContext.dart';
import '../Utilities/ProfilesUtils.dart';

class NewProfilePage extends StatefulWidget {
  const NewProfilePage({super.key});

  @override
  NewProfilePageState createState() => NewProfilePageState();
}

class NewProfilePageState extends State<NewProfilePage> {
  late Future<Profile> futureProfile;
  late List<GlobalKey> keyList;

  @override
  void initState() {
    super.initState();
    keyList = [];
    futureProfile = Profile.Init(newProfile: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GenAppBarWithDashboard(context, createNewProfilePrompt, 3),
      body: FutureBuilder<Profile>(
        future: futureProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('No Profile Found'));
          }
          Profile newProfile = snapshot.data!;
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
          return NewProfileContent(context, newProfile, keyList);
        },
      ),
      bottomNavigationBar: FutureBuilder<Profile>(
        future: futureProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            return NewProfileBottomAppBar(context, snapshot.data!);
          } else {
            return Container();
          }
        },
      ),
    );
  }
}
