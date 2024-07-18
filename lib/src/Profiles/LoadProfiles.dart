import 'package:flutter/material.dart';
import '../Context/Globals/GlobalContext.dart';
import '../Context/Profiles/LoadProfilesContext.dart';
import '../Utilities/GlobalUtils.dart';
import '../Utilities/ProfilesUtils.dart';

class LoadProfilePage extends StatefulWidget {
  const LoadProfilePage({super.key});

  @override
  LoadProfilePageState createState() => LoadProfilePageState();
}

class LoadProfilePageState extends State<LoadProfilePage> {
  late Future<List<Profile>> profiles;

  @override
  void initState() {
    super.initState();
    profiles = RetrieveSortedProfiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GenAppBarWithDashboard(context, "Load Previous Profiles", 3),
      body: FutureBuilder<List<Profile>>(
        future: profiles,
        builder: (context, AsyncSnapshot<List<Profile>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('No profiles found'));
          } else {
            final profiles = snapshot.data!;
            return LoadProfileContent(context, profiles, setState);
          }
        },
      ),
    );
  }
}
