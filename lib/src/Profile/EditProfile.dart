import 'package:flutter/material.dart';
import 'ProfileUtils.dart';

class EditProfilePage extends StatelessWidget {
  final String profileName;

  const EditProfilePage({required this.profileName, super.key});

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
  Widget build(BuildContext context) {
    return FutureBuilder<ProfileControllers>(
      future: loadProfileControllers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData) {
          return Center(child: Text('No data available'));
        } else {
          final controllers = snapshot.data!;
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
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ...profileEntry(context, 'Education', controllers.eduController, ''),
                  ...profileEntry(context, 'Experience', controllers.expController, ''),
                  ...profileEntry(context, 'Extracurricular', controllers.extraController, ''),
                  ...profileEntry(context, 'Honors', controllers.honController, ''),
                  ...profileEntry(context, 'Projects', controllers.projController, ''),
                  ...profileEntry(context, 'Qualifications / Skills', controllers.qualController, ''),
                  ...profileEntry(context, 'References', controllers.refController, ''),
                ],
              ),
            ),
            bottomNavigationBar: BottomAppBar(
              color: Colors.transparent,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
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
