import 'package:flutter/material.dart';
import '../Context/Applications/ApplicationsContext.dart';
import '../Context/Globals/GlobalContext.dart';
import '../Utilities/GlobalUtils.dart';
import '../Utilities/ApplicationsUtils.dart';
import '../Utilities/JobUtils.dart';
import '../Utilities/ProfilesUtils.dart';

class ApplicationsPage extends StatefulWidget {
  const ApplicationsPage({super.key});
  @override
  ApplicationsPageState createState() => ApplicationsPageState();
}

class ApplicationsPageState extends State<ApplicationsPage> {
  Future<List<dynamic>> contentFuture = RetrieveAllContent();
  List<Application> apps = [];
  List<Job> jobs = [];
  List<Profile> profiles = [];

  Future<void> _refreshApps() async {
    List<Application> updatedApps = await RetrieveSortedApplications();
    if (mounted) {
      setState(() {
        apps = updatedApps;
      });
    }
  }

  Future<void> _refreshJobs() async {
    List<Job> updatedJobs = await RetrieveSortedJobs();
    if (mounted) {
      setState(() {
        jobs = updatedJobs;
      });
    }
  }

  Future<void> _refreshProfiles() async {
    List<Profile> updatedProfiles = await RetrieveSortedProfiles();
    if (mounted) {
      setState(() {
        profiles = updatedProfiles;
      });
    }
  }

  Future<void> _refreshContent() async {
    await _refreshApps();
    await _refreshJobs();
    await _refreshProfiles();
  }

  @override
  void initState() {
    super.initState();
    _refreshContent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ApplicationsAppBar(context),
      body: FutureBuilder(
        future: contentFuture,
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('No Data'));
          } else {
            apps = snapshot.data![0];
            jobs = snapshot.data![1];
            profiles = snapshot.data![2];
            return ApplicationsContent(context, apps, jobs, profiles, setState);
          }
        },
      ),
      bottomNavigationBar: FutureBuilder<dynamic>(
        future: contentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            jobs = snapshot.data![1];
            profiles = snapshot.data![2];
            return BottomNav(context);
          } else {
            return BottomAppBar();
          }
        },
      ),
    );
  }
}
