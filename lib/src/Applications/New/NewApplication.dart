import 'package:flutter/material.dart';
import 'Context/NewApplicationContext.dart';
import '../Content/ApplicationContent.dart';
import '../../Jobs/Utilities/JobUtils.dart';
import '../../Profiles/Utilities/ProfilesUtils.dart';

class NewApplicationPage extends StatefulWidget {
  const NewApplicationPage({super.key});

  @override
  NewApplicationPageState createState() => NewApplicationPageState();
}

class NewApplicationPageState extends State<NewApplicationPage> {
  late Future<List<dynamic>> futureData;

  @override
  void initState() {
    super.initState();
    futureData = Future.wait([RetrieveSortedJobs(), RetrieveSortedProfiles()]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: futureData,
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: appBar(context),
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: appBar(context),
          );
        } else if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          final jobs = snapshot.data![0];
          final profiles = snapshot.data![1];
          return Scaffold(
            appBar: appBar(context),
            body: ApplicationContentList(jobs: jobs, profiles: profiles),
            bottomNavigationBar: bottomAppBar(context),
          );
        } else {
          return Scaffold(
            appBar: appBar(context),
          );
        }
      },
    );
  }
}
