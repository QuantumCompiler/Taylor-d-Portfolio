import 'package:flutter/material.dart';
import '../Context/NewApplicationContext.dart';
import '../Utilities/ApplicationsUtils.dart';
import '../Utilities/JobUtils.dart';
import '../Utilities/ProfilesUtils.dart';

class NewApplicationPage extends StatefulWidget {
  const NewApplicationPage({super.key});

  @override
  NewApplicationPageState createState() => NewApplicationPageState();
}

class NewApplicationPageState extends State<NewApplicationPage> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([RetrieveSortedJobs(), RetrieveSortedProfiles()]),
      builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final jobs = snapshot.data?[0] ?? [];
          final profiles = snapshot.data?[1] ?? [];
          ApplicationContent content = ApplicationContent(
            jobs: jobs,
            profiles: profiles,
          );
          return Scaffold(
            appBar: appBar(context, setState),
            body: loadApplicationContent(context, content, setState),
            bottomNavigationBar: bottomAppBar(context, content, setState),
          );
        } else {
          return Scaffold(
            appBar: appBar(context, setState),
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
