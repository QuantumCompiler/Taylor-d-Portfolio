import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../Context/Globals/GlobalContext.dart';
import '../Globals/Globals.dart';
import '../Globals/ProfilesGlobals.dart';
import '../Utilities/GlobalUtils.dart';

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Profile Class
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
class Profile {
  // Boolean
  final bool? newProfile;

  // Files
  late File covFile;
  late File eduFile;
  late File expFile;
  late File projFile;
  late File profFile;
  late File skiFile;

  // Strings
  late String name;

  // Lists Of Types
  List<ProfileCLCont> coverLetterContList = [];
  List<ProfileEduCont> eduContList = [];
  List<ProfileExpCont> expContList = [];
  List<ProfileProjCont> projContList = [];
  List<ProfileSkillsCont> skillsContList = [];

  Profile._({
    required this.newProfile,
    required this.name,
    required this.coverLetterContList,
    required this.eduContList,
    required this.expContList,
    required this.projContList,
    required this.skillsContList,
  });

  static Future<Profile> create({String name = '', required bool newProfile}) async {
    List<ProfileCLCont> coverLetterContList = [];
    List<ProfileEduCont> eduContList = [];
    List<ProfileExpCont> expContList = [];
    List<ProfileProjCont> projContList = [];
    List<ProfileSkillsCont> skillsContList = [];

    if (newProfile) {
      coverLetterContList = await LoadCLCont('Temp/');
      eduContList = await LoadEduCont('Temp/');
      expContList = await LoadExpCont('Temp/');
      projContList = await LoadProjectsCont('Temp/');
      skillsContList = await LoadSkillsCont('Temp/');
    }

    return Profile._(
      newProfile: newProfile,
      name: name,
      coverLetterContList: coverLetterContList,
      eduContList: eduContList,
      expContList: expContList,
      projContList: projContList,
      skillsContList: skillsContList,
    );
  }

  Future<void> CreateEduContJSON() async {
    await WriteContentToJSON('Temp/', 'EduCont.json', eduContList);
    await ReadEduContentFromJSON('Temp/');
  }

  Future<void> CreateExpContJSON() async {
    await WriteContentToJSON('Temp/', 'ExpCont.json', expContList);
    await ReadExpContentFromJSON('Temp/');
  }

  Future<void> CreateProjContJSON() async {
    await WriteContentToJSON('Temp/', 'ProjCont.json', projContList);
    await ReadProjContentFromJSON('Temp/');
  }

  Future<void> CreateSkillsContJSON() async {
    await WriteContentToJSON('Temp/', 'SkillsCont.json', skillsContList);
    await ReadSkillsContentFromJSON('Temp/');
  }

  // Create New Profile
  Future<void> CreateNewProfile(String profName) async {
    setProfName(profName);
    setProfDir();
    // setWriteNewFiles();
  }

  // Load Cover Letter Contents
  static Future<List<ProfileCLCont>> LoadCLCont(String subDir) async {
    try {
      final masterDir = await getApplicationDocumentsDirectory();
      final jsonFile = File('${masterDir.path}/$subDir/CLCont.json');
      final fileExists = await jsonFile.exists();
      if (fileExists) {
        final jsonString = await jsonFile.readAsString();
        final List<dynamic> jsonData = jsonDecode(jsonString);
        final List<ProfileCLCont> entries = jsonData.map((entry) => ProfileCLCont.fromJSON(entry)).toList();
        return entries;
      }
    } catch (e) {
      throw ('An error occurred while loading cover letter contents: $e');
    }
    return [];
  }

  // Load Education Contents
  static Future<List<ProfileEduCont>> LoadEduCont(String subDir) async {
    try {
      final masterDir = await getApplicationDocumentsDirectory();
      final jsonFile = File('${masterDir.path}/$subDir/EduCont.json');
      final fileExists = await jsonFile.exists();
      if (fileExists) {
        final jsonString = await jsonFile.readAsString();
        final List<dynamic> jsonData = jsonDecode(jsonString);
        final List<ProfileEduCont> entries = jsonData.map((entry) => ProfileEduCont.fromJSON(entry)).toList();
        return entries;
      }
    } catch (e) {
      throw ('An error occurred while loading education contents: $e');
    }
    return [];
  }

