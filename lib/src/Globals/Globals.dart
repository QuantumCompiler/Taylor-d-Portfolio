import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Booleans
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
// Is Desktop
bool isDesktop() {
  return (Platform.isMacOS || Platform.isLinux || Platform.isWindows);
}

// Is Mobile
bool isMobile() {
  return (Platform.isIOS || Platform.isAndroid);
}

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Button Parameters
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
double buttonTitle = 16;

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Card Parameters
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
double singleCardMaxHeight = 0.25;
double singleCardMinHeight = 0.1;
double singleCardMaxWidth = 0.35;
double singleCardMinWidth = 0.25;
double singleCardPadding = 16.0;
double singleCardWidthBox = 0.05;

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Colors
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
Color cyanButtonColor = Color.fromARGB(255, 0, 213, 255);
Color whiteButtonColor = Colors.white;
Color blackTextColor = Colors.black;
Color whiteTextColor = Colors.white;

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Dashboard Card Title Parameters
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
String resumesGenTitle = 'Resumes Generated';
String coverLettersGenTitle = 'Cover Letters Generated';

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Directories
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
// Profiles Directory Name
String profilesDir = 'Profiles';

// Application Directory
Future<Directory> GetAppDir() async {
  return await getApplicationDocumentsDirectory();
}

// Cache Directory
Future<Directory> GetCacheDir() async {
  return await getTemporaryDirectory();
}

// Profiles Directory
Future<Directory> GetProfilesDir() async {
  final appDir = await getApplicationDocumentsDirectory();
  final profilesDir = Directory('${appDir.path}/Profiles');
  if (!profilesDir.existsSync()) {
    profilesDir.createSync();
  }
  return profilesDir;
}

// Support Directory
Future<Directory> GetSupportDir() async {
  return await getApplicationSupportDirectory();
}

// Create Directory
Future<void> CreateDir(Directory parentDir, String dirName) async {
  final dir = Directory('${parentDir.path}/$dirName');
  if (!dir.existsSync()) {
    dir.createSync();
  }
}

// Create Profile Directory
Future<void> CreateProfileDir() async {
  Directory appDir = await GetAppDir();
  CreateDir(appDir, profilesDir);
}

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Documents Generated
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
int resumesGenerated = 0;
int coverLettersGenerated = 0;

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Drawer Parameters
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
double drawerVerticalPadding = 25.0;
double drawerWidth = 0.15;

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Files
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
Future<void> WriteFile(Directory dir, File file, String contents) async {
  await file.writeAsString(contents);
}

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Jobs
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
// Sizes
double jobTileContainerWidth = 0.6;
double jobTileSize = 24.0;
double jobContainerWidth = 0.8;
// Titles & Hints
String jobsCreateNew = 'Create A New Job';
String jobsLoad = 'Load A Job';

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Profile Parameters
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
// Sizes
double profileTileContainerWidth = 0.6;
double profileTitleSize = 24.0;
double profileContainerWidth = 0.8;
// Titles & Hints
String profileCreateNew = 'Create New Profile';
String profileLoad = 'Load Profiles';
String profileEduTitle = 'Education';
String profileEduHint = 'Enter education here.';
String profileExpTitle = 'Experience';
String profileExpHint = 'Enter experience here.';
String profileExtTitle = 'Extracurricular';
String profileExtHint = 'Enter extracurricular here.';
String profileHonTitle = 'Honors';
String profileHonHint = 'Enter honors here.';
String profileNameTitle = 'Profile Name';
String profileProjTitle = 'Projects';
String profileProjHint = 'Enter projects here.';
String profileRefTitle = 'References';
String profileRefHint = 'Enter references here.';
String profileSkillsTitle = 'Skills';
String profileSkillsHint = 'Enter skills here.';
// File Names
String profileEduFile = 'education.txt';
String profileExpFile = 'experience.txt';
String profileExtFile = 'extracurricular.txt';
String profileHonFile = 'honors.txt';
String profileProjFile = 'projects.txt';
String profileRefFile = 'references.txt';
String profileSkillsFile = 'skills.txt';

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Settings Parameters
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
double settingsTileContainerWidth = 0.6;
String settingsCurrentTheme = 'Switch Theme';
String settingsDeleteAllProfiles = 'Delete All Profiles';

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Size Box Parameters
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
double standardSizedBoxHeight = 20;
double standardSizedBoxWidth = 20;

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Text Parameters
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
double appBarTitle = 24.0;
double secondaryTitles = 16.0;

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Title Parameters
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
String dashboardTitle = 'Dashboard';
String jobsTitle = 'Jobs';
String profileTitle = 'Profile';
String settingsTitle = 'Settings';

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Tooltip Parameters
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
String dashboardToolTip = 'Dashboard';
String profileToolTip = 'Profile';
String jobsToolTip = 'Jobs';
String settingsToolTip = 'Settings';
