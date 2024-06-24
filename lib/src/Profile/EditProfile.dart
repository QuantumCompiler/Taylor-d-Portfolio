import 'package:flutter/material.dart';
import 'ProfileUtils.dart';

/*  EditProfilePage - Page for editing an existing profile
      Constructor - profileName: Name of the profile to edit
      Main Widget - FutureBuilder
        Future: loadProfileControllers
        Builder - Context, AsyncSnapshot<ProfileControllers>
          If Connection State is Waiting
            Center - CircularProgressIndicator
          Else If Error
            Center - Text: 'Error: ${snapshot.error}'
          Else If No Data
            Center - Text: 'No data available'
          Else
            Scaffold
              App Bar
                Leading: IconButton
                  Icon: Arrow Back
                  On Press: Pop Context
                Title: profileName
              Body - SingleChildScrollView
                Column
                  Profile Entry - Education
                    Title: 'Education'
                    Controller: eduController
                    Hint Text: ''
                  Profile Entry - Experience
                    Title: 'Experience'
                    Controller: expController
                    Hint Text: ''
                  Profile Entry - Extracurricular
                    Title: 'Extracurricular'
                    Controller: extController
                    Hint Text: ''
                  Profile Entry - Honors
                    Title: 'Honors'
                    Controller: honController
                    Hint Text: ''
                  Profile Entry - Projects
                    Title: 'Projects'
                    Controller: projController
                    Hint Text: ''
                  Profile Entry - Qualifications
                    Title: 'Qualifications / Skills'
                    Controller: qualController
                    Hint Text: ''
                  Profile Entry - References
                    Title: 'References'
                    Controller: refController
                    Hint Text: ''
              Bottom Navigation Bar
                Row
                  Save - ElevatedButton
                    On Press: 
                  Set As Primary - ElevatedButton
                    On Press: 
                  Cancel - ElevatedButton
                    On Press: 
*/
class EditProfilePage extends StatelessWidget {
  // Profile Name
  final String profileName;
  const EditProfilePage({required this.profileName, super.key});
  /*  loadProfileControllers - Load profile data into controllers
        Input:
          None
        Algorithm:
          * Load profile data
        Output:
          ProfileControllers
  */
  Future<ProfileControllers> loadProfileControllers() async {
    final profileData = await LoadProfileData(profileName);
    final eduController = TextEditingController(text: profileData.education);
    final expController = TextEditingController(text: profileData.experience);
    final extController = TextEditingController(text: profileData.extracurricular);
    final honController = TextEditingController(text: profileData.honors);
    final projController = TextEditingController(text: profileData.projects);
    final qualController = TextEditingController(text: profileData.qualifications);
    final refController = TextEditingController(text: profileData.references);
    return ProfileControllers(
      eduController: eduController,
      expController: expController,
      extraController: extController,
      honController: honController,
      projController: projController,
      qualController: qualController,
      refController: refController,
    );
  }

  @override
  // Main Widget
  Widget build(BuildContext context) {
    // Future Builder
    return FutureBuilder<ProfileControllers>(
      future: loadProfileControllers(),
      builder: (context, snapshot) {
        // If Connection State is Waiting
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        // Else If Error
        else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        // Else If No Data
        else if (!snapshot.hasData) {
          return Center(child: Text('No data available'));
        }
        // Else
        else {
          final controllers = snapshot.data!;
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
                profileName,
                style: TextStyle(
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
                children: [
                  // Education
                  ...profileEntry(context, 'Education', controllers.eduController, ''),
                  // Experience
                  ...profileEntry(context, 'Experience', controllers.expController, ''),
                  // Extracurricular
                  ...profileEntry(context, 'Extracurricular', controllers.extraController, ''),
                  // Honors
                  ...profileEntry(context, 'Honors', controllers.honController, ''),
                  // Projects
                  ...profileEntry(context, 'Projects', controllers.projController, ''),
                  // Qualifications
                  ...profileEntry(context, 'Qualifications / Skills', controllers.qualController, ''),
                  // References
                  ...profileEntry(context, 'References', controllers.refController, ''),
                ],
              ),
            ),
            // Bottom Navigation Bar
            bottomNavigationBar: BottomAppBar(
              color: Colors.transparent,
              // Row
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Save Button
                  ElevatedButton(
                    onPressed: () => {},
                    child: Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  // Set As Primary Button
                  ElevatedButton(
                    onPressed: () => {},
                    child: Text(
                      'Set As Primary',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  // Cancel Button
                  ElevatedButton(
                    onPressed: () => {},
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
