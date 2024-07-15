import 'package:flutter/material.dart';
import '../Context/Globals/GlobalContexts.dart';
import '../Context/Profiles/ContentProfilesContext.dart';
// import '../Globals/ProfilesGlobals.dart';
import '../Utilities/ProfilesUtils.dart';

class ProfileContentPage extends StatelessWidget {
  final Profile newProfile;
  final String title;
  const ProfileContentPage({super.key, required this.newProfile, required this.title});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GenAppBarWithDashboard(context, title, 4),
      body: ContentEntries(newProfile: newProfile),
    );
  }
}
