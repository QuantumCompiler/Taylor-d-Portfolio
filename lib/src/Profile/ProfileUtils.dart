import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../Themes/Themes.dart';

class ProfileData {
  final String education;
  final String experience;
  final String extracurricular;
  final String honors;
  final String profileName;
  final String projects;
  final String qualifications;
  final String references;

  ProfileData({
    required this.experience,
    required this.education,
    required this.extracurricular,
    required this.honors,
    required this.profileName,
    required this.projects,
    required this.qualifications,
    required this.references,
  });
}

class ProfileControllers {
  final TextEditingController eduController;
  final TextEditingController expController;
  final TextEditingController extController;
  final TextEditingController honController;
  final TextEditingController profNameController;
  final TextEditingController projController;
  final TextEditingController qualController;
  final TextEditingController refController;

  ProfileControllers({
    required this.eduController,
    required this.expController,
    required this.extController,
    required this.honController,
    required this.profNameController,
    required this.projController,
    required this.qualController,
    required this.refController,
  });
}

/*  CreateNewProfile - Creates a new profile
    Input:
      context - BuildContext that represents the context of the widget
    Algorithm:
      * Create a new ProfileData object with the profile name, education, experience, qualifications, and projects
      * Get the application directory
      * Get the profile directory
      * Check if the profile directory exists
        * If it does not exist, create the profile directory
        * If it exists, create the new profile directory
          * Check if the new profile directory exists
            * If it does not exist, create the new profile directory
            * If it exists, display an alert dialog
              * Title: Profile Already Exists
              * Content: A profile with the name ${profileData.profileName} already exists. Please choose a different name or navigate to the Load Profiles page to edit the existing profile.
      * If the profile directory exists
        * Create the education, experience, qualifications, and projects files
        * Show a dialog with a spinning icon while the files are being written
        * Write the text from the education, experience, qualifications, and projects text fields to the respective files
        * Close the dialog
    Output:
      Creates a new profile
*/
Future<void> CreateNewProfile(BuildContext context, ProfileControllers controllers) async {
  final profileData = ProfileData(
    education: controllers.eduController.text,
    experience: controllers.expController.text,
    extracurricular: controllers.extController.text,
    honors: controllers.honController.text,
    profileName: controllers.profNameController.text,
    projects: controllers.projController.text,
    qualifications: controllers.qualController.text,
    references: controllers.refController.text,
  );
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
    final newProfileDir = Directory('${dir.path}/Profiles/${profileData.profileName}');
    // Check if the new profile directory exists
    if (!newProfileDir.existsSync()) {
      // Create the new profile directory
      newProfileDir.createSync();
      // Create the education, experience, qualifications, and projects files
      File eduFile = File('${newProfileDir.path}/education.txt');
      File expFile = File('${newProfileDir.path}/experience.txt');
      File extFile = File('${newProfileDir.path}/extracurricular.txt');
      File honFile = File('${newProfileDir.path}/honors.txt');
      File projFile = File('${newProfileDir.path}/projects.txt');
      File qualFile = File('${newProfileDir.path}/qualifications.txt');
      File refFile = File('${newProfileDir.path}/references.txt');
      await eduFile.writeAsString(profileData.education);
      await expFile.writeAsString(profileData.experience);
      await extFile.writeAsString(profileData.extracurricular);
      await honFile.writeAsString(profileData.honors);
      await projFile.writeAsString(profileData.projects);
      await qualFile.writeAsString(profileData.qualifications);
      await refFile.writeAsString(profileData.references);
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
            content: Text('A profile with the name ${profileData.profileName} already exists. Please choose a different name \nor navigate to the Load Profiles page to edit the existing profile.'),
          );
        },
      );
    }
  }
}

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
    final profiles = profileDir.listSync().whereType<Directory>().cast<Directory>();
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
                color: themeTextColor(context),
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
                                    'Deleting all profiles...',
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

/*  loadProfileControllers - Load profile data into controllers
        Input:
          profileName - String that represents the name of the profile
        Algorithm:
          * Load profile data
          * Create controllers with info from profile data
          * Return profile controllers with data
        Output:
          ProfileControllers
  */
Future<ProfileControllers> LoadProfileControllers(String profileName) async {
  final profileData = await LoadProfileData(profileName);
  final eduController = TextEditingController(text: profileData.education);
  final expController = TextEditingController(text: profileData.experience);
  final extController = TextEditingController(text: profileData.extracurricular);
  final honController = TextEditingController(text: profileData.honors);
  final profController = TextEditingController(text: profileData.profileName);
  final projController = TextEditingController(text: profileData.projects);
  final qualController = TextEditingController(text: profileData.qualifications);
  final refController = TextEditingController(text: profileData.references);
  return ProfileControllers(
    eduController: eduController,
    expController: expController,
    extController: extController,
    honController: honController,
    profNameController: profController,
    projController: projController,
    qualController: qualController,
    refController: refController,
  );
}

