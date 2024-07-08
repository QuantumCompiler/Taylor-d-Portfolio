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
//  Directories
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
// Directory Names
String applicationsMasterDir = 'Applications';
String jobsMasterDir = 'Jobs';
String latexMasterDir = 'LaTeX';
String profilesMasterDir = 'Profiles';

// Application Directory
Future<Directory> GetAppDir() async {
  return await getApplicationDocumentsDirectory();
}

// Cache Directory
Future<Directory> GetCacheDir() async {
  return await getTemporaryDirectory();
}

// Applications Directory
Future<Directory> GetApplicationsDir() async {
  final appDir = await getApplicationDocumentsDirectory();
  final applicationsDir = Directory('${appDir.path}/$applicationsMasterDir');
  if (!applicationsDir.existsSync()) {
    applicationsDir.create();
  }
  return applicationsDir;
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

// LaTeX Directory
Future<Directory> GetLaTeXDir() async {
  final appDir = await getApplicationDocumentsDirectory();
  final latexDir = Directory('${appDir.path}/$latexMasterDir');
  if (!latexDir.existsSync()) {
    latexDir.createSync();
  }
  return latexDir;
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

// Create Applications Directory
Future<void> CreateApplicationsDir() async {
  Directory appDir = await GetAppDir();
  CreateDir(appDir, applicationsMasterDir);
}

// Create Jobs Directory
Future<void> CreateJobsDir() async {
  Directory appDir = await GetAppDir();
  CreateDir(appDir, jobsMasterDir);
}

// Create LaTeX Directory
Future<void> CreateLaTeXDir() async {
  Directory appDir = await GetAppDir();
  CreateDir(appDir, latexMasterDir);
}

// Create Profile Directory
Future<void> CreateProfileDir() async {
  Directory appDir = await GetAppDir();
  CreateDir(appDir, profilesMasterDir);
}

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Files
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
Future<void> WriteFile(Directory dir, File file, String contents) async {
  await file.writeAsString(contents);
}

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
