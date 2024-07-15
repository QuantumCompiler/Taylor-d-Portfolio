import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../Context/Globals/GlobalContext.dart';
import '../Globals/ProfilesGlobals.dart';
import '../Globals/Globals.dart';
import '../Utilities/GlobalUtils.dart';

class ProfileEduCont {
  late TextEditingController desInfo;
  late TextEditingController degInfo;
  late TextEditingController schoolInfo;
  late DateTime? startTime;
  late DateTime? endTime;
  late bool graduated;
  ProfileEduCont() {
    desInfo = TextEditingController();
    degInfo = TextEditingController();
    schoolInfo = TextEditingController();
    startTime = DateTime.now();
    endTime = DateTime.now();
    graduated = false;
  }
  ProfileEduCont.fromJSON(Map<String, dynamic> json) {
    desInfo = TextEditingController(text: json['desInfo']);
    degInfo = TextEditingController(text: json['degInfo']);
    schoolInfo = TextEditingController(text: json['schoolInfo']);
    graduated = json['graduated'];
    startTime = DateTime.parse(json['startTime']);
    endTime = DateTime.parse(json['endTime']);
  }
  Map<String, dynamic> toJSON() {
    return {
      'desInfo': desInfo.text,
      'degInfo': degInfo.text,
      'schoolInfo': schoolInfo.text,
      'graduated': graduated,
      'startTime': startTime?.toIso8601String().split('T')[0],
      'endTime': endTime?.toIso8601String().split('T')[0],
    };
  }
}

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

  // Lists Of Types
  List<ProfileEduCont> eduContList = [];

  // Constructor
  Profile({this.name = ''}) {
    eduTitle = educationTitle;
    expTitle = experienceTitle;
    projTitle = projectsTitle;
    skiTitle = skillsTitle;
    eduContList = eduContList;
    setTempDir();
  }

  Future<void> CreateEduContJSON() async {
    await WriteEduContentToJSONFile('Temp/');
    await ReadEduContentFromJSON('Temp/');
  }

  // Create New Profile
  Future<void> CreateNewProfile(String profName) async {
    setProfName(profName);
    setProfDir();
    // setWriteNewFiles();
  }

  // Get Education Content
  Future<List<ProfileEduCont>> getEduCont() async {
    return eduContList;
  }

  // Print Education Content
  Future<void> printEduCont() async {
    for (int i = 0; i < eduContList.length; i++) {
      print('Entry ${i + 1}: Degree Info: ${eduContList[i].degInfo.text}, Description Info: ${eduContList[i].desInfo.text}, '
          'School Info: ${eduContList[i].schoolInfo.text}, Graduated: ${eduContList[i].graduated}, Start Time: ${eduContList[i].startTime}, '
          'End Time: ${eduContList[i].endTime}');
    }
  }

  // Set Education Content
  Future<void> setEduCont(List<ProfileEduCont> list) async {
    eduContList = list;
  }

  // Set Profile Name
  Future<void> setProfName(String profName) async {
    name = profName;
  }

  // Set Profile Directory
  Future<void> setProfDir() async {
    final parentDir = await profsDir;
    CreateDir(parentDir, name);
  }

  // Set Temp Directory
  Future<void> setTempDir() async {
    final parentDir = await profsDir;
    final temp = Directory('${parentDir.path}/Temp');
    if (temp.existsSync()) {
      temp.deleteSync(recursive: true);
    }
    CreateDir(parentDir, 'Temp');
  }

  Future<void> ReadEduContentFromJSON(String subDir) async {
    final profs = await profsDir;
    final file = File('${profs.path}/$subDir/EduCont.json');
    if (!file.existsSync()) {
      print('Education content json file does not exist.');
      return;
    }
    String jsonString = file.readAsStringSync();
    List<dynamic> jsonData = jsonDecode(jsonString);
    for (int i = 0; i < jsonData.length; i++) {
      print(jsonData[i]['desInfo']);
      print(jsonData[i]['degInfo']);
      print(jsonData[i]['schoolInfo']);
      print(jsonData[i]['graduated']);
      print(jsonData[i]['startTime']);
      print(jsonData[i]['endTime']);
    }
    print(jsonData);
  }

  // Write Education Content To JSON
  Future<void> WriteEduContentToJSONFile(String subDir) async {
    final profs = await profsDir;
    Directory desDir = Directory('${profs.path}/$subDir');
    if (!desDir.existsSync()) {
      desDir.createSync();
    }
    final file = File('${desDir.path}EduCont.json');
    if (file.existsSync()) {
      file.deleteSync();
    }
    List<Map<String, dynamic>> eduContJSON = eduContList.map((eduCont) => eduCont.toJSON()).toList();
    String jsonString = jsonEncode(eduContJSON);
    await file.writeAsString(jsonString);
  }
}

