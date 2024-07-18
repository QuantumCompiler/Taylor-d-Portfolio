// ignore_for_file: unused_local_variable
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
  late File proFile;

  // Strings
  late String name;

  // Lists Of Types
  List<ProfileCLCont> coverLetterContList = [];
  List<ProfileEduCont> eduContList = [];
  List<ProfileExpCont> expContList = [];
  List<ProfileProjCont> projContList = [];
  List<ProfileSkillsCont> skillsContList = [];

  // Text Editing Controller
  TextEditingController nameController = TextEditingController();

  Profile._({
    required this.newProfile,
    required this.name,
    required this.coverLetterContList,
    required this.eduContList,
    required this.expContList,
    required this.projContList,
    required this.skillsContList,
    required this.nameController,
  });

  static Future<Profile> Init({String name = '', required bool? newProfile}) async {
    List<ProfileCLCont> coverLetterContList = [];
    List<ProfileEduCont> eduContList = [];
    List<ProfileExpCont> expContList = [];
    List<ProfileProjCont> projContList = [];
    List<ProfileSkillsCont> skillsContList = [];

    if (newProfile == true) {
      coverLetterContList = await LoadCLCont('Temp/');
      eduContList = await LoadEduCont('Temp/');
      expContList = await LoadExpCont('Temp/');
      projContList = await LoadProjectsCont('Temp/');
      skillsContList = await LoadSkillsCont('Temp/');
    } else if (newProfile == false) {
      coverLetterContList = await LoadCLCont('Profiles/$name/');
      eduContList = await LoadEduCont('Profiles/$name/');
      expContList = await LoadExpCont('Profiles/$name/');
      projContList = await LoadProjectsCont('Profiles/$name/');
      skillsContList = await LoadSkillsCont('Profiles/$name/');
    }

    return Profile._(
      newProfile: newProfile,
      name: name,
      coverLetterContList: coverLetterContList,
      eduContList: eduContList,
      expContList: expContList,
      projContList: projContList,
      skillsContList: skillsContList,
      nameController: TextEditingController(text: name),
    );
  }

  // Create Profile
  Future<void> CreateProfile(String profName) async {
    if (newProfile == true) {
      await setProfName(profName);
      await setProfDir();
      await WriteProfile("Profiles/$name", "Profiles/$name");
      if (kDebugMode) {
        print('Profile $name created successfully');
      }
      try {
        final masterDir = await getApplicationDocumentsDirectory();
        final tempDir = Directory('${masterDir.path}/Temp');
        if (await tempDir.exists()) {
          try {
            final tempDirContents = tempDir.listSync();
            for (var file in tempDirContents) {
              if (file is File) {
                await file.delete();
              } else if (file is Directory) {
                await file.delete(recursive: true);
              }
            }
            if (kDebugMode) {
              print('$tempDir contents cleaned successfully');
            }
          } catch (e) {
            throw ('Error occurred in cleaning $tempDir contents: $e');
          }
        }
      } catch (e) {
        throw ('Error occurred in creating $name profile: $e');
      }
    }
    if (newProfile == false) {
      final newName = nameController.text;
      final masterDir = await getApplicationDocumentsDirectory();
      final oldDir = Directory('${masterDir.path}/Profiles/$name');
      final existing = Directory('${masterDir.path}/Profiles/$newName');
      Directory newDir;
      if (oldDir.existsSync() && !existing.existsSync()) {
        newDir = await oldDir.rename('${masterDir.path}/Profiles/$newName');
        name = newName;
      }
      newDir = oldDir;
      try {
        await WriteProfile("Profiles/$name", "Profiles/$name");
      } catch (e) {
        throw ('Error occurred in overwriting $name: $e');
      }
    }
  }

  // Load Cover Letter Contents
  static Future<List<ProfileCLCont>> LoadCLCont(String subDir) async {
    try {
      final masterDir = await getApplicationDocumentsDirectory();
      final jsonFile = File('${masterDir.path}/$subDir/$coverLetterJSONFile');
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
      final jsonFile = File('${masterDir.path}/$subDir/$educationJSONFile');
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
      final jsonFile = File('${masterDir.path}/$subDir/$experienceJSONFile');
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
      final jsonFile = File('${masterDir.path}/$subDir/$projectsJSONFile');
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
      final jsonFile = File('${masterDir.path}/$subDir/$skillsJSONFile');
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

  Future<String> StringifyCLCont(String subDir) async {
    String ret = '';
    final masterDir = await getApplicationDocumentsDirectory();
    final File jsonFile = File('${masterDir.path}/$subDir/$coverLetterJSONFile');
    if (!jsonFile.existsSync()) {
      if (kDebugMode) {
        print('$jsonFile does not exist.');
      }
    } else {
      try {
        String jsonString = jsonFile.readAsStringSync();
        List<dynamic> jsonData = jsonDecode(jsonString);
        for (int i = 0; i < jsonData.length; i++) {
          ret += "About Applicant:\n\n${jsonData[i]['about']}\n";
        }
      } catch (e) {
        throw ('Error occurred $e');
      }
    }
    return ret;
  }

  Future<String> StringifyEduCont(String subDir) async {
    String ret = '';
    final masterDir = await getApplicationDocumentsDirectory();
    final File jsonFile = File('${masterDir.path}/$subDir/$educationJSONFile');
    if (!jsonFile.existsSync()) {
      if (kDebugMode) {
        print('$jsonFile does not exist');
      }
    } else {
      try {
        String jsonString = jsonFile.readAsStringSync();
        List<dynamic> jsonData = jsonDecode(jsonString);
        for (int i = 0; i < jsonData.length; i++) {
          if (i == 0) {
            ret += "\nEducation Information:\n";
          }
          ret += "\nEducation Institution ${i + 1}:\n\nSchool Name: ${jsonData[i]['name']}\n\nDegree(s): ${jsonData[i]['degree']}\n\nDescription: ${jsonData[i]['description']}\n";
        }
      } catch (e) {
        throw ("Error occurred $e");
      }
    }
    return ret;
  }

  Future<String> StringifyExpCont(String subDir) async {
    String ret = '';
    final masterDir = await getApplicationDocumentsDirectory();
    final File jsonFile = File('${masterDir.path}/$subDir/$experienceJSONFile');
    if (!jsonFile.existsSync()) {
      if (kDebugMode) {
        print('$jsonFile does not exist');
      }
    } else {
      try {
        String jsonString = jsonFile.readAsStringSync();
        List<dynamic> jsonData = jsonDecode(jsonString);
        for (int i = 0; i < jsonData.length; i++) {
          if (i == 0) {
            ret += "\nExperience Information:\n";
          }
          ret += "\nExperience Institution ${i + 1}:\n\nCompany Name: ${jsonData[i]['name']}\n\nPosition(s): ${jsonData[i]['position']}\n\nDescription: ${jsonData[i]['description']}\n";
        }
      } catch (e) {
        throw ("Error occurred $e");
      }
    }
    return ret;
  }

  Future<String> StringifyProjCont(String subDir) async {
    String ret = '';
    final masterDir = await getApplicationDocumentsDirectory();
    final File jsonFile = File('${masterDir.path}/$subDir/$projectsJSONFile');
    if (!jsonFile.existsSync()) {
      if (kDebugMode) {
        print('$jsonFile does not exist.');
      }
    } else {
      try {
        String jsonString = jsonFile.readAsStringSync();
        List<dynamic> jsonData = jsonDecode(jsonString);
        for (int i = 0; i < jsonData.length; i++) {
          if (i == 0) {
            ret += "\nProject Information:\n";
          }
          ret += "\nProject ${i + 1}:\n\nProject Name: ${jsonData[i]['name']}\n\nRole(s): ${jsonData[i]['role']}\n\nDescription: ${jsonData[i]['description']}\n";
        }
      } catch (e) {
        throw ("Error occurred $e");
      }
    }
    return ret;
  }

  Future<String> StringifySkillsCont(String subDir) async {
    String ret = '';
    final masterDir = await getApplicationDocumentsDirectory();
    final File jsonFile = File('${masterDir.path}/$subDir/$skillsJSONFile');
    if (!jsonFile.existsSync()) {
      if (kDebugMode) {
        print('$jsonFile does not exist');
      }
    } else {
      try {
        String jsonString = jsonFile.readAsStringSync();
        List<dynamic> jsonData = jsonDecode(jsonString);
        for (int i = 0; i < jsonData.length; i++) {
          if (i == 0) {
            ret += "\nSkills Information:\n";
          }
          ret += "\nSkill Category ${i + 1}:\n\nSkill Name: ${jsonData[0]['name']}\n\nDescription: ${jsonData[i]['description']}\n";
        }
      } catch (e) {
        throw ("Error occurred $e");
      }
    }
    return ret;
  }

  // Write Profile
  Future<void> WriteProfile(String jsonDir, String destDir) async {
    final masterDir = await getApplicationDocumentsDirectory();
    await WriteContentToJSON(jsonDir, coverLetterJSONFile, coverLetterContList);
    await WriteContentToJSON(jsonDir, educationJSONFile, eduContList);
    await WriteContentToJSON(jsonDir, experienceJSONFile, expContList);
    await WriteContentToJSON(jsonDir, projectsJSONFile, projContList);
    await WriteContentToJSON(jsonDir, skillsJSONFile, skillsContList);
    final File covFile = File('${masterDir.path}/$jsonDir/$coverLetterJSONFile');
    final File eduFile = File('${masterDir.path}/$jsonDir/$educationJSONFile');
    final File expFile = File('${masterDir.path}/$jsonDir/$experienceJSONFile');
    final File proFile = File('${masterDir.path}/$jsonDir/$projectsJSONFile');
    final File skiFile = File('${masterDir.path}/$jsonDir/$skillsJSONFile');
    if (covFile.existsSync() && eduFile.existsSync() && expFile.existsSync() && proFile.existsSync() && skiFile.existsSync()) {
      final File profileFile = File('${masterDir.path}/$destDir/$finalProfileJSONFile');
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
        await profileFile.writeAsString(jsonString);
        String clCont = await StringifyCLCont(jsonDir);
        String eduCont = await StringifyEduCont(jsonDir);
        String expCont = await StringifyExpCont(jsonDir);
        String proCont = await StringifyProjCont(jsonDir);
        String skillsCont = await StringifySkillsCont(jsonDir);
        String finalRet = clCont + eduCont + expCont + proCont + skillsCont;
        try {
          Directory finalDir = Directory('${masterDir.path}/$destDir');
          final proFile = File('${finalDir.path}/$finalProfileTextFile');
          await WriteFile(finalDir, proFile, finalRet);
        } catch (e) {
          throw ('Error occurred in creating string for final profile: $e');
        }
      } catch (e) {
        throw ('Error ocurred in writing profile file: $e');
      }
    } else {
      if (kDebugMode) {
        print('Necessary files do not exist to write profile file.');
      }
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
                  hintText: entry.name.text.isNotEmpty ? "Enter degree(s) information for ${entry.name.text} here..." : "Enter degree(s) information for Institution ${index + 1} here...",
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
                  hintText: entry.name.text.isNotEmpty ? "Enter description for ${entry.name.text} here..." : "Enter description for Institution ${index + 1} here...",
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
                  hintText: entry.name.text.isNotEmpty ? "Enter position info for ${entry.name.text} here..." : "Enter position info for Work Experience ${index + 1} here...",
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
                  hintText: entry.name.text.isNotEmpty ? "Enter description for ${entry.name.text} here..." : "Enter description for Work Experience ${index + 1} here...",
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
  late TextEditingController name;
  late TextEditingController role;
  late TextEditingController description;
  DateTime? start;
  DateTime? end;
  late bool completed;
  late bool include;

  ProfileProjCont() {
    name = TextEditingController();
    role = TextEditingController();
    description = TextEditingController();
    start = DateTime.now();
    end = DateTime.now();
    completed = false;
    include = false;
  }

  ProfileProjCont.fromJSON(Map<String, dynamic> json) {
    name = TextEditingController(text: json['name'] ?? '');
    role = TextEditingController(text: json['role'] ?? '');
    description = TextEditingController(text: json['description'] ?? '');
    start = json['start'] != null ? DateTime.parse(json['start']) : null;
    start = json['end'] != null ? DateTime.parse(json['end']) : null;
    completed = json['completed'] ?? false;
    include = json['include'] ?? false;
  }

  Map<String, dynamic> toJSON() {
    return {
      'name': name.text,
      'role': role.text,
      'description': description.text,
      'start': start?.toIso8601String().split('T')[0],
      'end': end?.toIso8601String().split('T')[0],
      'completed': completed,
      'include': include,
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
      entries[index].name.text = '';
      entries[index].role.text = '';
      entries[index].description.text = '';
      entries[index].start = DateTime.now();
      entries[index].end = DateTime.now();
      entries[index].completed = false;
      entries[index].include = false;
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
            entry.name.text.isNotEmpty ? entry.name.text : "Project ${index + 1}",
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
                      decoration: InputDecoration(hintText: 'Enter project name here...'),
                      onChanged: (value) async {
                        setState(() {});
                        await widget.profile.setProjCont(entries);
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  Tooltip(
                    message: entry.name.text.isNotEmpty ? "Completed ${entry.name.text}?" : "Completed Project ${index + 1}?",
                    child: Checkbox(
                      value: entry.completed,
                      onChanged: (bool? value) async {
                        setState(() {
                          entry.completed = value ?? false;
                        });
                        await widget.profile.setProjCont(entries);
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  Tooltip(
                    message: entry.name.text.isNotEmpty ? "Include ${entry.name.text} In Portfolio?" : "Include Project ${index + 1} In Portfolio?",
                    child: Checkbox(
                      value: entry.include,
                      onChanged: (bool? value) async {
                        setState(() {
                          entry.include = value ?? false;
                        });
                        await widget.profile.setProjCont(entries);
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  Tooltip(
                    message: entry.name.text.isNotEmpty ? "Start Date For ${entry.name.text}" : "Start Date For Project ${index + 1}",
                    child: IconButton(
                      icon: Icon(Icons.date_range),
                      onPressed: () async {
                        entry.start = await SelectDate(context);
                        await widget.profile.setProjCont(entries);
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  Tooltip(
                    message: entry.name.text.isNotEmpty ? "End Date For ${entry.name.text}" : "End Date For Project ${index + 1}",
                    child: IconButton(
                      icon: Icon(Icons.date_range),
                      onPressed: () async {
                        entry.end = await SelectDate(context);
                        await widget.profile.setProjCont(entries);
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: standardSizedBoxHeight),
              TextFormField(
                controller: entry.role,
                keyboardType: TextInputType.multiline,
                maxLines: 1,
                decoration: InputDecoration(
                  hintText: entry.name.text.isNotEmpty ? "Enter role info for ${entry.name.text} here..." : "Enter role info for Project ${index + 1} here...",
                ),
                onChanged: (value) async {
                  await widget.profile.setProjCont(entries);
                },
              ),
              SizedBox(height: standardSizedBoxHeight),
              TextFormField(
                controller: entry.description,
                keyboardType: TextInputType.multiline,
                maxLines: 10,
                decoration: InputDecoration(
                  hintText: entry.name.text.isNotEmpty ? "Enter description for ${entry.name.text} here..." : "Enter description for Project ${index + 1} here...",
                ),
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
                    message: entry.name.text.isNotEmpty ? "Add Entry After ${entry.name.text}" : "Add Entry After Project ${index + 1}",
                    child: IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () async {
                        addEntry(index);
                      },
                    ),
                  ),
                  Tooltip(
                    message: entry.name.text.isNotEmpty ? "Clear Entries For ${entry.name.text}" : "Clear Entries For Project ${index + 1}",
                    child: IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () async {
                        clearEntry(index);
                      },
                    ),
                  ),
                  if (entries.length > 1)
                    Tooltip(
                      message: entry.name.text.isNotEmpty ? "Delete Entry For ${entry.name.text}" : "Delete Entry For Project ${index + 1}",
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
  late TextEditingController name;
  late TextEditingController description;
  late bool include;

  ProfileSkillsCont() {
    name = TextEditingController();
    description = TextEditingController();
    include = false;
  }

  ProfileSkillsCont.fromJSON(Map<String, dynamic> json) {
    name = TextEditingController(text: json['name'] ?? '');
    description = TextEditingController(text: json['description'] ?? '');
    include = json['include'] ?? false;
  }

  Map<String, dynamic> toJSON() {
    return {
      'name': name.text,
      'description': description.text,
      'include': include,
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
      entries[index].name.text = '';
      entries[index].description.text = '';
      entries[index].include = false;
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
            entry.name.text.isNotEmpty ? entry.name.text : "Skill Category ${index + 1}",
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
                      decoration: InputDecoration(hintText: 'Enter skill name here...'),
                      onChanged: (value) async {
                        setState(() {});
                        await widget.profile.setSkillsCont(entries);
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  Tooltip(
                    message: entry.name.text.isNotEmpty ? "Include ${entry.name.text} In Portfolio?" : "Include Skill Category ${index + 1}",
                    child: Checkbox(
                      value: entry.include,
                      onChanged: (bool? value) async {
                        setState(() {
                          entry.include = value ?? false;
                        });
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
                decoration: InputDecoration(
                  hintText: entry.name.text.isNotEmpty ? "Enter skills info for ${entry.name.text} here..." : "Enter skills info for Skill Category ${index + 1} here...",
                ),
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
                    message: entry.name.text.isNotEmpty ? "Add Entry After ${entry.name.text}" : "Add Entry After Skill Category ${index + 1}",
                    child: IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        addEntry(index);
                      },
                    ),
                  ),
                  Tooltip(
                    message: entry.name.text.isNotEmpty ? "Clear Entries For ${entry.name.text}" : "Clear Entries For Skill Category ${index + 1}",
                    child: IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        clearEntry(index);
                      },
                    ),
                  ),
                  if (entries.length > 1)
                    Tooltip(
                      message: entry.name.text.isNotEmpty ? "Delete Entry For ${entry.name.text}" : "Delete Entry For Skill Category ${index + 1}",
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
