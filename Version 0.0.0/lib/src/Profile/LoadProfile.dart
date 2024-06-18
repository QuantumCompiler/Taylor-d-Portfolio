import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:taylord_resume/src/Profile/EditProfile.dart';
import 'dart:io';

import 'package:taylord_resume/src/Profile/ProfileFunctions.dart';

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
                  final profiles = profileDirectory.listSync().where((item) => item is Directory).map((item) => item as Directory).toList();
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
                              color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white,
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
                              color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white,
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
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text(
                                          profiles[index].path.split('/').last,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        content: Text(
                                          'Select The Action You Would Like To Perform',
                                          textAlign: TextAlign.center,
                                        ),
                                        actions: <Widget>[
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: <Widget>[
                                              ElevatedButton(
                                                onPressed: () => {},
                                                child: Text(
                                                  'Delete ${profiles[index].path.split('/').last}',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 20),
                                              ElevatedButton(
                                                onPressed: () => {},
                                                child: Text(
                                                  'Set ${profiles[index].path.split('/').last} As Primary',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 20),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  Navigator.of(context).pop();
                                                  final profileName = profiles[index].path.split('/').last;
                                                  final profileDirectory = Directory('${snapshot.data?.path}/Profiles/$profileName');
                                                  final educationFile = File('${profileDirectory.path}/education.txt');
                                                  final experienceFile = File('${profileDirectory.path}/experience.txt');
                                                  final qualificationsFile = File('${profileDirectory.path}/qualifications.txt');
                                                  final projectsFile = File('${profileDirectory.path}/projects.txt');
                                                  final education = await educationFile.readAsString();
                                                  final experience = await experienceFile.readAsString();
                                                  final qualifications = await qualificationsFile.readAsString();
                                                  final projects = await projectsFile.readAsString();
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => EditProfilePage(
                                                        key: Key('editProfilePage'),
                                                        education: education,
                                                        experience: experience,
                                                        qualifications: qualifications,
                                                        projects: projects,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Text(
                                                  'Edit ${profiles[index].path.split('/').last}',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    },
                                  );
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
