import 'dart:io';
import 'package:flutter/material.dart';
import '../Globals/Globals.dart';

// Profile Class
class Profile {
  // Directories
  Future<Directory> appDir = getAppDir();
  Future<Directory> cacheDir = getCacheDir();
  Future<Directory> profsDir = getProfilesDir();
  Future<Directory> supDir = getSupportDir();

  // Main Data
  String education = '';
  String experience = '';
  String extracurricular = '';
  String honors = '';
  String name = '';
  String projects = '';
  String references = '';
  String skills = '';

  // Controllers
  TextEditingController eduCont = TextEditingController();
  TextEditingController expCont = TextEditingController();
  TextEditingController extCont = TextEditingController();
  TextEditingController honCont = TextEditingController();
  TextEditingController namCont = TextEditingController();
  TextEditingController proCont = TextEditingController();
  TextEditingController refCont = TextEditingController();
  TextEditingController skiCont = TextEditingController();

  // Constructor
  Profile({
    required this.name,
  }) {
    setProfDir();
  }

  // Getters

  // Get Data
  List<String> getData() {
    List<String> data = [education, experience, extracurricular, honors, name, projects, references, skills];
    return data;
  }

  // Get Controllers
  List<TextEditingController> getControllers() {
    List<TextEditingController> controllers = [eduCont, expCont, honCont, namCont, proCont, refCont, skiCont];
    return controllers;
  }

  // Setters

  // Set Profile Directory
  Future<void> setProfDir() async {
    final profs = await profsDir;
    final dir = Directory('${profs.path}/$name');
    if (!dir.existsSync()) {
      dir.createSync();
    }
  }
}
