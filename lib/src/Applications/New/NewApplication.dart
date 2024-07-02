import 'package:flutter/material.dart';
import '../Context/NewApplicationContext.dart';
import '../Utilities/ApplicationsUtils.dart';
import '../../Jobs/Utilities/JobUtils.dart';
import '../../Profiles/Utilities/ProfilesUtils.dart';

class NewApplicationPage extends StatefulWidget {
  const NewApplicationPage({super.key});

  @override
  NewApplicationPageState createState() => NewApplicationPageState();
}

class NewApplicationPageState extends State<NewApplicationPage> {
  late Future<List<dynamic>> futureData;
  late ApplicationContent content;

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
          content = ApplicationContent(
            jobs: snapshot.data![0],
            profiles: snapshot.data![1],
            checkedJobs: [],
            checkedProfiles: [],
          );
          return Scaffold(
            appBar: appBar(context),
            body: loadContent(context, content, setState),
            bottomNavigationBar: bottomAppBar(context, content, setState),
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