/*  LoadProfileData - Loads the profile data
    Input:
      profileName - String that represents the name of the profile
    Algorithm:
      * Get the application directory
      * Get the profile directory
      * Get the education, experience, qualifications, and projects files
      * Read the text from the education, experience, qualifications, and projects files
      * Return a ProfileData object with the profile name, education, experience, qualifications, and projects
    Output:
      Returns a ProfileData object with the profile name, education, experience, qualifications, and projects
*/
Future<ProfileData> LoadProfileData(String profileName) async {
  // Directories
  final appDir = await getApplicationDocumentsDirectory();
  final profDir = Directory('${appDir.path}/Profiles/$profileName');
  // Files
  final eduFile = File('${profDir.path}/education.txt');
  final expFile = File('${profDir.path}/experience.txt');
  final extFile = File('${profDir.path}/extracurricular.txt');
  final honFile = File('${profDir.path}/honors.txt');
  final projFile = File('${profDir.path}/projects.txt');
  final qualFile = File('${profDir.path}/qualifications.txt');
  final refFile = File('${profDir.path}/references.txt');
  // Contents of files
  final education = await eduFile.readAsString();
  final experience = await expFile.readAsString();
  final extracurricular = await extFile.readAsString();
  final honors = await honFile.readAsString();
  final projects = await projFile.readAsString();
  final qualifications = await qualFile.readAsString();
  final references = await refFile.readAsString();
  // Returns
  return ProfileData(
      education: education,
      experience: experience,
      extracurricular: extracurricular,
      honors: honors,
      profileName: profileName,
      projects: projects,
      qualifications: qualifications,
      references: references);
}

/* ProfileEntry - Returns a list of widgets for a profile entry
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
List<Widget> ProfileEntry(BuildContext context, String title, TextEditingController controller, String hintText) {
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
          maxLines: 10,
          decoration: InputDecoration(hintText: hintText.isEmpty ? null : hintText),
        ),
      ),
    ),
    SizedBox(height: 20),
  ];
}

/*  OverWriteProfile - Shows a dialog asking the user if they want to overwrite the existing profile
    Input:
      context - BuildContext that represents the context of the widget
      profileControllers - ProfileControllers that represents the controllers for the profile
    Algorithm:
      * Show an alert dialog
        * Title: Overwrite Existing Profile
        * Content: Are you sure you want to overwrite your existing profile? This cannot be undone.
        * Actions:
          * ElevatedButton
            * OnPressed: Overwrite the existing profile
            * Text: Yes
          * SizedBox
          * ElevatedButton
            * OnPressed: Close the dialog
            * Text: No
    Output:
      Overwrites the existing profile
*/
Future<void> OverWriteProfile(BuildContext context, ProfileControllers profileControllers) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          'Overwrite Existing Profile',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: themeTextColor(context),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text('Are you sure you want to overwrite your existing profile? This cannot be undone.'),
        actions: <Widget>[
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Yes Button
                  ElevatedButton(
                    onPressed: () async {
                      final dir = await getApplicationDocumentsDirectory();
                      final profileDir = Directory('${dir.path}/Profiles/${profileControllers.profNameController.text}');
                      final eduFile = File('${profileDir.path}/education.txt');
                      final expFile = File('${profileDir.path}/experience.txt');
                      final extFile = File('${profileDir.path}/extracurricular.txt');
                      final honFile = File('${profileDir.path}/honors.txt');
                      final projFile = File('${profileDir.path}/projects.txt');
                      final qualFile = File('${profileDir.path}/qualifications.txt');
                      final refFile = File('${profileDir.path}/references.txt');
                      await eduFile.writeAsString(profileControllers.eduController.text);
                      await expFile.writeAsString(profileControllers.expController.text);
                      await extFile.writeAsString(profileControllers.extController.text);
                      await honFile.writeAsString(profileControllers.honController.text);
                      await projFile.writeAsString(profileControllers.projController.text);
                      await qualFile.writeAsString(profileControllers.qualController.text);
                      await refFile.writeAsString(profileControllers.refController.text);
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return Dialog(
                            child: Container(
                              padding: EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  CircularProgressIndicator(),
                                  SizedBox(height: 20),
                                  Text(
                                    'Overwriting files...',
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
                  // No Button
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
          ),
        ],
      );
    },
  );
}