  // Load Experience Contents
  static Future<List<ProfileExpCont>> LoadExpCont(String subDir) async {
    try {
      final masterDir = await getApplicationDocumentsDirectory();
      final jsonFile = File('${masterDir.path}/$subDir/ExpCont.json');
      final fileExists = await jsonFile.exists();
      if (fileExists) {
        final jsonString = await jsonFile.readAsString();
        final List<dynamic> jsonData = jsonDecode(jsonString);
        final List<ProfileExpCont> entries = jsonData.map((entry) => ProfileExpCont.fromJSON(entry)).toList();
        return entries;
      }
    } catch (e) {
      throw ('An error occurred while loading experience contents: $e');
    }
    return [];
  }

  // Load Projects Contents
  static Future<List<ProfileProjCont>> LoadProjectsCont(String subDir) async {
    try {
      final masterDir = await getApplicationDocumentsDirectory();
      final jsonFile = File('${masterDir.path}/$subDir/ProjCont.json');
      final fileExists = await jsonFile.exists();
      if (fileExists) {
        final jsonString = await jsonFile.readAsString();
        final List<dynamic> jsonData = jsonDecode(jsonString);
        final List<ProfileProjCont> entries = jsonData.map((entry) => ProfileProjCont.fromJSON(entry)).toList();
        return entries;
      }
    } catch (e) {
      throw ('An error occurred while loading projects contents: $e');
    }
    return [];
  }

  // Load Skills Contents
  static Future<List<ProfileSkillsCont>> LoadSkillsCont(String subDir) async {
    try {
      final masterDir = await getApplicationDocumentsDirectory();
      final jsonFile = File('${masterDir.path}/$subDir/SkillsCont.json');
      final fileExists = await jsonFile.exists();
      if (fileExists) {
        final jsonString = await jsonFile.readAsString();
        final List<dynamic> jsonData = jsonDecode(jsonString);
        final List<ProfileSkillsCont> entries = jsonData.map((entry) => ProfileSkillsCont.fromJSON(entry)).toList();
        return entries;
      }
    } catch (e) {
      throw ('An error occurred while loading skills contents: $e');
    }
    return [];
  }

  // Set Cover Letter Pitch Content
  Future<void> setCLCont(List<ProfileCLCont> list) async {
    coverLetterContList = list;
  }

  // Set Education Content
  Future<void> setEduCont(List<ProfileEduCont> list) async {
    eduContList = list;
  }

  // Set Experience Content
  Future<void> setExpCont(List<ProfileExpCont> list) async {
    expContList = list;
  }

  // Set Projects Content
  Future<void> setProjCont(List<ProfileProjCont> list) async {
    projContList = list;
  }

  // Set Skills Content
  Future<void> setSkillsCont(List<ProfileSkillsCont> list) async {
    skillsContList = list;
  }

  // Set Profile Name
  Future<void> setProfName(String profName) async {
    name = profName;
  }

  // Set Profile Directory
  Future<void> setProfDir() async {
    final masterDir = await getApplicationDocumentsDirectory();
    Directory parentDir = Directory('${masterDir.path}/Profiles/');
    CreateDir(parentDir, name);
  }

  // Finish Implementation Here!!!!
  Future<void> WriteNewCLCont(String jsonDir) async {
    await WriteContentToJSON(jsonDir, 'CLCont.json', coverLetterContList);
    try {
      final masterDir = await getApplicationDocumentsDirectory();
      final profilesDir = Directory('${masterDir.path}/Profiles');
      final currDir = Directory('${profilesDir.path}/$name');
      if (!currDir.existsSync()) {
        currDir.create();
      }
      final file = File('${masterDir.path}/$jsonDir/CLCont.json');
      if (await file.exists()) {
        covFile = File('${masterDir.path}/Profiles/$name/$coverLetterFile');
        if (covFile.existsSync()) {
          covFile.deleteSync();
        }
        String jsonString = file.readAsStringSync();
        List<dynamic> jsonData = jsonDecode(jsonString);
        String content = '';
        for (int i = 0; i < jsonData.length; i++) {
          content += jsonData[i]['about'];
        }
        await WriteFile(currDir, covFile, content);
      }
    } catch (e) {
      throw ('Error occurred: $e');
    }
  }

