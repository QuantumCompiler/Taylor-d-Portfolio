import 'package:flutter/material.dart';
import '../Context/Profiles/LoadProfilesContext.dart';
import '../Dashboard/Dashboard.dart';
import '../Profiles/Profiles.dart';
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
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => ProfilePage()), (Route<dynamic> route) => false);
          },
        ),
        actions: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.dashboard),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => Dashboard()), (Route<dynamic> route) => false);
                },
              ),
            ],
          ),
        ],
      ),
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
