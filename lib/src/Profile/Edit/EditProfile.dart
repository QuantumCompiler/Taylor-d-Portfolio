import 'package:flutter/material.dart';
import 'Context/EditProfileContext.dart';
import '../Utilities/ProfileUtils.dart';

class EditProfilePage extends StatelessWidget {
  // Profile Name
  final String profileName;
  const EditProfilePage({required this.profileName, super.key});
  @override
  // Main Widget
  Widget build(BuildContext context) {
    Profile prevProfile = Profile(name: profileName);
    prevProfile.LoadProfileData();
    return Scaffold(
      appBar: appBar(context, prevProfile),
      body: editProfileContent(context, prevProfile),
      bottomNavigationBar: bottomAppBar(context, prevProfile),
    );
  }
}
