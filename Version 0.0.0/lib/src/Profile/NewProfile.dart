import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class NewProfilePage extends StatelessWidget {
  final eduController = TextEditingController();
  final expController = TextEditingController();
  final qualController = TextEditingController();
  final projController = TextEditingController();
  NewProfilePage({super.key});
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
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                child: TextField(
                  controller: eduController,
                  keyboardType: TextInputType.multiline,
                  maxLines: 5,
                  decoration: InputDecoration(hintText: 'Enter educational history here.'),
                ),
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
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                child: TextField(
                  controller: expController,
                  keyboardType: TextInputType.multiline,
                  maxLines: 5,
                  decoration: InputDecoration(hintText: 'Enter experience here.'),
                ),
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
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                child: TextField(
                  controller: qualController,
                  keyboardType: TextInputType.multiline,
                  maxLines: 5,
                  decoration: InputDecoration(hintText: 'Enter qualifications here.'),
                ),
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
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                child: TextField(
                  controller: projController,
                  keyboardType: TextInputType.multiline,
                  maxLines: 5,
                  decoration: InputDecoration(hintText: 'Enter projects here.'),
                ),
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
                                    final dir = await getApplicationDocumentsDirectory();
                                    final profilesDir = Directory('${dir.path}/Profiles');
                                    if (!profilesDir.existsSync()) {
                                      profilesDir.createSync();
                                    } else {
                                      final newProfileDir = Directory('${dir.path}/Profiles/${profileName.text}');
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
                                      } else {}
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
      ),
    );
  }
}