class EducationProfileEntry extends StatefulWidget {
  final Profile newProfile;

  const EducationProfileEntry({
    super.key,
    required this.newProfile,
  });

  @override
  EducationProfileEntryState createState() => EducationProfileEntryState();
}

class EducationProfileEntryState extends State<EducationProfileEntry> {
  List<ProfileEduCont> entries = [];

  @override
  void initState() {
    super.initState();
    if (widget.newProfile.eduContList.isNotEmpty) {
      entries = widget.newProfile.eduContList;
    } else {
      entries.add(ProfileEduCont());
    }
  }

  void addEntry(int index) {
    setState(() {
      entries.insert(index + 1, ProfileEduCont());
    });
  }

  void clearEntry(int index) {
    setState(() {
      entries[index].degInfo.text = '';
      entries[index].desInfo.text = '';
      entries[index].schoolInfo.text = '';
      entries[index].graduated = false;
      entries[index].startTime = DateTime.now();
      entries[index].endTime = DateTime.now();
    });
  }

  void deleteEntry(int index) {
    if (entries.length > 1) {
      setState(() {
        entries.removeAt(index);
      });
    }
  }

  List<ProfileEduCont> retrieveEntries() {
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          ...entries.asMap().entries.map(
            (entry) {
              int index = entry.key;
              ProfileEduCont entryData = entry.value;
              return buildContEntry(
                context,
                index,
                entryData,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildContEntry(
    BuildContext context,
    int index,
    ProfileEduCont entry,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: standardSizedBoxHeight),
        Center(
          child: Text(
            'Institution - ${index + 1}',
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
                      controller: entry.schoolInfo,
                      keyboardType: TextInputType.multiline,
                      maxLines: 1,
                      decoration: InputDecoration(hintText: 'Enter name here...'),
                      onChanged: (value) {
                        setState(() {
                          widget.newProfile.setEduCont(entries);
                        });
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  Tooltip(
                    message: 'Graduated From Institution ${index + 1}?',
                    child: Checkbox(
                      value: entry.graduated,
                      onChanged: (bool? value) {
                        setState(() {
                          entry.graduated = value ?? false;
                          widget.newProfile.setEduCont(entries);
                        });
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  Tooltip(
                    message: 'Select Start Date For Institution ${index + 1}',
                    child: IconButton(
                      icon: Icon(Icons.date_range),
                      onPressed: () async {
                        entry.startTime = await SelectDate(context);
                        widget.newProfile.setEduCont(entries);
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  Tooltip(
                    message: 'Select End Date For Institution ${index + 1}',
                    child: IconButton(
                      icon: Icon(Icons.date_range),
                      onPressed: () async {
                        entry.endTime = await SelectDate(context);
                        widget.newProfile.setEduCont(entries);
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: standardSizedBoxHeight),
              TextFormField(
                controller: entry.degInfo,
                keyboardType: TextInputType.multiline,
                maxLines: 1,
                decoration: InputDecoration(hintText: 'Enter degree(s) information here...'),
                onChanged: (value) {
                  setState(() {
                    widget.newProfile.setEduCont(entries);
                  });
                },
              ),
              SizedBox(height: standardSizedBoxHeight),
              TextFormField(
                controller: entry.desInfo,
                keyboardType: TextInputType.multiline,
                maxLines: 10,
                decoration: InputDecoration(hintText: 'Enter description here...'),
                onChanged: (value) {
                  setState(() {
                    widget.newProfile.setEduCont(entries);
                  });
                },
              ),
              SizedBox(height: standardSizedBoxHeight),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Tooltip(
                    message: 'Add Entry After Institution ${index + 1}',
                    child: IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        addEntry(index);
                        widget.newProfile.setEduCont(entries);
                      },
                    ),
                  ),
                  Tooltip(
                    message: 'Clear Entries For Institution ${index + 1}',
                    child: IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        clearEntry(index);
                        widget.newProfile.setEduCont(entries);
                      },
                    ),
                  ),
                  Tooltip(
                    message: 'Delete Entry For Institution ${index + 1}',
                    child: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        deleteEntry(index);
                        widget.newProfile.setEduCont(entries);
                      },
                    ),
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
