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
