import 'package:flutter/material.dart';
import '../Globals/ProfilesGlobals.dart';
import '../Context/Profiles/ProfileContext.dart';
import '../Context/Globals/GlobalContext.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GenAppBar(context, profileTitle),
      body: ProfileContent(context),
    );
  }
}
