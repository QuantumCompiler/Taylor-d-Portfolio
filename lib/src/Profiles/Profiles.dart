import 'package:flutter/material.dart';
import '../Context/Profiles/ProfileContext.dart';
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
    if (mounted) {
      setState(() {
        profiles = updatedProfiles;
      });
    }
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
      appBar: ProfileAppBar(context, profiles),
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
