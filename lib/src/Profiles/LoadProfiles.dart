import 'package:flutter/material.dart';
import '../Context/Globals/GlobalContexts.dart';
import '../Context/Profiles/LoadProfilesContext.dart';
import '../Globals/ProfilesGlobals.dart';
import '../Utilities/GlobalUtils.dart';
import '../Utilities/ProfilesUtils.dart';

class LoadProfilePage extends StatefulWidget {
  const LoadProfilePage({super.key});
  @override
  LoadProfilePageState createState() => LoadProfilePageState();
}

class LoadProfilePageState extends State<LoadProfilePage> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: RetrieveSortedProfiles(),
      builder: (BuildContext context, AsyncSnapshot<List<Profile>> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final profs = snapshot.data ?? [];
          return Scaffold(
            appBar: GenAppBarWithDashboardObject(context, loadProfilesTitle, profilesEmptyTitle, 3, profs, setState),
            body: LoadProfileContent(context, profs, setState),
          );
        } else {
          return Scaffold();
        }
      },
    );
  }
}
