import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

// Button Parameters
double buttonTitle = 16;

// Card Parameters
double singleCardMaxHeight = 0.25;
double singleCardMinHeight = 0.1;
double singleCardMaxWidth = 0.35;
double singleCardMinWidth = 0.25;
double singleCardPadding = 16.0;
double singleCardWidthBox = 0.05;

// Colors
Color cyanButtonColor = Color.fromARGB(255, 0, 213, 255);
Color whiteButtonColor = Colors.white;
Color blackTextColor = Colors.black;
Color whiteTextColor = Colors.white;

// Dashboard Card Title Parameters
String resumesGenTitle = 'Resumes Generated';
String coverLettersGenTitle = 'Cover Letters Generated';

// Directories
String profilesDir = 'Profiles';

// Application Directory
Future<Directory> getAppDir() async {
  return await getApplicationDocumentsDirectory();
}

// Cache Directory
Future<Directory> getCacheDir() async {
  return await getTemporaryDirectory();
}

// Profiles Directory
Future<Directory> getProfilesDir() async {
  final appDir = await getApplicationDocumentsDirectory();
  final profilesDir = Directory('${appDir.path}/Profiles');
  if (!profilesDir.existsSync()) {
    profilesDir.createSync();
  }
  return profilesDir;
}

// Support Directory
Future<Directory> getSupportDir() async {
  return await getApplicationSupportDirectory();
}

// Create Profile Directory
Future<void> createProfileDir() async {
  Directory appDir = await getAppDir();
  final profsDir = Directory('${appDir.path}/$profilesDir');
  if (!profsDir.existsSync()) {
    profsDir.createSync();
  }
}

// Documents generated
int resumesGenerated = 0;
int coverLettersGenerated = 0;

// Drawer Parameters
double drawerVerticalPadding = 25.0;
double drawerWidth = 0.15;

// Profile Parameters
double profileTileContainerWidth = 0.6;
double profileTitleSize = 24.0;
double profileContainerWidth = 0.8;
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
String profileProjTitle = 'Projects';
String profileProjHint = 'Enter projects here.';
String profileRefTitle = 'References';
String profileRefHint = 'Enter references here.';
String profileSkillsTitle = 'Skills';
String profileSkillsHint = 'Enter skills here.';

// Settings Parameters
String settingsCurrentTheme = 'Switch Theme';
String settingsDeleteAllProfiles = 'Delete All Profiles';
double settingsTileContainerWidth = 0.6;

// Size Box Parameters
double standardSizedBoxHeight = 20;
double standardSizedBoxWidth = 20;

// Text Parameters
double appBarTitle = 24.0;
double secondaryTitles = 16.0;

// Title Parameters
String dashboardTitle = 'Dashboard';
String profileTitle = 'Profile';
String settingsTitle = 'Settings';

// Tooltip Parameters
String dashboardToolTip = 'Dashboard';
String profileToolTip = 'Profile';
String jobsToolTip = 'Job Description';
String settingsToolTip = 'Settings';
