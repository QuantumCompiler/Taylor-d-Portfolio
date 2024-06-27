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
// Directory Names
String jobsMasterDir = 'Jobs';
String profilesMasterDir = 'Profiles';

// Application Directory
Future<Directory> GetAppDir() async {
  return await getApplicationDocumentsDirectory();
}

// Cache Directory
Future<Directory> GetCacheDir() async {
  return await getTemporaryDirectory();
}

// Jobs Directory
Future<Directory> GetJobsDir() async {
  final appDir = await getApplicationDocumentsDirectory();
  final jobsDir = Directory('${appDir.path}/$jobsMasterDir');
  if (!jobsDir.existsSync()) {
    jobsDir.createSync();
  }
  return jobsDir;
}

// Profiles Directory
Future<Directory> GetProfilesDir() async {
  final appDir = await getApplicationDocumentsDirectory();
  final profilesDir = Directory('${appDir.path}/$profilesMasterDir');
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
  CreateDir(appDir, profilesMasterDir);
}

// Create Jobs Directory
Future<void> CreateJobsDir() async {
  Directory appDir = await GetAppDir();
  CreateDir(appDir, jobsMasterDir);
}

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Documents Generated
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
int resumesGenerated = 0;
int coverLettersGenerated = 0;

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Drawer Parameters
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----

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
double jobTitleSize = 24.0;
double jobContainerWidth = 0.8;
// Titles & Hints
String jobsCreateNew = 'Create New Job';
String jobsLoad = 'Load A Job';
String jobsDesTitle = 'Description';
String jobsDesHint = 'Enter job description here.';
String jobsNameTitle = 'Job Name';
String jobsOtherTitle = 'Other';
String jobsOtherHint = 'Enter other info here.';
String jobsPosTitle = 'Position';
String jobsPosHint = 'Enter position info here.';
String jobsQualsTitle = 'Qualifications';
String jobsQualsHint = 'Enter qualifications here.';
String jobsRoleTitle = 'Role';
String jobsRoleHint = 'Enter role info here.';
String jobsTasksTitle = 'Tasks';
String jobsTasksHint = 'Enter tasks info here.';
// File Names
String jobsDesFile = 'description.txt';
String jobsOtherFile = 'other.txt';
String jobsPosFile = 'position.txt';
String jobsQualsFile = 'qualifications.txt';
String jobsRoleFile = 'role.txt';
String jobsTasksFile = 'tasks.txt';

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
String jobsTitle = 'Jobs';
String profileTitle = 'Profile';