import 'package:flutter/material.dart';
import 'package:taylord_portfolio/src/Dashboard/Dashboard.dart';
// import '../Globals/ProfilesGlobals.dart';
import '../Context/Profiles/ProfileContext.dart';
import '../Context/Globals/GlobalContext.dart';
import '../Utilities/GlobalUtils.dart';
import '../Utilities/ProfilesUtils.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  Future<List<Profile>> profilesFuture = RetrieveSortedProfiles();
  List<Profile> profiles = [];

  Future<void> _refreshProfiles() async {
    List<Profile> updatedProfiles = await RetrieveSortedProfiles();
    setState(() {
      profiles = updatedProfiles;
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshProfiles();
  }

  @override
  Widget build(BuildContext context) {
    _refreshProfiles();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_outlined),
          onPressed: () {
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => Dashboard()), (Route<dynamic> route) => false);
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
        future: profilesFuture,
        builder: (context, AsyncSnapshot<List<Profile>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('No Data'));
          } else {
            profiles = snapshot.data!;
            return ProfileContent(context, profiles, setState);
          }
        },
      ),
    );
  }
}
