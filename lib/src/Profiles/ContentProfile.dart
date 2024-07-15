import 'package:flutter/material.dart';
import '../Context/Globals/GlobalContext.dart';
import '../Context/Profiles/ContentProfilesContext.dart';
import '../Globals/Globals.dart';
import '../Utilities/ProfilesUtils.dart';

class ProfileContentPage extends StatelessWidget {
  final Profile profile;
  final String title;
  final ContentType type;
  final List<GlobalKey> keyList;
  const ProfileContentPage({
    super.key,
    required this.profile,
    required this.title,
    required this.type,
    required this.keyList,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GenAppBarWithDashboard(context, title, 4),
      body: ProfileContentEntry(profile: profile, contentType: type, keyList: keyList),
      bottomNavigationBar: ProfileContentBottomAppBar(context, type, profile, keyList),
    );
  }
}
