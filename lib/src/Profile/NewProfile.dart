import 'package:flutter/material.dart';
import '../Themes/Themes.dart';
import 'ProfileUtils.dart';

class NewProfilePage extends StatelessWidget {
  final profileName = TextEditingController();
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
        title: Text(
          'Create New Profile',
          style: TextStyle(
            color: themeTextColor(context),
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            // Education
            ...profileEntry(context, 'Education', eduController, 'Enter education here.'),
            // Experience
            ...profileEntry(context, 'Experience', expController, 'Enter experience here.'),
            // Qualifications
            ...profileEntry(context, 'Qualifications / Skills', qualController, 'Enter qualifications / skills here.'),
            // Projects
            ...profileEntry(context, 'Projects', projController, 'Enter projects here.'),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Save Profile
            ElevatedButton(
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text(
                        'Enter Name Of Current Profile',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                                createNewProfile(context, profileName, eduController, expController, qualController, projController);
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
      ),
    );
  }
}
