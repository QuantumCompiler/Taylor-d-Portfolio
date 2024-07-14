import 'package:flutter/material.dart';
import '../Context/Applications/LoadApplicationContext.dart';
import '../Utilities/ApplicationsUtils.dart';
import '../Utilities/GlobalUtils.dart';

class LoadApplicationPage extends StatefulWidget {
  const LoadApplicationPage({super.key});
  @override
  LoadApplicationPageState createState() => LoadApplicationPageState();
}

class LoadApplicationPageState extends State<LoadApplicationPage> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Application>>(
      future: RetrieveSortedApplications(),
      builder: (BuildContext context, AsyncSnapshot<List<Application>> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final apps = snapshot.data ?? [];
          return Scaffold(
            appBar: appBar(context, apps, setState),
            body: loadAppsContent(context, apps, setState),
          );
        } else {
          return Scaffold();
        }
      },
    );
  }
}
