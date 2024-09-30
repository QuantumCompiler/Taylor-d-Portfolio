import 'package:flutter/material.dart';
import '../Context/Globals/GlobalContext.dart';
import '../Context/Profiles/EditProfilesContext.dart';
import '../Utilities/ProfilesUtils.dart';

class EditProfilePage extends StatefulWidget {
  late String profileName;
  final bool backToProfile;
  EditProfilePage({
    super.key,
    required this.profileName,
    this.backToProfile = true,
  });

  @override
  EditProfilePageState createState() => EditProfilePageState();
}

class EditProfilePageState extends State<EditProfilePage> {
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
      appBar: EditProfileAppBar(context, widget.profileName, widget.backToProfile),
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
            return EditProfileContent(context, previousProfile, keyList, widget.backToProfile);
          }
        },
      ),
      bottomNavigationBar: FutureBuilder<Profile>(
        future: previousProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            return BottomNav(context);
          } else {
            return Container();
          }
        },
      ),
    );
  }
}