  Future<void> WriteProfile(String jsonDir, String destDir) async {
    final masterDir = await getApplicationDocumentsDirectory();
    final File file = File('${masterDir.path}/$destDir/Profile.json');
    final File covFile = File('${masterDir.path}/$jsonDir/CLCont.json');
    final File eduFile = File('${masterDir.path}/$jsonDir/EduCont.json');
    final File expFile = File('${masterDir.path}/$jsonDir/ExpCont.json');
    final File proFile = File('${masterDir.path}/$jsonDir/ProjCont.json');
    final File skiFile = File('${masterDir.path}/$jsonDir/SkillsCont.json');
    if (covFile.existsSync() && eduFile.existsSync() && expFile.existsSync() && proFile.existsSync() && skiFile.existsSync()) {
      final List<dynamic> covData = jsonDecode(await covFile.readAsString());
      final List<dynamic> eduData = jsonDecode(await eduFile.readAsString());
      final List<dynamic> expData = jsonDecode(await expFile.readAsString());
      final List<dynamic> proData = jsonDecode(await proFile.readAsString());
      final List<dynamic> skiData = jsonDecode(await skiFile.readAsString());
      final Map<String, dynamic> combinedJSON = {
        'name': name,
        'coverLetter': covData,
        'education': eduData,
        'experience': expData,
        'projects': proData,
        'skills': skiData,
      };
      try {
        final String jsonString = jsonEncode(combinedJSON);
        await file.writeAsString(jsonString);
      } catch (e) {
        throw ('Error ocurred in writing profile file: $e');
      }
    } else {
      if (kDebugMode) {
        print('Necessary files do not exist to write profile file.');
      }
    }
  }

  // Read Education Content From JSON
  Future<void> ReadEduContentFromJSON(String subDir) async {
    final masterDir = await getApplicationDocumentsDirectory();
    final file = File('${masterDir.path}/$subDir/EduCont.json');
    if (!file.existsSync()) {
      print('Education content json file does not exist.');
      return;
    }
    String jsonString = file.readAsStringSync();
    List<dynamic> jsonData = jsonDecode(jsonString);
    for (int i = 0; i < jsonData.length; i++) {
      print(jsonData[i]['name']);
      print(jsonData[i]['degree']);
      print(jsonData[i]['description']);
      print(jsonData[i]['start']);
      print(jsonData[i]['end']);
      print(jsonData[i]['graduated']);
    }
  }

  // Read Experience Content From JSON
  Future<void> ReadExpContentFromJSON(String subDir) async {
    final masterDir = await getApplicationDocumentsDirectory();
    final file = File('${masterDir.path}/$subDir/ExpCont.json');
    if (!file.existsSync()) {
      print('Experience content json file does not exist.');
      return;
    }
    String jsonString = file.readAsStringSync();
    List<dynamic> jsonData = jsonDecode(jsonString);
    for (int i = 0; i < jsonData.length; i++) {
      print(jsonData[i]['name']);
      print(jsonData[i]['position']);
      print(jsonData[i]['description']);
      print(jsonData[i]['start']);
      print(jsonData[i]['end']);
      print(jsonData[i]['working']);
    }
  }

  // Read Projects Content From JSON
  Future<void> ReadProjContentFromJSON(String subDir) async {
    final masterDir = await getApplicationDocumentsDirectory();
    final file = File('${masterDir.path}/$subDir/ProjCont.json');
    if (!file.existsSync()) {
      print('Projects content json file does not exist.');
      return;
    }
    String jsonString = file.readAsStringSync();
    List<dynamic> jsonData = jsonDecode(jsonString);
    for (int i = 0; i < jsonData.length; i++) {
      print(jsonData[i]['projName']);
      print(jsonData[i]['roleName']);
      print(jsonData[i]['description']);
      print(jsonData[i]['completed']);
      print(jsonData[i]['date']);
    }
  }

  // Read Projects Content From JSON
  Future<void> ReadSkillsContentFromJSON(String subDir) async {
    final masterDir = await getApplicationDocumentsDirectory();
    final file = File('${masterDir.path}/$subDir/SkillsCont.json');
    if (!file.existsSync()) {
      print('Skills content json file does not exist.');
      return;
    }
    String jsonString = file.readAsStringSync();
    List<dynamic> jsonData = jsonDecode(jsonString);
    for (int i = 0; i < jsonData.length; i++) {
      print(jsonData[i]['skillCategory']);
      print(jsonData[i]['description']);
    }
  }

