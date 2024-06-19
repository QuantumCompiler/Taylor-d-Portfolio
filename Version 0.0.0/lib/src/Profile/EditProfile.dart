import 'package:flutter/material.dart';
import 'ProfileUtils.dart';

class EditProfilePage extends StatelessWidget {
  final String profileName;

  const EditProfilePage({required this.profileName, super.key});

  Future<ProfileControllers> loadProfileControllers() async {
    final profileData = await LoadProfileData(profileName);
    final eduController = TextEditingController(text: profileData.education);
    final expController = TextEditingController(text: profileData.experience);
    final qualController = TextEditingController(text: profileData.qualifications);
    final projController = TextEditingController(text: profileData.projects);
    return ProfileControllers(
      eduController: eduController,
      expController: expController,
      qualController: qualController,
      projController: projController,
    );
  }

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
      body: FutureBuilder<ProfileControllers>(
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
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: Text(
                        'Profile: $profileName',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    ...profileEntry(context, 'Education', controllers.eduController, ''),
                    ...profileEntry(context, 'Experience', controllers.expController, ''),
                    ...profileEntry(context, 'Qualifications', controllers.qualController, ''),
                    ...profileEntry(context, 'Projects', controllers.projController, ''),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
