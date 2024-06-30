import 'dart:io';
import 'package:flutter/material.dart';
import 'Context/LoadProfileContext.dart';
import '../Utilities/ProfileUtils.dart';

class LoadProfilePage extends StatefulWidget {
  const LoadProfilePage({super.key});
  @override
  LoadProfilePageState createState() => LoadProfilePageState();
}

class LoadProfilePageState extends State<LoadProfilePage> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Directory>>(
      future: RetrieveSortedProfiles(),
      builder: (BuildContext context, AsyncSnapshot<List<Directory>> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final profiles = snapshot.data ?? [];
          return Scaffold(
            appBar: appBar(context, profiles, setState),
            body: profiles.isEmpty ? Container() : loadProfileContent(context, profiles, setState),
          );
        } else {
          return Scaffold(
            appBar: loadingProfilesAppBar(context),
            body: loadingProfilesContent(),
          );
        }
      },
    );
  }
}
