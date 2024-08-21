import 'package:flutter/material.dart';
import '../Context/Profiles/ViewProfileContext.dart';
import '../Utilities/ApplicationsUtils.dart';
import '../Utilities/ProfilesUtils.dart';

class ViewProfilePage extends StatefulWidget {
  late String profileName;
  late Application app;
  ViewProfilePage({
    super.key,
    required this.profileName,
    required this.app,
  });

  @override
  ViewProfilePageState createState() => ViewProfilePageState();
}

class ViewProfilePageState extends State<ViewProfilePage> {
  late Future<Profile> previousProfile;
  late List<GlobalKey> keyList;

  @override
  void initState() {
    super.initState();
    keyList = [];
    previousProfile = Profile.Init(name: widget.profileName, newProfile: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ViewProfileAppBar(context, widget.profileName, widget.app),
      body: FutureBuilder<Profile>(
        future: previousProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('No Profile Data Found'));
          } else {
            final previousProfile = snapshot.data!;
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
            return ViewProfileContent(context, previousProfile, keyList);
          }
        },
      ),
    );
  }
}
