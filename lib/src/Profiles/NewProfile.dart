import 'package:flutter/material.dart';
import '../Context/Globals/GlobalContexts.dart';
import '../Globals/ProfilesGlobals.dart';
import '../Context/Profiles/NewProfileContext.dart';
import '../Utilities/ProfilesUtils.dart';

class NewProfilePage extends StatelessWidget {
  const NewProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    Profile newProfile = Profile();
    return Scaffold(
      appBar: GenAppBarWithDashboard(context, createNewProfilePrompt, 3),
      body: newProfileContent(context, newProfile),
      bottomNavigationBar: bottomAppBar(context, newProfile),
    );
  }
}
