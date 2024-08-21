import 'package:flutter/material.dart';
import '../Context/Profiles/ProfileContentContext.dart';
import '../Globals/Globals.dart';
import '../Utilities/ProfilesUtils.dart';

class ProfileContentPage extends StatelessWidget {
  final Profile profile;
  final String title;
  final ProfileContentType type;
  final List<GlobalKey> keyList;
  final bool viewing;
  const ProfileContentPage({
    super.key,
    required this.profile,
    required this.title,
    required this.type,
    required this.keyList,
    required this.viewing,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ProfileContentAppBar(context, type, profile.name),
      body: ProfileContentEntry(profile: profile, type: type, keyList: keyList, viewing: viewing),
      bottomNavigationBar: !viewing ? ProfileContentBottomAppBar(context, type, profile, keyList) : Container(width: 0, height: 0),
    );
  }
}
