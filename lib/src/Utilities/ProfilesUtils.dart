import 'dart:io';
import 'package:flutter/material.dart';
import '../Globals/ProfilesGlobals.dart';
import '../Globals/Globals.dart';
import '../Themes/Themes.dart';
import '../Utilities/GlobalUtils.dart';

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
  late File projFile;
  late File skiFile;

  // Main Titles & Name
  late String eduTitle;
  late String expTitle;
  late String name;
  late String projTitle;
  late String skiTitle;

  // Contents
  late String education;
  late String experience;
  late String projects;
  late String skills;

  // Controllers
  late TextEditingController eduCont;
  late TextEditingController expCont;
  late TextEditingController nameCont;
  late TextEditingController projCont;
  late TextEditingController skillsCont;

  // Constructor
  Profile({this.name = ''}) {
    eduTitle = educationTitle;
    expTitle = experienceTitle;
    projTitle = projectsTitle;
    skiTitle = skillsTitle;
    eduCont = TextEditingController();
    expCont = TextEditingController();
    nameCont = TextEditingController();
    projCont = TextEditingController();
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
    projFile = File('${currProf.path}/$projectsFile');
    skiFile = File('${currProf.path}/$skillsFile');
    if (await eduFile.exists()) {
      education = await eduFile.readAsString();
      eduCont.text = education;
    }
    if (await expFile.exists()) {
      experience = await expFile.readAsString();
      expCont.text = experience;
    }
    if (await projFile.exists()) {
      projects = await projFile.readAsString();
      projCont.text = projects;
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
    Directory newDir;
    if (oldDir.existsSync() && !existing.existsSync()) {
      newDir = await oldDir.rename('${dir.path}/$newName');
      name = newName;
    } else {
      newDir = oldDir;
    }
    eduFile = File('${newDir.path}/$educationFile');
    expFile = File('${newDir.path}/$experienceFile');
    projFile = File('${newDir.path}/$projectsFile');
    skiFile = File('${newDir.path}/$skillsFile');
    await WriteFile(dir, eduFile, eduCont.text);
    await WriteFile(dir, expFile, expCont.text);
    await WriteFile(dir, projFile, projCont.text);
    await WriteFile(dir, skiFile, skillsCont.text);
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
    projFile = File('${currDir.path}/$projectsFile');
    skiFile = File('${currDir.path}/$skillsFile');
    WriteFile(dir, eduFile, eduCont.text);
    WriteFile(dir, expFile, expCont.text);
    WriteFile(dir, projFile, projCont.text);
    WriteFile(dir, skiFile, skillsCont.text);
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
