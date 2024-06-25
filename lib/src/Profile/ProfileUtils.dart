import 'dart:io';
import 'package:flutter/material.dart';
import '../Globals/Globals.dart';
import '../Themes/Themes.dart';

// Profile Class
class Profile {
  // Boolean
  bool init;

  // Directories
  Future<Directory> appDir = getAppDir();
  Future<Directory> cacheDir = getCacheDir();
  Future<Directory> profsDir = getProfilesDir();
  Future<Directory> supDir = getSupportDir();

  // Main Tiles
  late String educationTitle;
  late String experienceTitle;
  late String extracurricularTitle;
  late String honorsTitle;
  late String name;
  late String projectsTitle;
  late String referencesTitle;
  late String skillsTitle;

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
  Profile({required this.init}) {
    // Initialization
    if (init) {
      // Initialize Titles
      educationTitle = profileEduTitle;
      experienceTitle = profileExpTitle;
      extracurricularTitle = profileExtTitle;
      honorsTitle = profileHonTitle;
      projectsTitle = profileProjTitle;
      referencesTitle = profileRefTitle;
      skillsTitle = profileSkillsTitle;
      // Initialize Controllers
      eduCont = TextEditingController();
      expCont = TextEditingController();
      extCont = TextEditingController();
      honCont = TextEditingController();
      nameCont = TextEditingController();
      projCont = TextEditingController();
      refCont = TextEditingController();
      skillsCont = TextEditingController();
    }
  }

  // Setters

  // Set Profile Name
  Future<void> setProfName(String profName) async {
    name = profName;
  }

  // Set Profile Directory
  Future<void> setProfDir() async {
    final profs = await profsDir;
    final dir = Directory('${profs.path}/$name');
    if (!dir.existsSync()) {
      dir.createSync();
    }
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
