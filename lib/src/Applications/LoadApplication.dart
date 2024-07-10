import 'dart:io';
import 'package:flutter/material.dart';
import '../Context/LoadApplicationContext.dart';
import '../Utilities/ApplicationsUtils.dart';

class LoadApplicationPage extends StatefulWidget {
  const LoadApplicationPage({super.key});
  @override
  LoadApplicationPageState createState() => LoadApplicationPageState();
}

class LoadApplicationPageState extends State<LoadApplicationPage> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Directory>>(
      future: RetrieveSortedApplications(),
      builder: (BuildContext context, AsyncSnapshot<List<Directory>> snapshot) {
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
