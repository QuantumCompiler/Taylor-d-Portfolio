import 'package:flutter/material.dart';
import 'LoadProfile.dart';
import 'NewProfile.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.6,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              // Create New Profile
              ListTile(
                title: Text('Create New Profile'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => NewProfilePage()));
                },
              ),
              // Load Profiles
              ListTile(
                title: Text('Load Profiles'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => LoadProfilePage()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
