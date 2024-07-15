import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '../Context/Globals/GlobalContext.dart';
import '../Globals/ProfilesGlobals.dart';
import '../Globals/Globals.dart';
import '../Utilities/GlobalUtils.dart';

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Education Profile Content
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
class ProfileEduCont {
  late TextEditingController desInfo;
  late TextEditingController degInfo;
  late TextEditingController schoolInfo;
  late DateTime? startDate;
  late DateTime? endDate;
  late bool graduated;
  ProfileEduCont() {
    desInfo = TextEditingController();
    degInfo = TextEditingController();
    schoolInfo = TextEditingController();
    startDate = DateTime.now();
    endDate = DateTime.now();
    graduated = false;
  }
  ProfileEduCont.fromJSON(Map<String, dynamic> json) {
    desInfo = TextEditingController(text: json['desInfo']);
    degInfo = TextEditingController(text: json['degInfo']);
    schoolInfo = TextEditingController(text: json['schoolInfo']);
    startDate = DateTime.parse(json['startDate']);
    endDate = DateTime.parse(json['endDate']);
    graduated = json['graduated'];
  }
  Map<String, dynamic> toJSON() {
    return {
      'desInfo': desInfo.text,
      'degInfo': degInfo.text,
      'schoolInfo': schoolInfo.text,
      'startDate': startDate?.toIso8601String().split('T')[0],
      'endDate': endDate?.toIso8601String().split('T')[0],
      'graduated': graduated,
    };
  }
}

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Experience Profile Content
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
class ProfileExpCont {
  late TextEditingController companyName;
  late TextEditingController positionName;
  late TextEditingController desInfo;
  late DateTime? startDate;
  late DateTime? endDate;
  late bool stillWorking;
  ProfileExpCont() {
    companyName = TextEditingController();
    positionName = TextEditingController();
    desInfo = TextEditingController();
    startDate = DateTime.now();
    endDate = DateTime.now();
    stillWorking = false;
  }
  ProfileExpCont.fromJSON(Map<String, dynamic> json) {
    companyName = TextEditingController(text: json['companyName']);
    positionName = TextEditingController(text: json['positionName']);
    desInfo = TextEditingController(text: json['desInfo']);
    startDate = DateTime.parse(json['startDate']);
    endDate = DateTime.parse(json['endDate']);
    stillWorking = json['stillWorking'];
  }
  Map<String, dynamic> toJSON() {
    return {
      'companyName': companyName.text,
      'positionName': positionName.text,
      'desInfo': desInfo.text,
      'startDate': startDate?.toIso8601String().split('T')[0],
      'endDate': endDate?.toIso8601String().split('T')[0],
      'stillWorking': stillWorking,
    };
  }
}

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Profile Class
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
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
  List<ProfileExpCont> expContList = [];

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
    await WriteContentToJSON('Temp/', 'EduCont.json', eduContList);
    await ReadEduContentFromJSON('Temp/');
  }

  Future<void> CreateExpContJSON() async {
    await WriteContentToJSON('Temp/', 'ExpCont.json', expContList);
    await ReadExpContentFromJSON('Temp/');
  }

  // Create New Profile
  Future<void> CreateNewProfile(String profName) async {
    setProfName(profName);
    setProfDir();
    // setWriteNewFiles();
  }

  // Set Education Content
  Future<void> setEduCont(List<ProfileEduCont> list) async {
    eduContList = list;
  }

  Future<void> setExpCont(List<ProfileExpCont> list) async {
    expContList = list;
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

  // Read Education Content From JSON
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
      print(jsonData[i]['startDate']);
      print(jsonData[i]['endDate']);
    }
  }

  Future<void> ReadExpContentFromJSON(String subDir) async {
    final profs = await profsDir;
    final file = File('${profs.path}/$subDir/ExpCont.json');
    if (!file.existsSync()) {
      print('Experience content json file does not exist.');
      return;
    }
    String jsonString = file.readAsStringSync();
    List<dynamic> jsonData = jsonDecode(jsonString);
    for (int i = 0; i < jsonData.length; i++) {
      print(jsonData[i]['companyName']);
      print(jsonData[i]['positionName']);
      print(jsonData[i]['desInfo']);
      print(jsonData[i]['stillWorking']);
      print(jsonData[i]['startDate']);
      print(jsonData[i]['endDate']);
    }
  }

  // companyName = TextEditingController(text: json['companyName']);
  // positionName = TextEditingController(text: json['positionName']);
  // desInfo = TextEditingController(text: json['desInfo']);
  // startDate = DateTime.parse(json['startDate']);
  // endDate = DateTime.parse(json['endDate']);
  // stillWorking = json['stillWorking'];

  // Read Experience Content From JSON

  // Write Content To JSON
  Future<void> WriteContentToJSON<T>(String subDir, String fileName, List<T> list) async {
    final profs = await profsDir;
    Directory desDir = Directory('${profs.path}/$subDir');
    if (!desDir.existsSync()) {
      desDir.createSync();
    }
    final file = File('${desDir.path}/$fileName');
    if (file.existsSync()) {
      file.deleteSync();
    }

    List<Map<String, dynamic>> contJSON = list.map((cont) {
      if (cont is ProfileEduCont) {
        return (cont as ProfileEduCont).toJSON();
      } else if (cont is ProfileExpCont) {
        return (cont as ProfileExpCont).toJSON();
      } else {
        throw Exception("Type T does not have a toJSON method");
      }
    }).toList();

    String jsonString = jsonEncode(contJSON);
    await file.writeAsString(jsonString);
  }
}

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Education Profile Entry
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
class EducationProfileEntry extends StatefulWidget {
  final Profile profile;

