import 'package:flutter/material.dart';
import '../Globals/Globals.dart';
import 'dart:io';
import 'EditProfile.dart';
import 'ProfileUtils.dart';

class LoadProfilePage extends StatelessWidget {
  const LoadProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Directory>>(
      future: RetrieveSortedProfiles(),
      builder: (BuildContext context, AsyncSnapshot<List<Directory>> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final profiles = snapshot.data ?? [];
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              title: Text(
                profiles.isEmpty ? 'No Profiles' : 'Load Profiles',
                style: TextStyle(
                  fontSize: appBarTitle,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: profiles.isEmpty
                ? Container()
                : Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * profileTileContainerWidth,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(height: standardSizedBoxHeight),
                          Expanded(
                            child: ListView.builder(
                              itemCount: profiles.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text(profiles[index].path.split('/').last),
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfilePage(profileName: profiles[index].path.split('/').last)));
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text('Loading Profiles...'),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
