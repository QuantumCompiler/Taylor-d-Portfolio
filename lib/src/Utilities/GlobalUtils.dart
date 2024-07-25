import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'ApplicationsUtils.dart';
import 'JobUtils.dart';
import 'ProfilesUtils.dart';
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
//  Other Directory Operations
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----

// Clean Directory
Future<void> CleanDir(String subDir) async {
  final masterDir = await getApplicationDocumentsDirectory();
  final dir = Directory('${masterDir.path}/$subDir');
  final contents = dir.listSync();
  for (var entity in contents) {
    if (entity is File) {
      await entity.delete();
    } else if (entity is Directory) {
      await entity.delete(recursive: true);
    }
  }
}

// Function to recursively copy directories
Future<void> CopyDir(Directory sourceDir, Directory destDir, bool delete) async {
  await for (var entity in sourceDir.list(recursive: false)) {
    if (entity is Directory) {
      var newDirectory = Directory(path.join(destDir.path, path.basename(entity.path)));
      await newDirectory.create(recursive: true);
      await CopyDir(entity, newDirectory, false);
    } else if (entity is File) {
      await CopyFile(entity, destDir);
    }
  }
  if (delete) {
    await sourceDir.delete(recursive: true);
  }
}

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Files
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----

// Function to copy files
Future<void> CopyFile(File sourceFile, Directory destDir) async {
  final newFile = File(path.join(destDir.path, path.basename(sourceFile.path)));
  await newFile.create(recursive: true);
  await newFile.writeAsBytes(await sourceFile.readAsBytes());
}

// Read JSON To String
Future<List<dynamic>> JSONList(File inputFile) async {
  String jsonString = await inputFile.readAsString();
  return jsonDecode(jsonString);
}

// Map String To JSON
Future<List<T>> MapJSONToList<T>(File inputFile, T Function(Map<String, dynamic> fromJSON) fromJSON) async {
  List<T> ret = [];
  final jsonString = await inputFile.readAsString();
  final List<dynamic> jsonData = jsonDecode(jsonString);
  ret = jsonData.map((entry) => fromJSON(entry)).toList();
  return ret;
}

// Retrieve JSON File
Future<File> RetJSONFile(String subDir, String fileName) async {
  final masterDir = await getApplicationDocumentsDirectory();
  File jsonFile = File('${masterDir.path}/$subDir/$fileName');
  return jsonFile;
}

// Write New File
Future<void> WriteFile(Directory dir, File file, String contents) async {
  await file.writeAsString(contents);
}

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Delete Objects
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----

Future<void> DeleteApplication(String appName) async {
  final appsDir = await GetApplicationsDir();
  final appDir = Directory('${appsDir.path}/$appName');
  if (await appDir.exists()) {
    await appDir.delete(recursive: true);
  }
}

Future<void> DeleteAllApplications() async {
  final appsDir = await GetApplicationsDir();
  final List<FileSystemEntity> apps = appsDir.listSync();
  for (final app in apps) {
    if (app is Directory) {
      app.deleteSync(recursive: true);
    }
  }
}

Future<void> DeleteAllJobs() async {
  final jobsDir = await GetJobsDir();
  final List<FileSystemEntity> jobs = jobsDir.listSync();
  for (final job in jobs) {
    if (job is Directory) {
      await job.delete(recursive: true);
    }
  }
}

Future<void> DeleteJob(String jobName) async {
  final jobsDir = await GetJobsDir();
  final jobDir = Directory('${jobsDir.path}/$jobName');
  if (await jobDir.exists()) {
    await jobDir.delete(recursive: true);
  }
}

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
        Application app = await Application.Init(
          name: appName,
          newApp: false,
        );
        applications.add(app);
      }
    }
  }
  applications.sort((a, b) => a.name.compareTo(b.name));
  return applications;
}

// Retrieve Jobs
Future<List<Job>> RetrieveSortedJobs() async {
  final jobsDir = await GetJobsDir();
  List<Job> jobs = [];
  if (jobsDir.existsSync()) {
    for (var entity in jobsDir.listSync()) {
      if (entity is Directory) {
        String jobName = entity.path.split('/').last;
        Job job = await Job.Init(
          name: jobName,
          newJob: false,
        );
        jobs.add(job);
      }
    }
  }
  jobs.sort((a, b) => a.name.compareTo(b.name));
  return jobs;
}

// Retrieve Profiles
Future<List<Profile>> RetrieveSortedProfiles() async {
  final profsDir = await GetProfilesDir();
  List<Profile> profiles = [];
  if (profsDir.existsSync()) {
    for (var entity in profsDir.listSync()) {
      if (entity is Directory) {
        String profName = entity.path.split('/').last;
        Profile profile = await Profile.Init(
          name: profName,
          newProfile: false,
        );
        profiles.add(profile);
      }
    }
  }
  profiles.sort((a, b) => a.name.compareTo(b.name));
  return profiles;
}

// Retrieve All Content (Applications, Jobs, Profiles)
Future<List<dynamic>> RetrieveAllContent() async {
  List<dynamic> content = [];
  List<Application> apps = await RetrieveSortedApplications();
  List<Job> jobs = await RetrieveSortedJobs();
  List<Profile> profiles = await RetrieveSortedProfiles();
  content.add(apps);
  content.add(jobs);
  content.add(profiles);
  return content;
}

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Objects
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----

/*  LoadContent - Loads content from a JSON file into a list
        Class Definition:
          T - Type of class list to load:
        Input:
          fileName - String for the name of the JSON file
          subDir - String for the subdirectory to load the file from
          fromJSON - Function to convert JSON to class
        Algorithm:
          * Declare empty list
          * Try to load content
            * Retrieve directories and file
            * If the file exists, map the JSON to the list
          * Catch error if occurs
        Output:
          List of class type T
  */
Future<List<T>> LoadContent<T>(String fileName, String subDir, T Function(Map<String, dynamic>) fromJSON) async {
  // Declare empty list
  List<T> ret = [];
  // Try to load content
  try {
    // Retrieve directories and file
    final masterDir = await getApplicationDocumentsDirectory();
    final subDirPath = '${masterDir.path}/$subDir';
    final jsonFile = File('$subDirPath/$fileName');
    // Check if the sub-directory exists
    final subDirExists = await Directory(subDirPath).exists();
    if (!subDirExists) {
      return ret;
    }
    // Check if the file exists
    final fileExists = await jsonFile.exists();
    if (fileExists) {
      return await MapJSONToList<T>(jsonFile, fromJSON);
    } else {
      return ret;
    }
  }
  // Catch error if occurs
  catch (e) {
    throw ('An error occurred while loading content: $e');
  }
}

/*  SetContent - Sets the content of a list
        Class Definition:
          T - Type of class list to set:
        Input:
          inputList - List of type T that is the input list
          outputList - List of type T that is the output list
        Algorithm:
          * Clear the output list
          * Add all elements from the input list to the output list
        Output:
          Sets the content of a list
  */
Future<void> SetContent<T>(List<T> inputList, List<T> outputList) async {
  outputList.clear();
  outputList.addAll(inputList);
}

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Custom Page Route Builders
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
// Left To Right Route
class LeftToRightPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  LeftToRightPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(-1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);
            return SlideTransition(position: offsetAnimation, child: child);
          },
        );
}

// Right To Left Route
class RightToLeftPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  RightToLeftPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);
            return SlideTransition(position: offsetAnimation, child: child);
          },
        );
}