  const EducationProfileEntry({
    super.key,
    required this.profile,
  });

  @override
  EducationProfileEntryState createState() => EducationProfileEntryState();
}

class EducationProfileEntryState extends State<EducationProfileEntry> {
  List<ProfileEduCont> entries = [];

  @override
  void initState() {
    super.initState();
    if (widget.profile.eduContList.isNotEmpty) {
      entries = widget.profile.eduContList;
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
      entries[index].startDate = DateTime.now();
      entries[index].endDate = DateTime.now();
    });
  }

  void deleteEntry(int index) {
    if (entries.length > 1) {
      setState(() {
        entries.removeAt(index);
      });
    }
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
                          widget.profile.setEduCont(entries);
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
                          widget.profile.setEduCont(entries);
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
                        entry.startDate = await SelectDate(context);
                        widget.profile.setEduCont(entries);
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  Tooltip(
                    message: 'Select End Date For Institution ${index + 1}',
                    child: IconButton(
                      icon: Icon(Icons.date_range),
                      onPressed: () async {
                        entry.endDate = await SelectDate(context);
                        widget.profile.setEduCont(entries);
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
                    widget.profile.setEduCont(entries);
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
                    widget.profile.setEduCont(entries);
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
                        widget.profile.setEduCont(entries);
                      },
                    ),
                  ),
                  Tooltip(
                    message: 'Clear Entries For Institution ${index + 1}',
                    child: IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        clearEntry(index);
                        widget.profile.setEduCont(entries);
                      },
                    ),
                  ),
                  Tooltip(
                    message: 'Delete Entry For Institution ${index + 1}',
                    child: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        deleteEntry(index);
                        widget.profile.setEduCont(entries);
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

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Experience Profile Entry
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
class ExperienceProfileEntry extends StatefulWidget {
  final Profile profile;

  const ExperienceProfileEntry({
    super.key,
    required this.profile,
  });

  @override
  ExperienceProfileEntryState createState() => ExperienceProfileEntryState();
}

class ExperienceProfileEntryState extends State<ExperienceProfileEntry> {
  List<ProfileExpCont> entries = [];

  @override
  void initState() {
    super.initState();
    if (widget.profile.expContList.isNotEmpty) {
      entries = widget.profile.expContList;
    } else {
      entries.add(ProfileExpCont());
    }
  }

  void addEntry(int index) {
    setState(() {
      entries.insert(index + 1, ProfileExpCont());
    });
  }

  void clearEntry(int index) {
    setState(() {
      entries[index].companyName.text = '';
      entries[index].positionName.text = '';
      entries[index].desInfo.text = '';
      entries[index].startDate = DateTime.now();
      entries[index].endDate = DateTime.now();
      entries[index].stillWorking = false;
    });
  }

  void deleteEntry(int index) {
    if (entries.length > 1) {
      setState(() {
        entries.removeAt(index);
      });
    }
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
              ProfileExpCont entryData = entry.value;
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
    ProfileExpCont entry,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: standardSizedBoxHeight),
        Center(
          child: Text(
            'Work Experience - ${index + 1}',
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
                      controller: entry.companyName,
                      keyboardType: TextInputType.multiline,
                      maxLines: 1,
                      decoration: InputDecoration(hintText: 'Enter company name here...'),
                      onChanged: (value) {
                        setState(() {
                          widget.profile.setExpCont(entries);
                        });
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  Tooltip(
                    message: 'Still Working At Work Experience ${index + 1}?',
                    child: Checkbox(
                      value: entry.stillWorking,
                      onChanged: (bool? value) {
                        setState(() {
                          entry.stillWorking = value ?? false;
                          widget.profile.setExpCont(entries);
                        });
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  Tooltip(
                    message: 'Select Start Date For Work Experience ${index + 1}',
                    child: IconButton(
                      icon: Icon(Icons.date_range),
                      onPressed: () async {
                        entry.startDate = await SelectDate(context);
                        widget.profile.setExpCont(entries);
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  Tooltip(
                    message: 'Select End Date For Work Experience ${index + 1}',
                    child: IconButton(
                      icon: Icon(Icons.date_range),
                      onPressed: () async {
                        entry.endDate = await SelectDate(context);
                        widget.profile.setExpCont(entries);
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: standardSizedBoxHeight),
              TextFormField(
                controller: entry.positionName,
                keyboardType: TextInputType.multiline,
                maxLines: 1,
                decoration: InputDecoration(hintText: 'Enter position info here...'),
                onChanged: (value) {
                  setState(() {
                    widget.profile.setExpCont(entries);
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
                    widget.profile.setExpCont(entries);
                  });
                },
              ),
              SizedBox(height: standardSizedBoxHeight),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Tooltip(
                    message: 'Add Entry After Work Experience ${index + 1}',
                    child: IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        addEntry(index);
                        widget.profile.setExpCont(entries);
                      },
                    ),
                  ),
                  Tooltip(
                    message: 'Clear Entries For Work Experience ${index + 1}',
                    child: IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        clearEntry(index);
                        widget.profile.setExpCont(entries);
                      },
                    ),
                  ),
                  Tooltip(
                    message: 'Delete Entry For Work Experience ${index + 1}',
                    child: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        deleteEntry(index);
                        widget.profile.setExpCont(entries);
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