  // Write Content To JSON
  Future<void> WriteContentToJSON<T>(String subDir, String fileName, List<T> list) async {
    final masterDir = await getApplicationDocumentsDirectory();
    Directory desDir = Directory('${masterDir.path}/$subDir');
    if (!desDir.existsSync()) {
      desDir.createSync();
    }
    final file = File('${desDir.path}/$fileName');
    if (file.existsSync()) {
      file.deleteSync();
    }
    List<Map<String, dynamic>> contJSON = list.map((cont) {
      if (cont is ProfileCLCont) {
        return (cont as ProfileCLCont).toJSON();
      } else if (cont is ProfileEduCont) {
        return (cont as ProfileEduCont).toJSON();
      } else if (cont is ProfileExpCont) {
        return (cont as ProfileExpCont).toJSON();
      } else if (cont is ProfileProjCont) {
        return (cont as ProfileProjCont).toJSON();
      } else if (cont is ProfileSkillsCont) {
        return (cont as ProfileSkillsCont).toJSON();
      } else {
        throw Exception("Type T does not have a toJSON method");
      }
    }).toList();
    String jsonString = jsonEncode(contJSON);
    await file.writeAsString(jsonString);
  }
}

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Cover Letter Pitch Profile Content
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
class ProfileCLCont {
  late TextEditingController about;
  ProfileCLCont() {
    about = TextEditingController();
  }
  ProfileCLCont.fromJSON(Map<String, dynamic> json) {
    about = TextEditingController(text: json['about'] ?? '');
  }
  Map<String, dynamic> toJSON() {
    return {
      'about': about.text,
    };
  }
}

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Cover Letter Pitch Profile Entry
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
class CoverLetterProfilePitchEntry extends StatefulWidget {
  final Profile profile;

  const CoverLetterProfilePitchEntry({
    super.key,
    required this.profile,
  });

  @override
  CoverLetterProfilePitchEntryState createState() => CoverLetterProfilePitchEntryState();
}

class CoverLetterProfilePitchEntryState extends State<CoverLetterProfilePitchEntry> {
  List<ProfileCLCont> entries = [];

  @override
  void initState() {
    super.initState();
    initializeEntries();
  }

  void initializeEntries() {
    if (widget.profile.coverLetterContList.isNotEmpty) {
      entries = widget.profile.coverLetterContList;
    } else {
      entries.add(ProfileCLCont());
    }
  }

