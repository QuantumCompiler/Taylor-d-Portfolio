import 'dart:io';
import 'package:flutter/material.dart';
import '../Context/Globals/GlobalContexts.dart';
import '../Globals/ProfilesGlobals.dart';
import '../Globals/Globals.dart';
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

class EduContEntry extends StatefulWidget {
  final BuildContext context;
  final String title;
  final TextEditingController nameController;
  final TextEditingController degreeController;
  final TextEditingController descriptionController;
  final bool graduated;
  final VoidCallback addEntry;
  final VoidCallback deleteEntry;
  final Function(bool) updateGraduated;
  final int? lines;

  EduContEntry({
    required Key key,
    required this.context,
    required this.title,
    required this.nameController,
    required this.degreeController,
    required this.descriptionController,
    required this.graduated,
    required this.addEntry,
    required this.deleteEntry,
    required this.updateGraduated,
    this.lines = 10,
  }) : super(key: key);

  @override
  EduContEntryState createState() => EduContEntryState();
}

class EduContEntryState extends State<EduContEntry> {
  late bool graduated;

  @override
  void initState() {
    super.initState();
    graduated = widget.graduated;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: standardSizedBoxHeight),
        Center(
          child: Text(
            widget.title,
            style: TextStyle(fontSize: secondaryTitles, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: standardSizedBoxHeight),
        Container(
          width: MediaQuery.of(context).size.width * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: widget.nameController,
                      keyboardType: TextInputType.multiline,
                      maxLines: 1,
                      decoration: InputDecoration(hintText: 'Enter name here...'),
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  Tooltip(
                    message: 'Graduated From Institution?',
                    child: Checkbox(
                      value: graduated,
                      onChanged: (bool? value) {
                        setState(() {
                          graduated = value ?? false;
                        });
                        widget.updateGraduated(graduated);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Graduated: ${graduated.toString()}')),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  Tooltip(
                    message: 'Select Start Date',
                    child: IconButton(
                      icon: Icon(Icons.date_range),
                      onPressed: () async {
                        DateTime? selectedDate = await SelectDate(context);
                        if (selectedDate != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Selected Date: ${selectedDate.toString().split(' ')[0]}')),
                          );
                        }
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  Tooltip(
                    message: 'Select End Date',
                    child: IconButton(
                      icon: Icon(Icons.date_range),
                      onPressed: () async {
                        DateTime? selectedDate = await SelectDate(context);
                        if (selectedDate != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Selected Date: ${selectedDate.toString().split(' ')[0]}')),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: standardSizedBoxHeight),
              TextFormField(
                controller: widget.degreeController,
                keyboardType: TextInputType.multiline,
                maxLines: 1,
                decoration: InputDecoration(hintText: 'Enter degree(s) information here...'),
              ),
              SizedBox(height: standardSizedBoxHeight),
              TextFormField(
                controller: widget.descriptionController,
                keyboardType: TextInputType.multiline,
                maxLines: widget.lines,
                decoration: InputDecoration(hintText: 'Enter description here...'),
              ),
              SizedBox(height: standardSizedBoxHeight),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: widget.addEntry,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: widget.deleteEntry,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
