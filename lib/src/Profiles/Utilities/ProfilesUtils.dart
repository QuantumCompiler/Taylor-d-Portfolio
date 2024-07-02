import 'dart:io';
import 'package:flutter/material.dart';
import '../Globals/ProfilesGlobals.dart';
import '../../Globals/Globals.dart';
import '../../Themes/Themes.dart';

// Profile Class
class Profile {
  // Directories
  final Future<Directory> appDir = GetAppDir();
  final Future<Directory> cacheDir = GetCacheDir();
  final Future<Directory> profsDir = GetProfilesDir();
  final Future<Directory> supDir = GetSupportDir();

  // Files
  late File eduFile;
  late File expFile;
  late File extFile;
  late File honFile;
  late File projFile;
  late File refFile;
  late File skiFile;

  // Main Titles & Name
  late String eduTitle;
  late String expTitle;
  late String extTitle;
  late String honTitle;
  late String name;
  late String projTitle;
  late String refTitle;
  late String skiTitle;

  // Contents
  late String education;
  late String experience;
  late String extracurricular;
  late String honors;
  late String projects;
  late String references;
  late String skills;

  // Controllers
  late TextEditingController eduCont;
  late TextEditingController expCont;
  late TextEditingController extCont;
  late TextEditingController honCont;
  late TextEditingController nameCont;
  late TextEditingController projCont;
  late TextEditingController refCont;
  late TextEditingController skillsCont;

  // Constructor
  Profile({this.name = ''}) {
    eduTitle = educationTitle;
    expTitle = experienceTitle;
    extTitle = extracurricularTitle;
    honTitle = honorsTitle;
    projTitle = projectsTitle;
    refTitle = referencesTitle;
    skiTitle = skillsTitle;
    eduCont = TextEditingController();
    expCont = TextEditingController();
    extCont = TextEditingController();
    honCont = TextEditingController();
    nameCont = TextEditingController();
    projCont = TextEditingController();
    refCont = TextEditingController();
    skillsCont = TextEditingController();
  }

  // Create New Profile
  Future<void> CreateNewProfile(String profName) async {
    setProfName(profName);
    setProfDir();
    setWriteNewFiles();
  }

  // Load Profile
  Future<void> LoadProfileData() async {
    final profsDirectory = await profsDir;
    final currProf = Directory('${profsDirectory.path}/$name');
    if (currProf.existsSync()) {
      nameCont.text = name;
    }
    eduFile = File('${currProf.path}/$educationFile');
    expFile = File('${currProf.path}/$experienceFile');
    extFile = File('${currProf.path}/$extracurricularFile');
    honFile = File('${currProf.path}/$honorsFile');
    projFile = File('${currProf.path}/$projectsFile');
    refFile = File('${currProf.path}/$referencesFile');
    skiFile = File('${currProf.path}/$skillsFile');
    if (await eduFile.exists()) {
      education = await eduFile.readAsString();
      eduCont.text = education;
    }
    if (await expFile.exists()) {
      experience = await expFile.readAsString();
      expCont.text = experience;
    }
    if (await extFile.exists()) {
      extracurricular = await extFile.readAsString();
      extCont.text = extracurricular;
    }
    if (await honFile.exists()) {
      honors = await honFile.readAsString();
      honCont.text = honors;
    }
    if (await projFile.exists()) {
      projects = await projFile.readAsString();
      projCont.text = projects;
    }
    if (await refFile.exists()) {
      references = await refFile.readAsString();
      refCont.text = references;
    }
    if (await skiFile.exists()) {
      skills = await skiFile.readAsString();
      skillsCont.text = skills;
    }
  }

  // Setters

  // Set Profile Name
  Future<void> setProfName(String profName) async {
    name = profName;
  }

  // Set Overwrite Files
  Future<void> setOverwriteFiles() async {
    final dir = await profsDir;
    final newName = nameCont.text;
    final oldDir = Directory('${dir.path}/$name');
    final existing = Directory('${dir.path}/$newName');
    if (oldDir.existsSync() && !existing.existsSync()) {
      Directory newDir = await oldDir.rename('${dir.path}/$newName');
      name = newName;
      eduFile = File('${newDir.path}/$educationFile');
      expFile = File('${newDir.path}/$experienceFile');
      extFile = File('${newDir.path}/$extracurricularFile');
      honFile = File('${newDir.path}/$honorsFile');
      projFile = File('${newDir.path}/$projectsFile');
      refFile = File('${newDir.path}/$referencesFile');
      skiFile = File('${newDir.path}/$skillsFile');
      WriteFile(dir, eduFile, eduCont.text);
      WriteFile(dir, expFile, expCont.text);
      WriteFile(dir, extFile, extCont.text);
      WriteFile(dir, honFile, honCont.text);
      WriteFile(dir, projFile, projCont.text);
      WriteFile(dir, refFile, refCont.text);
      WriteFile(dir, skiFile, skillsCont.text);
    }
  }

  // Set Profile Directory
  Future<void> setProfDir() async {
    final parentDir = await profsDir;
    CreateDir(parentDir, name);
  }

  // Set Write New Files
  Future<void> setWriteNewFiles() async {
    final dir = await profsDir;
    final currDir = Directory('${dir.path}/$name');
    eduFile = File('${currDir.path}/$educationFile');
    expFile = File('${currDir.path}/$experienceFile');
    extFile = File('${currDir.path}/$extracurricularFile');
    honFile = File('${currDir.path}/$honorsFile');
    projFile = File('${currDir.path}/$projectsFile');
    refFile = File('${currDir.path}/$referencesFile');
    skiFile = File('${currDir.path}/$skillsFile');
    WriteFile(dir, eduFile, eduCont.text);
    WriteFile(dir, expFile, expCont.text);
    WriteFile(dir, extFile, extCont.text);
    WriteFile(dir, honFile, honCont.text);
    WriteFile(dir, projFile, projCont.text);
    WriteFile(dir, refFile, refCont.text);
    WriteFile(dir, skiFile, skillsCont.text);
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

List<Widget> ProfileEntry(BuildContext context, String title, TextEditingController controller, String hintText, {int? lines = 10}) {
  return [
    Center(
      child: Text(
        title,
        style: TextStyle(
          color: themeTextColor(context),
          fontSize: profileTitleSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    SizedBox(height: standardSizedBoxHeight),
    Center(
      child: Container(
        width: MediaQuery.of(context).size.width * profileContainerWidth,
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.multiline,
          maxLines: lines,
          decoration: InputDecoration(hintText: hintText.isEmpty ? null : hintText),
        ),
      ),
    ),
    SizedBox(height: 20),
  ];
}

Future<List<Directory>> RetrieveSortedProfiles() async {
  final profilesDir = await GetProfilesDir();
  final profilesList = profilesDir.listSync().whereType<Directory>().toList();
  profilesList.sort((a, b) => a.path.split('/').last.compareTo(b.path.split('/').last));
  return profilesList;
}