  void clearEntry(int index) async {
    setState(() {
      entries[index].about.text = '';
    });
    await widget.profile.setCLCont(entries);
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
              ProfileCLCont entryData = entry.value;
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
    ProfileCLCont entry,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: standardSizedBoxHeight),
        Center(
          child: Text(
            'About',
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
              TextFormField(
                controller: entry.about,
                keyboardType: TextInputType.multiline,
                maxLines: 15,
                decoration: InputDecoration(hintText: 'Enter details about you here...'),
                onChanged: (value) async {
                  await widget.profile.setCLCont(entries);
                },
              ),
            ],
          ),
        ),
        SizedBox(height: standardSizedBoxHeight),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Tooltip(
              message: 'Clear Cover Letter About',
              child: IconButton(
                icon: Icon(Icons.clear),
                onPressed: () async {
                  clearEntry(index);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Education Profile Content
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
class ProfileEduCont {
  late TextEditingController description;
  late TextEditingController degree;
  late TextEditingController name;
  DateTime? start;
  DateTime? end;
  late bool graduated;
  late bool include;

  ProfileEduCont() {
    description = TextEditingController();
    degree = TextEditingController();
    name = TextEditingController();
    start = DateTime.now();
    end = DateTime.now();
    graduated = false;
    include = false;
  }

  ProfileEduCont.fromJSON(Map<String, dynamic> json) {
    description = TextEditingController(text: json['description'] ?? '');
    degree = TextEditingController(text: json['degree'] ?? '');
    name = TextEditingController(text: json['name'] ?? '');
    start = json['start'] != null ? DateTime.parse(json['start']) : null;
    end = json['end'] != null ? DateTime.parse(json['end']) : null;
    graduated = json['graduated'] ?? false;
    include = json['include'] ?? false;
  }

  Map<String, dynamic> toJSON() {
    return {
      'name': name.text,
      'degree': degree.text,
      'description': description.text,
      'start': start?.toIso8601String().split('T')[0],
      'end': end?.toIso8601String().split('T')[0],
      'graduated': graduated,
      'include': include,
    };
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
    initializeEntries();
  }

  void initializeEntries() async {
    if (widget.profile.eduContList.isNotEmpty) {
      entries = widget.profile.eduContList;
    } else {
      entries.add(ProfileEduCont());
    }
  }

  void addEntry(int index) async {
    setState(() {
      entries.insert(index + 1, ProfileEduCont());
    });
    await widget.profile.setEduCont(entries);
  }

  void clearEntry(int index) async {
    setState(() {
      entries[index].name.text = '';
      entries[index].degree.text = '';
      entries[index].description.text = '';
      entries[index].start = DateTime.now();
      entries[index].end = DateTime.now();
      entries[index].graduated = false;
      entries[index].include = false;
    });
    await widget.profile.setEduCont(entries);
  }

  void deleteEntry(int index) async {
    if (entries.length > 1) {
      setState(() {
        entries.removeAt(index);
      });
      await widget.profile.setEduCont(entries);
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
            entry.name.text.isNotEmpty ? entry.name.text : "Institution ${index + 1}",
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
                      controller: entry.name,
                      keyboardType: TextInputType.multiline,
                      maxLines: 1,
                      decoration: InputDecoration(hintText: 'Enter name here...'),
                      onChanged: (value) async {
                        setState(() {});
                        await widget.profile.setEduCont(entries);
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  Tooltip(
                    message: entry.name.text.isNotEmpty ? "Graduated From ${entry.name.text}?" : "Graduated From Institution ${index + 1}?",
                    child: Checkbox(
                      value: entry.graduated,
                      onChanged: (bool? value) async {
                        setState(() {
                          entry.graduated = value ?? false;
                        });
                        await widget.profile.setEduCont(entries);
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  Tooltip(
                    message: entry.name.text.isNotEmpty ? "Include ${entry.name.text} In Portfolio?" : "Include Institution ${index + 1} In Portfolio?",
                    child: Checkbox(
                      value: entry.include,
                      onChanged: (bool? value) async {
                        setState(() {
                          entry.include = value ?? false;
                        });
                        await widget.profile.setEduCont(entries);
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  Tooltip(
                    message: entry.name.text.isNotEmpty ? "Start Date For ${entry.name.text}" : "Start Date For Institution ${index + 1}",
                    child: IconButton(
                      icon: Icon(Icons.date_range),
                      onPressed: () async {
                        entry.start = await SelectDate(context);
                        await widget.profile.setEduCont(entries);
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  Tooltip(
                    message: entry.name.text.isNotEmpty ? "End Date For ${entry.name.text}" : "End Date For Institution ${index + 1}",
                    child: IconButton(
                      icon: Icon(Icons.date_range),
                      onPressed: () async {
                        entry.end = await SelectDate(context);
                        await widget.profile.setEduCont(entries);
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: standardSizedBoxHeight),
              TextFormField(
                controller: entry.degree,
                keyboardType: TextInputType.multiline,
                maxLines: 1,
                decoration: InputDecoration(
                  hintText: entry.name.text.isNotEmpty ? "Enter degree(s) information for ${entry.name.text} here..." : "Enter degree(s) information here...",
                ),
                onChanged: (value) async {
                  await widget.profile.setEduCont(entries);
                },
              ),
              SizedBox(height: standardSizedBoxHeight),
              TextFormField(
                controller: entry.description,
                keyboardType: TextInputType.multiline,
                maxLines: 10,
                decoration: InputDecoration(
                  hintText: entry.name.text.isNotEmpty ? "Enter description for ${entry.name.text} here..." : "Enter description here...",
                ),
                onChanged: (value) async {
                  await widget.profile.setEduCont(entries);
                },
              ),
              SizedBox(height: standardSizedBoxHeight),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Tooltip(
                    message: entry.name.text.isNotEmpty ? "Add Entry After ${entry.name.text}" : "Add Entry After Institution ${index + 1}",
                    child: IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () async {
                        addEntry(index);
                      },
                    ),
                  ),
                  Tooltip(
                    message: entry.name.text.isNotEmpty ? "Clear Entries For ${entry.name.text}" : "Clear Entries For Institution ${index + 1}",
                    child: IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () async {
                        clearEntry(index);
                      },
                    ),
                  ),
                  if (entries.length > 1)
                    Tooltip(
                      message: entry.name.text.isNotEmpty ? "Delete Entry For ${entry.name.text}" : "Delete Entry For Institution ${index + 1}",
                      child: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () async {
                          deleteEntry(index);
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
//  Experience Profile Content
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
class ProfileExpCont {
  late TextEditingController name;
  late TextEditingController position;
  late TextEditingController description;
  DateTime? start;
  DateTime? end;
  late bool working;
  late bool include;

  ProfileExpCont() {
    name = TextEditingController();
    position = TextEditingController();
    description = TextEditingController();
    start = DateTime.now();
    end = DateTime.now();
    working = false;
    include = false;
  }

  ProfileExpCont.fromJSON(Map<String, dynamic> json) {
    name = TextEditingController(text: json['name'] ?? '');
    position = TextEditingController(text: json['position'] ?? '');
    description = TextEditingController(text: json['description'] ?? '');
    start = json['start'] != null ? DateTime.parse(json['start']) : null;
    end = json['end'] != null ? DateTime.parse(json['end']) : null;
    working = json['working'] ?? false;
    include = json['include'] ?? false;
  }

  Map<String, dynamic> toJSON() {
    return {
      'name': name.text,
      'position': position.text,
      'description': description.text,
      'start': start?.toIso8601String().split('T')[0],
      'end': end?.toIso8601String().split('T')[0],
      'working': working,
      'include': include,
    };
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
    initializeEntries();
  }

  void initializeEntries() {
    if (widget.profile.expContList.isNotEmpty) {
      entries = widget.profile.expContList;
    } else {
      entries.add(ProfileExpCont());
    }
  }

  void addEntry(int index) async {
    setState(() {
      entries.insert(index + 1, ProfileExpCont());
    });
    await widget.profile.setExpCont(entries);
  }

  void clearEntry(int index) async {
    setState(() {
      entries[index].name.text = '';
      entries[index].position.text = '';
      entries[index].description.text = '';
      entries[index].start = DateTime.now();
      entries[index].end = DateTime.now();
      entries[index].working = false;
      entries[index].include = false;
    });
    await widget.profile.setExpCont(entries);
  }

  void deleteEntry(int index) async {
    if (entries.length > 1) {
      setState(() {
        entries.removeAt(index);
      });
      await widget.profile.setExpCont(entries);
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
            entry.name.text.isNotEmpty ? entry.name.text : "Work Experience ${index + 1}",
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
                      controller: entry.name,
                      keyboardType: TextInputType.multiline,
                      maxLines: 1,
                      decoration: InputDecoration(hintText: 'Enter company name here...'),
                      onChanged: (value) async {
                        setState(() {});
                        await widget.profile.setExpCont(entries);
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  Tooltip(
                    message: entry.name.text.isNotEmpty ? "Sill Working At ${entry.name.text}?" : "Sill Working At Work Experience - ${index + 1}?",
                    child: Checkbox(
                      value: entry.working,
                      onChanged: (bool? value) async {
                        setState(() {
                          entry.working = value ?? false;
                        });
                        await widget.profile.setExpCont(entries);
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  Tooltip(
                    message: entry.name.text.isNotEmpty ? "Include ${entry.name.text} In Portfolio?" : "Include Work Experience ${index + 1} In Portfolio?",
                    child: Checkbox(
                      value: entry.include,
                      onChanged: (bool? value) async {
                        await widget.profile.setExpCont(entries);
                        setState(() {
                          entry.include = value ?? false;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  Tooltip(
                    message: entry.name.text.isNotEmpty ? "Start Date For ${entry.name.text}" : "Start Date For Work Experience ${index + 1}",
                    child: IconButton(
                      icon: Icon(Icons.date_range),
                      onPressed: () async {
                        entry.start = await SelectDate(context);
                        await widget.profile.setExpCont(entries);
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  Tooltip(
                    message: entry.name.text.isNotEmpty ? "End Date For ${entry.name.text}" : "End Date For Work Experience ${index + 1}",
                    child: IconButton(
                      icon: Icon(Icons.date_range),
                      onPressed: () async {
                        entry.end = await SelectDate(context);
                        await widget.profile.setExpCont(entries);
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: standardSizedBoxHeight),
              TextFormField(
                controller: entry.position,
                keyboardType: TextInputType.multiline,
                maxLines: 1,
                decoration: InputDecoration(
                  hintText: entry.name.text.isNotEmpty ? "Enter position info for ${entry.name.text} here..." : "Enter position info here...",
                ),
                onChanged: (value) async {
                  await widget.profile.setExpCont(entries);
                },
              ),
              SizedBox(height: standardSizedBoxHeight),
              TextFormField(
                controller: entry.description,
                keyboardType: TextInputType.multiline,
                maxLines: 10,
                decoration: InputDecoration(
                  hintText: entry.name.text.isNotEmpty ? "Enter description for ${entry.name.text} here..." : "Enter description here...",
                ),
                onChanged: (value) async {
                  await widget.profile.setExpCont(entries);
                },
              ),
              SizedBox(height: standardSizedBoxHeight),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Tooltip(
                    message: entry.name.text.isNotEmpty ? "Add Entry After ${entry.name.text}" : "Add Entry After Work Experience ${index + 1}",
                    child: IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () async {
                        addEntry(index);
                      },
                    ),
                  ),
                  Tooltip(
                    message: entry.name.text.isNotEmpty ? "Clear Entries For ${entry.name.text}" : "Clear Entries For Work Experience ${index + 1}",
                    child: IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () async {
                        clearEntry(index);
                      },
                    ),
                  ),
                  if (entries.length > 1)
                    Tooltip(
                      message: entry.name.text.isNotEmpty ? "Delete Entry For ${entry.name.text}" : "Delete Entry For Work Experience ${index + 1}",
                      child: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () async {
                          deleteEntry(index);
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
//  Projects Profile Content
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
class ProfileProjCont {
  late TextEditingController projName;
  late TextEditingController roleName;
  late TextEditingController description;
  DateTime? date;
  late bool completed;

  ProfileProjCont() {
    projName = TextEditingController();
    roleName = TextEditingController();
    description = TextEditingController();
    date = DateTime.now();
    completed = false;
  }

  ProfileProjCont.fromJSON(Map<String, dynamic> json) {
    projName = TextEditingController(text: json['projName'] ?? '');
    roleName = TextEditingController(text: json['roleName'] ?? '');
    description = TextEditingController(text: json['description'] ?? '');
    date = json['date'] != null ? DateTime.parse(json['date']) : null;
    completed = json['completed'] ?? false;
  }

  Map<String, dynamic> toJSON() {
    return {
      'projName': projName.text,
      'roleName': roleName.text,
      'description': description.text,
      'date': date?.toIso8601String().split('T')[0],
      'completed': completed,
    };
  }
}

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Project Profile Entry
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
class ProjectProfileEntry extends StatefulWidget {
  final Profile profile;

  const ProjectProfileEntry({
    super.key,
    required this.profile,
  });

  @override
  ProjectProfileEntryState createState() => ProjectProfileEntryState();
}

class ProjectProfileEntryState extends State<ProjectProfileEntry> {
  List<ProfileProjCont> entries = [];

  @override
  void initState() {
    super.initState();
    initializeEntries();
  }

  void initializeEntries() {
    if (widget.profile.projContList.isNotEmpty) {
      entries = widget.profile.projContList;
    } else {
      entries.add(ProfileProjCont());
    }
  }

  void addEntry(int index) async {
    setState(() {
      entries.insert(index + 1, ProfileProjCont());
    });
    await widget.profile.setProjCont(entries);
  }

  void clearEntry(int index) async {
    setState(() {
      entries[index].projName.text = '';
      entries[index].roleName.text = '';
      entries[index].description.text = '';
      entries[index].date = DateTime.now();
      entries[index].completed = false;
    });
    await widget.profile.setProjCont(entries);
  }

  void deleteEntry(int index) async {
    if (entries.length > 1) {
      setState(() {
        entries.removeAt(index);
      });
      await widget.profile.setProjCont(entries);
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
              ProfileProjCont entryData = entry.value;
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
    ProfileProjCont entry,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: standardSizedBoxHeight),
        Center(
          child: Text(
            'Project - ${index + 1}',
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
                      controller: entry.projName,
                      keyboardType: TextInputType.multiline,
                      maxLines: 1,
                      decoration: InputDecoration(hintText: 'Enter project name here...'),
                      onChanged: (value) async {
                        await widget.profile.setProjCont(entries);
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  Tooltip(
                    message: 'Completed project ${index + 1}?',
                    child: Checkbox(
                      value: entry.completed,
                      onChanged: (bool? value) async {
                        await widget.profile.setProjCont(entries);
                        setState(() {
                          entry.completed = value ?? false;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  Tooltip(
                    message: 'Select Date For Project ${index + 1}',
                    child: IconButton(
                      icon: Icon(Icons.date_range),
                      onPressed: () async {
                        entry.date = await SelectDate(context);
                        await widget.profile.setProjCont(entries);
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: standardSizedBoxHeight),
              TextFormField(
                controller: entry.roleName,
                keyboardType: TextInputType.multiline,
                maxLines: 1,
                decoration: InputDecoration(hintText: 'Enter role info here...'),
                onChanged: (value) async {
                  await widget.profile.setProjCont(entries);
                },
              ),
              SizedBox(height: standardSizedBoxHeight),
              TextFormField(
                controller: entry.description,
                keyboardType: TextInputType.multiline,
                maxLines: 10,
                decoration: InputDecoration(hintText: 'Enter description here...'),
                onChanged: (value) async {
                  await widget.profile.setProjCont(entries);
                },
              ),
              SizedBox(height: standardSizedBoxHeight),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Tooltip(
                    message: 'Add Entry After Project ${index + 1}',
                    child: IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () async {
                        addEntry(index);
                      },
                    ),
                  ),
                  Tooltip(
                    message: 'Clear Entries For Project ${index + 1}',
                    child: IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () async {
                        clearEntry(index);
                      },
                    ),
                  ),
                  Tooltip(
                    message: 'Delete Entry For Project ${index + 1}',
                    child: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () async {
                        deleteEntry(index);
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
//  Skills Profile Content
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
class ProfileSkillsCont {
  late TextEditingController skillCategory;
  late TextEditingController description;

  ProfileSkillsCont() {
    skillCategory = TextEditingController();
    description = TextEditingController();
  }

  ProfileSkillsCont.fromJSON(Map<String, dynamic> json) {
    skillCategory = TextEditingController(text: json['skillCategory'] ?? '');
    description = TextEditingController(text: json['description'] ?? '');
  }

  Map<String, dynamic> toJSON() {
    return {
      'skillCategory': skillCategory.text,
      'description': description.text,
    };
  }
}

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Skills Profile Entry
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
class SkillsProjectEntry extends StatefulWidget {
  final Profile profile;

  const SkillsProjectEntry({
    super.key,
    required this.profile,
  });

  @override
  SkillsProjectEntryState createState() => SkillsProjectEntryState();
}

class SkillsProjectEntryState extends State<SkillsProjectEntry> {
  List<ProfileSkillsCont> entries = [];

  @override
  void initState() {
    super.initState();
    initializeEntries();
  }

  void initializeEntries() {
    if (widget.profile.skillsContList.isNotEmpty) {
      entries = widget.profile.skillsContList;
    } else {
      entries.add(ProfileSkillsCont());
    }
  }

  void addEntry(int index) async {
    setState(() {
      entries.insert(index + 1, ProfileSkillsCont());
    });
    await widget.profile.setSkillsCont(entries);
  }

  void clearEntry(int index) async {
    setState(() {
      entries[index].skillCategory.text = '';
      entries[index].description.text = '';
    });
    await widget.profile.setSkillsCont(entries);
  }

  void deleteEntry(int index) async {
    if (entries.length > 1) {
      setState(() {
        entries.removeAt(index);
      });
      await widget.profile.setSkillsCont(entries);
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
              ProfileSkillsCont entryData = entry.value;
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
    ProfileSkillsCont entry,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: standardSizedBoxHeight),
        Center(
          child: Text(
            'Skill Category - ${index + 1}',
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
                      controller: entry.skillCategory,
                      keyboardType: TextInputType.multiline,
                      maxLines: 1,
                      decoration: InputDecoration(hintText: 'Enter skill category here...'),
                      onChanged: (value) async {
                        await widget.profile.setSkillsCont(entries);
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: standardSizedBoxHeight),
              TextFormField(
                controller: entry.description,
                keyboardType: TextInputType.multiline,
                maxLines: 10,
                decoration: InputDecoration(hintText: 'Enter skills here...'),
                onChanged: (value) async {
                  await widget.profile.setSkillsCont(entries);
                },
              ),
              SizedBox(height: standardSizedBoxHeight),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Tooltip(
                    message: 'Add Entry Skill Category ${index + 1}',
                    child: IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        addEntry(index);
                      },
                    ),
                  ),
                  Tooltip(
                    message: 'Clear Entries For Skill Category ${index + 1}',
                    child: IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        clearEntry(index);
                      },
                    ),
                  ),
                  Tooltip(
                    message: 'Delete Entry Skill Category ${index + 1}',
                    child: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        deleteEntry(index);
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
