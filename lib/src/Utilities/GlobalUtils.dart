import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../Utilities/ApplicationsUtils.dart';
import '../Utilities/ProfilesUtils.dart';
import '../Globals/Globals.dart';

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Get Directories
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----

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

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Create Directories
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----

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

// Write New File
Future<void> WriteFile(Directory dir, File file, String contents) async {
  await file.writeAsString(contents);
}

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Delete Objects
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----

Future<void> DeleteAllProfiles() async {
  final profilesDirectory = await GetProfilesDir();
  final List<FileSystemEntity> profiles = profilesDirectory.listSync();
  for (final profile in profiles) {
    if (profile is Directory) {
      await profile.delete(recursive: true);
    }
  }
}

Future<void> DeleteProfile(String profileName) async {
  final profilesDirectory = await GetProfilesDir();
  final profileDir = Directory('${profilesDirectory.path}/$profileName');
  if (await profileDir.exists()) {
    await profileDir.delete(recursive: true);
  }
}

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Retrieve Objects
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----

// Retrieve Applications
Future<List<Application>> RetrieveSortedApplications() async {
  final appsDir = await GetApplicationsDir();
  List<Application> applications = [];
  if (appsDir.existsSync()) {
    for (var entity in appsDir.listSync()) {
      if (entity is Directory) {
        String appName = entity.path.split('/').last;
        applications.add(Application(
          applicationName: appName,
          profileName: '',
          controllers: List.generate(9, (index) => TextEditingController()),
        ));
      }
    }
  }
  applications.sort((a, b) => a.applicationName.compareTo(b.applicationName));
  return applications;
}

// Retrieve Profiles
Future<List<Profile>> RetrieveSortedProfiles() async {
  final profsDir = await GetProfilesDir();
  List<Profile> profiles = [];
  if (profsDir.existsSync()) {
    for (var entity in profsDir.listSync()) {
      if (entity is Directory) {
        String profName = entity.path.split('/').last;
        profiles.add(
          Profile(
            name: profName,
          ),
        );
      }
    }
  }
  return profiles;
}
