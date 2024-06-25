import 'package:flutter/material.dart';
import '../Globals/Globals.dart';
import 'dart:io';
import 'EditProfile.dart';
import 'ProfileUtils.dart';

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
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {});
                },
              ),
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.dashboard),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                ),
              ],
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
                                return MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: ListTile(
                                    title: Text(profiles[index].path.split('/').last),
                                    trailing: IconButton(
                                      icon: Icon(Icons.delete),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text(
                                                "Delete ${profiles[index].path.split('/').last}?",
                                                style: TextStyle(
                                                  fontSize: appBarTitle,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              content: Text(
                                                "Are you sure you want to delete this profile?",
                                                style: TextStyle(
                                                  fontSize: secondaryTitles,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              actions: <Widget>[
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    ElevatedButton(
                                                      child: Text("Cancel"),
                                                      onPressed: () {
                                                        Navigator.of(context).pop();
                                                      },
                                                    ),
                                                    SizedBox(width: standardSizedBoxWidth),
                                                    ElevatedButton(
                                                      child: Text("Delete"),
                                                      onPressed: () {
                                                        DeleteProfile(profiles[index].path.split('/').last);
                                                        Navigator.of(context).pop();
                                                        setState(() {});
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditProfilePage(profileName: profiles[index].path.split('/').last),
                                        ),
                                      ).then(
                                        (_) {
                                          setState(() {});
                                        },
                                      );
                                    },
                                  ),
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
