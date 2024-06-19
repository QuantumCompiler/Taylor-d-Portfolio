import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../Themes/Themes.dart';
import 'EditProfile.dart';

class LoadProfilePage extends StatelessWidget {
  const LoadProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            FutureBuilder(
              future: getApplicationDocumentsDirectory(),
              builder: (BuildContext context, AsyncSnapshot<Directory> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  final profileDirectory = Directory('${snapshot.data?.path}/Profiles');
                  final profiles = profileDirectory.listSync().whereType<Directory>().map((item) => item).toList();
                  profiles.sort((a, b) => a.path.split('/').last.compareTo(b.path.split('/').last));
                  if (profiles.isEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Center(
                          child: Text(
                            'No Profiles Present',
                            style: TextStyle(
                              color: themeTextColor(context),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Center(
                          child: Text(
                            'Generated Profiles',
                            style: TextStyle(
                              color: themeTextColor(context),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.75,
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: ClampingScrollPhysics(),
                            itemCount: profiles.length,
                            itemBuilder: (BuildContext context, int index) {
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
                    );
                  }
                } else {
                  return CircularProgressIndicator();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
