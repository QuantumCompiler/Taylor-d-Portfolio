import 'package:flutter/material.dart';
import '../Context/Globals/GlobalContexts.dart';
import '../Context/Profiles/ContentProfilesContext.dart';
import '../Globals/Globals.dart';
import '../Utilities/ProfilesUtils.dart';

class ProfileContentPage extends StatelessWidget {
  final Profile newProfile;
  final String title;
  final ContentType type;
  const ProfileContentPage({
    super.key,
    required this.newProfile,
    required this.title,
    required this.type,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GenAppBarWithDashboard(context, title, 4),
      body: ProfileContentEntry(newProfile: newProfile, contentType: type),
    );
  }
}
