import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import '../Themes/Themes.dart';

/*  DeleteAllProfiles - Shows a dialog asking the user if they want to delete all profiles
    Input:
      context - BuildContext that represents the context of the widget
    Algorithm:
      * Get the application directory
      * Get the profile directory
      * Check if the profile directory exists
        * If it exists, get the list of profiles
        * Check if the list of profiles is not empty
          * If it is not empty, display an alert dialog
            * Title: Delete All Profiles
            * Content: Are you sure you want to delete all profiles? This cannot be undone.
            * Actions:
              * ElevatedButton
                * OnPressed: Delete all profiles
                * Text: Yes
              * SizedBox
              * ElevatedButton
                * OnPressed: Close the dialog
                * Text: No
          * If it is empty, display a dialog
            * Content: There are no profiles present.
    Output:
      Deletes all profiles
*/
Future<void> DeleteAllProfiles(BuildContext context) async {
  final appDir = await getApplicationDocumentsDirectory();
  final profileDir = Directory('${appDir.path}/Profiles');
  if (profileDir.existsSync()) {
    final profiles = profileDir.listSync().where((item) => item is Directory).cast<Directory>();
    // Profiles exist
    if (profiles.isNotEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Delete All Profiles',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Prompt the user to confirm the deletion of all profiles
            content: Text('Are you sure you want to delete all profiles? This cannot be undone.'),
            actions: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Yes button
                  ElevatedButton(
                    onPressed: () async {
                      // Show a dialog simulating the deletion of all profiles
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return Dialog(
                            child: Container(
                              padding: EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 20),
                                  Text(
                                    'Deleting all profiles',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                      for (var profs in profiles) {
                        profs.deleteSync(recursive: true);
                      }
                      await Future.delayed(Duration(seconds: 2));
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Yes',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  // No button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'No',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );
    }
    // No profiles exist
    else {
      // Dialog showing that now profiles are present
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return Dialog(
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'There are no profiles present.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }
}

// Future<void> ReadProfileData(String profile) async {
//   final appDir = await getApplicationDocumentsDirectory();
//   final profileDir = Directory('${appDir.path}/Profiles/$profile');
//   final profileJSON = File('${profileDir.path}/data.json');
//   if (await profileJSON.existsSync()) {
//     final profileData = await profileJSON.readAsString();
//     return jsonDecode(profileData);
//   } else {
//     throw Exception('Profile data not found');
//   }
// }

/* profileEntry - Returns a list of widgets for a profile entry
    Input:
      context - BuildContext that represents the context of the widget
      title - String that represents the title of the profile entry
      controller - TextEditingController that represents the controller for the text field
      hintText - String that represents the hint text for the text field
    Algorithm:
      * Return a list of widgets that represent the profile entry
        * Center widget that contains a Text widget with the title
          * Set the title of the current profile entry
          * Set the style of the text widget
        * SizedBox widget with a height of 20
        * Center widget that contains a Container widget
          * Set the width of the container to 80% of the screen width
          * Set the child of the container to a TextField widget
            * Set the controller of the text field to the controller parameter
            * Set the keyboardType of the text field to multiline
            * Set the maxLines of the text field to 5
            * Set the decoration of the text field to an InputDecoration widget with the hintText parameter
        * SizedBox widget with a height of 20
    Output:
      Returns a list of widgets that represent the profile entry
*/
List<Widget> profileEntry(BuildContext context, String title, TextEditingController controller, String hintText) {
  return [
    // Title of the profile entry
    Center(
      child: Text(
        title,
        style: TextStyle(
          color: themeTextColor(context),
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    SizedBox(height: 20),
    // Text field for the profile entry
    Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.multiline,
          maxLines: 5,
          decoration: InputDecoration(hintText: hintText),
        ),
      ),
    ),
    SizedBox(height: 20),
  ];
}

/*  createNewProfile - Creates a new profile
    Input:
      context - BuildContext that represents the context of the widget
      profName - TextEditingController that represents the controller for the profile name
      edu - TextEditingController that represents the controller for the education field
      exp - TextEditingController that represents the controller for the experience field
      qual - TextEditingController that represents the controller for the qualifications field
      proj - TextEditingController that represents the controller for the projects field
    Algorithm:
      * Get the application directory
      * Get the profile directory
      * Check if the profile directory exists
        * If it does not exist, create the profile directory
      * Check if the new profile directory exists
        * If it does not exist, create the new profile directory
        * Create the education, experience, qualifications, and projects files
        * Display a loading dialog simulating that the files are being written
      * If the new profile directory exists
        * Display an alert dialog
          * Title: Profile Already Exists
          * Content: A profile with the name ${profName.text} already exists. Please choose a different name or navigate to the Load Profiles page to edit the existing profile.
    Output:
      Creates a new profile
*/
Future<void> createNewProfile(
    BuildContext context, TextEditingController profName, TextEditingController edu, TextEditingController exp, TextEditingController qual, TextEditingController proj) async {
  // Get the application directory
  final dir = await getApplicationDocumentsDirectory();
  // Get the profile directory
  final profilesDir = Directory('${dir.path}/Profiles');
  // Check if the profile directory exists
  if (!profilesDir.existsSync()) {
    profilesDir.createSync();
  }
  // Check if the profile directory exists
  else {
    // Create the new profile directory
    final newProfileDir = Directory('${dir.path}/Profiles/${profName.text}');
    // Check if the new profile directory exists
    if (!newProfileDir.existsSync()) {
      // Create the new profile directory
      newProfileDir.createSync();
      // Create the education, experience, qualifications, and projects files
      final eduFile = File('${newProfileDir.path}/education.txt');
      final expFile = File('${newProfileDir.path}/experience.txt');
      final qualFile = File('${newProfileDir.path}/qualifications.txt');
      final projFile = File('${newProfileDir.path}/proj.txt');
      // Write the text from the education, experience, qualifications, and projects text fields to the respective files
      await eduFile.writeAsString(edu.text);
      await expFile.writeAsString(exp.text);
      await qualFile.writeAsString(qual.text);
      await projFile.writeAsString(proj.text);
      // Show a spinning icon while the files are being written
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    'Writing files...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
      // Write the text from the education, experience, qualifications, and projects text fields to the respective files
      await Future.delayed(Duration(seconds: 2));
      // Close the dialog
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    }
    // If the new profile directory exists
    else {
      // Display an alert dialog
      return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            // Text of dialog
            title: Text(
              'Profile Already Exists',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Content of dialog
            content: Text('A profile with the name ${profName.text} already exists. Please choose a different name \nor navigate to the Load Profiles page to edit the existing profile.'),
          );
        },
      );
    }
  }
}
