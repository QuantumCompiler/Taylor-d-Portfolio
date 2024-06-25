import 'dart:io';
import 'package:flutter/material.dart';
import '../Globals/Globals.dart';
import '../Themes/Themes.dart';

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
  late File skillsFile;

  // Main Titles & Name
  late String educationTitle;
  late String experienceTitle;
  late String extracurricularTitle;
  late String honorsTitle;
  late String name;
  late String projectsTitle;
  late String referencesTitle;
  late String skillsTitle;

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
    educationTitle = profileEduTitle;
    experienceTitle = profileExpTitle;
    extracurricularTitle = profileExtTitle;
    honorsTitle = profileHonTitle;
    projectsTitle = profileProjTitle;
    referencesTitle = profileRefTitle;
    skillsTitle = profileSkillsTitle;
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
    eduFile = File('${currProf.path}/$profileEduFile');
    expFile = File('${currProf.path}/$profileExpFile');
    extFile = File('${currProf.path}/$profileExtFile');
    honFile = File('${currProf.path}/$profileHonFile');
    projFile = File('${currProf.path}/$profileProjFile');
    refFile = File('${currProf.path}/$profileRefFile');
    skillsFile = File('${currProf.path}/$profileSkillsFile');
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
    if (await skillsFile.exists()) {
      skills = await skillsFile.readAsString();
      skillsCont.text = skills;
    }
  }

  // Setters

  // Set Profile Name
  Future<void> setProfName(String profName) async {
    name = profName;
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
    eduFile = File('${currDir.path}/$profileEduFile');
    expFile = File('${currDir.path}/$profileExpFile');
    extFile = File('${currDir.path}/$profileExtFile');
    honFile = File('${currDir.path}/$profileHonFile');
    projFile = File('${currDir.path}/$profileProjFile');
    refFile = File('${currDir.path}/$profileRefFile');
    skillsFile = File('${currDir.path}/$profileSkillsFile');
    WriteFile(dir, eduFile, eduCont.text);
    WriteFile(dir, expFile, expCont.text);
    WriteFile(dir, extFile, extCont.text);
    WriteFile(dir, honFile, honCont.text);
    WriteFile(dir, projFile, projCont.text);
    WriteFile(dir, refFile, refCont.text);
    WriteFile(dir, skillsFile, skillsCont.text);
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
