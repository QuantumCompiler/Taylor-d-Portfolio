import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../Themes/Themes.dart';
import 'EditProfile.dart';

/*  LoadProfilePage - Page for loading existing profiles
      Constructor - key: Key for widget identification
      Main Widget - FutureBuilder
        Future: getApplicationDocumentsDirectory
        Builder - Context, AsyncSnapshot<Directory>
          If Connection State is Done
            Profile Directory - Directory
*/
class LoadProfilePage extends StatelessWidget {
  const LoadProfilePage({super.key});
  @override
  // Main Widget
  Widget build(BuildContext context) {
    // Future Builder
    return FutureBuilder(
      // Application Directory
      future: getApplicationDocumentsDirectory(),
      builder: (BuildContext context, AsyncSnapshot<Directory> snapshot) {
        // If Connection State is Done
        if (snapshot.connectionState == ConnectionState.done) {
          // Profile Directory
          final profileDirectory = Directory('${snapshot.data?.path}/Profiles');
          // Profiles
          final profiles = profileDirectory.listSync().whereType<Directory>().map((item) => item).toList();
          profiles.sort((a, b) => a.path.split('/').last.compareTo(b.path.split('/').last));
          // Scaffold
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              title: Text(
                profiles.isEmpty ? 'No Profiles' : 'Load Profiles',
                style: TextStyle(
                  color: themeTextColor(context),
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Body
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  // If Profiles is Empty
                  if (profiles.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        // Container
                        Center(
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.6,
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: ClampingScrollPhysics(),
                              itemCount: profiles.length,
                              itemBuilder: (BuildContext context, int index) {
                                // ListTile
                                return ListTile(
                                  title: Text(profiles[index].path.split('/').last),
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfilePage(profileName: profiles[index].path.split('/').last)));
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        }
        // Else
        else {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              title: Text('Loading...'),
            ),
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
