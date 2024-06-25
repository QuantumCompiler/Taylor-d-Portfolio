import 'package:flutter/material.dart';
import '../Globals/Globals.dart';
import 'ProfileUtils.dart';

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
              Navigator.of(context).pop();
            },
          ),
        ],
        title: Text(
          prevProfile.name,
          style: TextStyle(
            fontSize: appBarTitle,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Profile Name
            ...ProfileEntry(context, profileNameTitle, prevProfile.nameCont, '', lines: 1),
            // Education
            ...ProfileEntry(context, profileEduTitle, prevProfile.eduCont, ''),
            // Experience
            ...ProfileEntry(context, profileExpTitle, prevProfile.expCont, ''),
            // Extracurricular
            ...ProfileEntry(context, profileExtTitle, prevProfile.extCont, ''),
            // Honors
            ...ProfileEntry(context, profileHonTitle, prevProfile.honCont, ''),
            // Projects
            ...ProfileEntry(context, profileProjTitle, prevProfile.projCont, ''),
            // References
            ...ProfileEntry(context, profileRefTitle, prevProfile.refCont, ''),
            // Skills
            ...ProfileEntry(context, profileSkillsTitle, prevProfile.skillsCont, ''),
          ],
        ),
      ),
    );
    // Future Builder
    // return FutureBuilder<Profile>(
    //   future: prevProfile.getProf(profileName),
    //   builder: (context, snapshot) {
    //     // If Connection State is Waiting
    //     if (snapshot.connectionState == ConnectionState.waiting) {
    //       return Center(child: CircularProgressIndicator());
    //     }
    //     // Else If Error
    //     else if (snapshot.hasError) {
    //       return Center(child: Text('Error: ${snapshot.error}'));
    //     }
    //     // Else If No Data
    //     else if (!snapshot.hasData) {
    //       return Center(child: Text('No data available'));
    //     }
    //     // Else
    //     else {
    //       final controllers = snapshot.data!;
    //       // Scaffold
    //       return Scaffold(
    //         appBar: AppBar(
    //           leading: IconButton(
    //             icon: Icon(Icons.arrow_back),
    //             onPressed: () {
    //               Navigator.of(context).pop();
    //             },
    //           ),
    //           actions: <Widget>[
    //             IconButton(
    //               icon: Icon(Icons.dashboard),
    //               onPressed: () {
    //                 Navigator.of(context).pop();
    //                 Navigator.of(context).pop();
    //                 Navigator.of(context).pop();
    //                 Navigator.of(context).pop();
    //               },
    //             ),
    //           ],
    //           title: Text(
    //             profileName,
    //             style: TextStyle(
    //               fontSize: appBarTitle,
    //               fontWeight: FontWeight.bold,
    //             ),
    //           ),
    //         ),
    //         // Body
    //         body: SingleChildScrollView(
    //           child: Column(
    //             crossAxisAlignment: CrossAxisAlignment.center,
    //             mainAxisAlignment: MainAxisAlignment.start,
    //             children: [
    //               // Profile Name
    //               // Education
    //               // Experience
    //               // Extracurricular
    //               // Honors
    //               // Projects
    //               // Qualifications
    //               // References
    //             ],
    //           ),
    //         ),
    //         // Bottom Navigation Bar
    //         bottomNavigationBar: BottomAppBar(
    //             // color: Colors.transparent,
    //             // // Row
    //             // child: Row(
    //             //   crossAxisAlignment: CrossAxisAlignment.center,
    //             //   mainAxisAlignment: MainAxisAlignment.center,
    //             //   children: <Widget>[
    //             //     // Save Button
    //             //     ElevatedButton(
    //             //       onPressed: () {
    //             //         OverWriteProfile(context, controllers);
    //             //       },
    //             //       child: Text(
    //             //         'Save',
    //             //         style: TextStyle(
    //             //           color: Colors.black,
    //             //           fontSize: 16.0,
    //             //           fontWeight: FontWeight.bold,
    //             //         ),
    //             //       ),
    //             //     ),
    //             //     SizedBox(width: 20),
    //             //     // Set As Primary Button
    //             //     ElevatedButton(
    //             //       onPressed: () => {},
    //             //       child: Text(
    //             //         'Set As Primary',
    //             //         style: TextStyle(
    //             //           color: Colors.black,
    //             //           fontSize: 16.0,
    //             //           fontWeight: FontWeight.bold,
    //             //         ),
    //             //       ),
    //             //     ),
    //             //     SizedBox(width: 20),
    //             //     // Cancel Button
    //             //     ElevatedButton(
    //             //       onPressed: () {
    //             //         Navigator.of(context).pop();
    //             //       },
    //             //       child: Text(
    //             //         'Cancel',
    //             //         style: TextStyle(
    //             //           color: Colors.black,
    //             //           fontSize: 16.0,
    //             //           fontWeight: FontWeight.bold,
    //             //         ),
    //             //       ),
    //             //     ),
    //             //   ],
    //             // ),
    //             ),
    //       );
    //     }
    //   },
    // );
  }
}
