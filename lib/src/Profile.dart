import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  bool showNewProfile = false;
  bool showProfileList = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            if (!showNewProfile && !showProfileList) {
              Navigator.pushNamed(context, '/dashboard');
            } else {
              Navigator.pushNamed(context, '/profile');
            }
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.height * 0.05),
        child: !showNewProfile && showProfileList
            ? LoadProfiles(context, setState, () => showProfileList = false)
            : showNewProfile && !showProfileList
                ? NewProfileForm(context, setState, () => showNewProfile = false)
                : BuildProfileCards(),
      ),
    );
  }

  Widget BuildProfileCards() {
    return Column(
      children: [
        LoadProfileCard(
          key: UniqueKey(),
          onLoadProfile: () {
            setState(() {
              showProfileList = true;
            });
          },
        ),
        NewProfileCard(
          key: UniqueKey(),
          onCreateNewProfile: () {
            setState(() {
              showNewProfile = true;
            });
          },
        ),
      ],
    );
  }
}

class LoadProfileCard extends StatelessWidget {
  final VoidCallback onLoadProfile;
  const LoadProfileCard({required Key key, required this.onLoadProfile}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
        minWidth: MediaQuery.of(context).size.width,
      ),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Center(
                child: Text(
                  'Load Profile',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              Center(
                child: SizedBox(
                  width: 250,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: onLoadProfile,
                    child: Text(
                      'Load Previous Profiles',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget LoadProfiles(BuildContext context, Function state, Function toggleShow) {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        FutureBuilder(
          future: getApplicationCacheDirectory(),
          builder: (BuildContext context, AsyncSnapshot<Directory> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              final profiles = snapshot.data?.listSync().where((item) => item is Directory).map((item) => item as Directory).toList() ?? [];
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
                          color: Colors.black,
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
                    ListView.builder(
                      shrinkWrap: true,
                      physics: ClampingScrollPhysics(), // This allows the ListView to be scrollable inside the SingleChildScrollView
                      itemCount: profiles.length,
                      itemBuilder: (BuildContext context, int index) {
                        return ListTile(
                          title: Text(profiles[index].path.split('/').last),
                          onTap: () => {},
                        );
                      },
                    )
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
  );
}

class NewProfileCard extends StatelessWidget {
  final VoidCallback onCreateNewProfile;
  const NewProfileCard({required Key key, required this.onCreateNewProfile}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
        minWidth: MediaQuery.of(context).size.width,
      ),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Center(
                child: Text(
                  'New Profile',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              Center(
                child: SizedBox(
                  width: 250,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: onCreateNewProfile,
                    child: Text(
                      'Create New Profile',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget NewProfileForm(BuildContext context, Function state, Function toggleShow) {
  final eduController = TextEditingController();
  final expController = TextEditingController();
  final qualController = TextEditingController();
  final projController = TextEditingController();
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        // Education
        Center(
          child: Text(
            'Education',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Center(
          child: TextField(
            controller: eduController,
            keyboardType: TextInputType.multiline,
            maxLines: 5,
          ),
        ),
        SizedBox(height: 20),
        // Experience
        Center(
          child: Text(
            'Experience',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Center(
          child: TextField(
            controller: expController,
            keyboardType: TextInputType.multiline,
            maxLines: 5,
          ),
        ),
        SizedBox(height: 20),
        // Qualifications
        Center(
          child: Text(
            'Qualifications / Skills',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Center(
          child: TextField(
            controller: qualController,
            keyboardType: TextInputType.multiline,
            maxLines: 5,
          ),
        ),
        SizedBox(height: 20),
        // Projects
        Center(
          child: Text(
            'Projects',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Center(
          child: TextField(
            controller: projController,
            keyboardType: TextInputType.multiline,
            maxLines: 5,
          ),
        ),
        SizedBox(height: 20),
        // Buttons
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Save Profile
            ElevatedButton(
              onPressed: () async {
                final profileName = TextEditingController();
                await showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('Enter Name Of Current Profile'),
                      content: TextField(
                        controller: profileName,
                        decoration: InputDecoration(hintText: "Profile Name"),
                      ),
                      actions: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            ElevatedButton(
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            SizedBox(width: 20),
                            ElevatedButton(
                              child: Text(
                                'Save',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () async {
                                final dir = await getApplicationCacheDirectory();
                                final newProfileDir = Directory('${dir.path}/${profileName.text}');
                                if (!newProfileDir.existsSync()) {
                                  newProfileDir.createSync();
                                  final eduFile = File('${newProfileDir.path}/education.txt');
                                  final expFile = File('${newProfileDir.path}/experience.txt');
                                  final qualFile = File('${newProfileDir.path}/qualifications.txt');
                                  final projFile = File('${newProfileDir.path}/proj.txt');
                                  await eduFile.writeAsString(eduController.text);
                                  await expFile.writeAsString(expController.text);
                                  await qualFile.writeAsString(qualController.text);
                                  await projFile.writeAsString(projController.text);
                                }
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text(
                'Save Profile',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
      ],
    ),
  );
}
