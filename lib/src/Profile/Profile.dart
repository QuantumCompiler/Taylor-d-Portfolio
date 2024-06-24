import 'package:flutter/material.dart';

/*  ProfilePage - Main page for profile management
      Constructor - key: Key for widget identification
      Main Widget - Scaffold
        App Bar - Title: 'Profile'
        Body - Centered Column
          Create New Profile - ListTile
            Title: 'Create New Profile'
            On Tap: Navigate to NewProfilePage
          Load Profiles - ListTile
            Title: 'Load Profiles'
            On Tap: Navigate to LoadProfilePage
*/
class ProfilePage extends StatelessWidget {
  // Constructor
  const ProfilePage({super.key});
  @override
  // Main Widget
  Widget build(BuildContext context) {
    // Scaffold
    return Scaffold(
      // App Bar
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Profile',
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // Body
      body: Center(
        // Container
        child: Container(
          width: MediaQuery.of(context).size.width * 0.6,
          // Column
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              // Create New Profile
              ListTile(
                title: Text('Create New Profile'),
                onTap: () {
                  // Navigator.push(context, MaterialPageRoute(builder: (context) => NewProfilePage()));
                },
              ),
              // Load Profiles
              ListTile(
                title: Text('Load Profiles'),
                onTap: () {
                  // Navigator.push(context, MaterialPageRoute(builder: (context) => LoadProfilePage()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
