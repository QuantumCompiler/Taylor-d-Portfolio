import 'package:flutter/material.dart';
import '../Themes/Themes.dart';
import 'ProfileUtils.dart';

/*  NewProfilePage - Page for creating a new profile
      Constructor - key: Key for widget identification
      Main Widget - Scaffold
        App Bar - Title: 'Create New Profile'
        Body - SingleChildScrollView
          Column
            Profile Entry - Education
              Title: 'Education'
              Controller: eduController
              Hint Text: 'Enter education here.'
            Profile Entry - Experience
              Title: 'Experience'
              Controller: expController
              Hint Text: 'Enter experience here.'
            Profile Entry - Extracurricular
              Title: 'Extracurricular'
              Controller: extController
              Hint Text: 'Enter extracurricular here.'
            Profile Entry - Honors
              Title: 'Honors'
              Controller: honController
              Hint Text: 'Enter honors here.'
            Profile Entry - Projects
              Title: 'Projects'
              Controller: projController
              Hint Text: 'Enter projects here.'
            Profile Entry - Qualifications
              Title: 'Qualifications / Skills'
              Controller: qualController
              Hint Text: 'Enter qualifications / skills here.'
            Profile Entry - References
              Title: 'References'
              Controller: refController
              Hint Text: 'Enter references here.'
        Bottom Navigation Bar
          Row
            Save Profile - ElevatedButton
              On Press: Show Dialog
                Title: 'Enter Name Of Current Profile'
                Content: TextField
                  Controller: profileName
                  Hint Text: 'Profile Name'
                Actions
                  Row
                    Cancel - ElevatedButton
                      On Press: Pop Dialog
                    Save - ElevatedButton
                      On Press: Create New Profile
*/
class NewProfilePage extends StatelessWidget {
  // Controllers
  final eduController = TextEditingController();
  final expController = TextEditingController();
  final extController = TextEditingController();
  final honController = TextEditingController();
  final profNameController = TextEditingController();
  final projController = TextEditingController();
  final qualController = TextEditingController();
  final refController = TextEditingController();
  NewProfilePage({super.key});
  @override
  // Main Widget
  Widget build(BuildContext context) {
    ProfileControllers controllers;
    controllers = ProfileControllers(
        eduController: eduController,
        expController: expController,
        extController: extController,
        honController: honController,
        profNameController: profNameController,
        projController: projController,
        qualController: qualController,
        refController: refController);
    // Scaffold
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
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
          'Create New Profile',
          style: TextStyle(
            color: themeTextColor(context),
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // Body
      body: SingleChildScrollView(
        // Column
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            // Education
            ...ProfileEntry(context, 'Education', eduController, 'Enter education here.'),
            // Experience
            ...ProfileEntry(context, 'Experience', expController, 'Enter experience here.'),
            // Experience
            ...ProfileEntry(context, 'Extracurricular', extController, 'Enter extracurricular here'),
            // Honors
            ...ProfileEntry(context, 'Honors', honController, 'Enter honors here'),
            // Projects
            ...ProfileEntry(context, 'Projects', projController, 'Enter projects here.'),
            // Qualifications
            ...ProfileEntry(context, 'Qualifications / Skills', qualController, 'Enter qualifications / skills here.'),
            // References
            ...ProfileEntry(context, 'References', refController, 'Enter references here.'),
          ],
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Save Profile
            ElevatedButton(
              onPressed: () async {
                // Show Dialog
                await showDialog(
                  context: context,
                  builder: (context) {
                    // Alert Dialog
                    return AlertDialog(
                      title: Text(
                        'Enter Name Of Current Profile',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: TextField(
                        controller: profNameController,
                        decoration: InputDecoration(hintText: "Profile Name"),
                      ),
                      actions: <Widget>[
                        // Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            // Cancel Button
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
                            // Save Buttons
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
                                CreateNewProfile(context, controllers);
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
