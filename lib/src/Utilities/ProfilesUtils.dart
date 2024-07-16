import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../Context/Globals/GlobalContext.dart';
import '../Globals/ProfilesGlobals.dart';
import '../Globals/Globals.dart';
import '../Utilities/GlobalUtils.dart';

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Cover Letter Pitch Profile Content
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
class ProfileCLCont {
  late TextEditingController pitch;
  ProfileCLCont() {
    pitch = TextEditingController();
  }
  ProfileCLCont.fromJSON(Map<String, dynamic> json) {
    pitch = TextEditingController(text: json['pitch'] ?? '');
  }
  Map<String, dynamic> toJSON() {
    return {
      'pitch': pitch.text,
    };
  }
}

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Education Profile Content
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
class ProfileEduCont {
  late TextEditingController desInfo;
  late TextEditingController degInfo;
  late TextEditingController schoolInfo;
  DateTime? startDate;
  DateTime? endDate;
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
    desInfo = TextEditingController(text: json['desInfo'] ?? '');
    degInfo = TextEditingController(text: json['degInfo'] ?? '');
    schoolInfo = TextEditingController(text: json['schoolInfo'] ?? '');
    startDate = json['startDate'] != null ? DateTime.parse(json['startDate']) : null;
    endDate = json['endDate'] != null ? DateTime.parse(json['endDate']) : null;
    graduated = json['graduated'] ?? false;
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
  DateTime? startDate;
  DateTime? endDate;
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
    companyName = TextEditingController(text: json['companyName'] ?? '');
    positionName = TextEditingController(text: json['positionName'] ?? '');
    desInfo = TextEditingController(text: json['desInfo'] ?? '');
    startDate = json['startDate'] != null ? DateTime.parse(json['startDate']) : null;
    endDate = json['endDate'] != null ? DateTime.parse(json['endDate']) : null;
    stillWorking = json['stillWorking'] ?? false;
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
//  Projects Profile Content
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
class ProfileProjCont {
  late TextEditingController projName;
  late TextEditingController roleName;
  late TextEditingController desInfo;
  DateTime? date;
  late bool completed;

  ProfileProjCont() {
    projName = TextEditingController();
    roleName = TextEditingController();
    desInfo = TextEditingController();
    date = DateTime.now();
    completed = false;
  }

  ProfileProjCont.fromJSON(Map<String, dynamic> json) {
    projName = TextEditingController(text: json['projName'] ?? '');
    roleName = TextEditingController(text: json['roleName'] ?? '');
    desInfo = TextEditingController(text: json['desInfo'] ?? '');
    date = json['date'] != null ? DateTime.parse(json['date']) : null;
    completed = json['completed'] ?? false;
  }

  Map<String, dynamic> toJSON() {
    return {
      'projName': projName.text,
      'roleName': roleName.text,
      'desInfo': desInfo.text,
      'date': date?.toIso8601String().split('T')[0],
      'completed': completed,
    };
  }
}

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Skills Profile Content
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
class ProfileSkillsCont {
  late TextEditingController skillCategory;
  late TextEditingController desInfo;

  ProfileSkillsCont() {
    skillCategory = TextEditingController();
    desInfo = TextEditingController();
  }

  ProfileSkillsCont.fromJSON(Map<String, dynamic> json) {
    skillCategory = TextEditingController(text: json['skillCategory'] ?? '');
    desInfo = TextEditingController(text: json['desInfo'] ?? '');
  }

  Map<String, dynamic> toJSON() {
    return {
      'skillCategory': skillCategory.text,
      'desInfo': desInfo.text,
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
  List<ProfileCLCont> coverLetterContList = [];
  List<ProfileEduCont> eduContList = [];
  List<ProfileExpCont> expContList = [];
  List<ProfileProjCont> projContList = [];
  List<ProfileSkillsCont> skillsContList = [];

  // Constructor
  Profile({this.name = ''}) {
    eduTitle = educationTitle;
    expTitle = experienceTitle;
    projTitle = projectsTitle;
    skiTitle = skillsTitle;
    coverLetterContList = coverLetterContList;
    eduContList = eduContList;
    expContList = expContList;
    projContList = projContList;
    skillsContList = skillsContList;
    setTempDir();
  }

  Future<void> CreateCLContJSON() async {
    await WriteContentToJSON('Temp/', 'CLCont.json', coverLetterContList);
    await ReadCLContentFromJSON('Temp/');
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
  Future<void> LoadCLCont() async {
    try {
      final appsDir = await getApplicationDocumentsDirectory();
      final jsonFile = File('${appsDir.path}/Profiles/Temp/CLCont.json');
      final fileExists = await jsonFile.exists();
      if (fileExists) {
        final jsonString = await jsonFile.readAsString();
        final List<dynamic> jsonData = jsonDecode(jsonString);
        final List<ProfileCLCont> entries = jsonData.map((entry) => ProfileCLCont.fromJSON(entry)).toList();
        coverLetterContList = entries;
      }
    } catch (e) {
      throw ('An error occurred while loading cover letter contents: $e');
    }
  }

  // Load Education Contents
  Future<void> LoadEduCont() async {
    try {
      final appsDir = await getApplicationDocumentsDirectory();
      final jsonFile = File('${appsDir.path}/Profiles/Temp/CLCont.json');
      final fileExists = await jsonFile.exists();
      if (fileExists) {
        final jsonString = await jsonFile.readAsString();
        final List<dynamic> jsonData = jsonDecode(jsonString);
        final List<ProfileEduCont> entries = jsonData.map((entry) => ProfileEduCont.fromJSON(entry)).toList();
        eduContList = entries;
      }
    } catch (e) {
      throw ('An error occurred while loading education contents: $e');
    }
  }

  // Load Experience Contents
  Future<void> LoadExpCont() async {
    try {
      final appsDir = await getApplicationDocumentsDirectory();
      final jsonFile = File('${appsDir.path}/Profiles/Temp/ExpCont.json');
      final fileExists = await jsonFile.exists();
      if (fileExists) {
        final jsonString = await jsonFile.readAsString();
        final List<dynamic> jsonData = jsonDecode(jsonString);
        final List<ProfileExpCont> entries = jsonData.map((entry) => ProfileExpCont.fromJSON(entry)).toList();
        expContList = entries;
      }
    } catch (e) {
      throw ('An error occurred while loading experience contents: $e');
    }
  }

  // Load Projects Contents
  Future<void> LoadProjectsCont() async {
    try {
      final appsDir = await getApplicationDocumentsDirectory();
      final jsonFile = File('${appsDir.path}/Profiles/Temp/ProjCont.json');
      final fileExists = await jsonFile.exists();
      if (fileExists) {
        final jsonString = await jsonFile.readAsString();
        final List<dynamic> jsonData = jsonDecode(jsonString);
        final List<ProfileProjCont> entries = jsonData.map((entry) => ProfileProjCont.fromJSON(entry)).toList();
        projContList = entries;
      }
    } catch (e) {
      throw ('An error occurred while loading projects contents: $e');
    }
  }

  // Load Skills Contents
  Future<void> LoadSkillsCont() async {
    try {
      final appsDir = await getApplicationDocumentsDirectory();
      final jsonFile = File('${appsDir.path}/Profiles/Temp/SkillsCont.json');
      final fileExists = await jsonFile.exists();
      if (fileExists) {
        final jsonString = await jsonFile.readAsString();
        final List<dynamic> jsonData = jsonDecode(jsonString);
        final List<ProfileSkillsCont> entries = jsonData.map((entry) => ProfileSkillsCont.fromJSON(entry)).toList();
        skillsContList = entries;
      }
    } catch (e) {
      throw ('An error occurred while loading skills contents: $e');
    }
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

  // Read Cover Letter Pitch Content From JSON
  Future<void> ReadCLContentFromJSON(String subDir) async {
    final profs = await profsDir;
    final file = File('${profs.path}/$subDir/CLCont.json');
    if (!file.existsSync()) {
      print('Cover letter content json file does not exist.');
      return;
    }
    String jsonString = file.readAsStringSync();
    List<dynamic> jsonData = jsonDecode(jsonString);
    for (int i = 0; i < jsonData.length; i++) {
      print(jsonData[i]['pitch']);
    }
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

  // Read Experience Content From JSON
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

  // Read Projects Content From JSON
  Future<void> ReadProjContentFromJSON(String subDir) async {
    final profs = await profsDir;
    final file = File('${profs.path}/$subDir/ProjCont.json');
    if (!file.existsSync()) {
      print('Projects content json file does not exist.');
      return;
    }
    String jsonString = file.readAsStringSync();
    List<dynamic> jsonData = jsonDecode(jsonString);
    for (int i = 0; i < jsonData.length; i++) {
      print(jsonData[i]['projName']);
      print(jsonData[i]['roleName']);
      print(jsonData[i]['desInfo']);
      print(jsonData[i]['completed']);
      print(jsonData[i]['date']);
    }
  }

  // Read Projects Content From JSON
  Future<void> ReadSkillsContentFromJSON(String subDir) async {
    final profs = await profsDir;
    final file = File('${profs.path}/$subDir/SkillsCont.json');
    if (!file.existsSync()) {
      print('Skills content json file does not exist.');
      return;
    }
    String jsonString = file.readAsStringSync();
    List<dynamic> jsonData = jsonDecode(jsonString);
    for (int i = 0; i < jsonData.length; i++) {
      print(jsonData[i]['skillCategory']);
      print(jsonData[i]['desInfo']);
    }
  }

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
      } else if (cont is ProfileProjCont) {
        return (cont as ProfileProjCont).toJSON();
      } else if (cont is ProfileSkillsCont) {
        return (cont as ProfileSkillsCont).toJSON();
      } else if (cont is ProfileCLCont) {
        return (cont as ProfileCLCont).toJSON();
      } else {
        throw Exception("Type T does not have a toJSON method");
      }
    }).toList();
    String jsonString = jsonEncode(contJSON);
    await file.writeAsString(jsonString);
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

  void clearEntry(int index) {
    setState(() {
      entries[index].pitch.text = '';
    });
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
            'Pitch',
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
                controller: entry.pitch,
                keyboardType: TextInputType.multiline,
                maxLines: 15,
                decoration: InputDecoration(hintText: 'Enter pitch here...'),
                onChanged: (value) {
                  setState(() {
                    widget.profile.setCLCont(entries);
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
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

  void initializeEntries() {
    if (widget.profile.eduContList.isNotEmpty) {
      entries = widget.profile.eduContList;
    } else {
      entries.add(ProfileEduCont());
    }
  }

  void addEntry(int index) {
    setState(() {
      entries.insert(index + 1, ProfileEduCont());
      widget.profile.setEduCont(entries);
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
      widget.profile.setEduCont(entries);
    });
  }

  void deleteEntry(int index) {
    if (entries.length > 1) {
      setState(() {
        entries.removeAt(index);
        widget.profile.setEduCont(entries);
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
    initializeEntries();
  }

  void initializeEntries() {
    if (widget.profile.expContList.isNotEmpty) {
      entries = widget.profile.expContList;
    } else {
      entries.add(ProfileExpCont());
    }
  }

  void addEntry(int index) {
    setState(() {
      entries.insert(index + 1, ProfileExpCont());
      widget.profile.setExpCont(entries);
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
      widget.profile.setExpCont(entries);
    });
  }

  void deleteEntry(int index) {
    if (entries.length > 1) {
      setState(() {
        entries.removeAt(index);
        widget.profile.setExpCont(entries);
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

  void addEntry(int index) {
    setState(() {
      entries.insert(index + 1, ProfileProjCont());
      widget.profile.setProjCont(entries);
    });
  }

  void clearEntry(int index) {
    setState(() {
      entries[index].projName.text = '';
      entries[index].roleName.text = '';
      entries[index].desInfo.text = '';
      entries[index].date = DateTime.now();
      entries[index].completed = false;
      widget.profile.setProjCont(entries);
    });
  }

  void deleteEntry(int index) {
    if (entries.length > 1) {
      setState(() {
        entries.removeAt(index);
        widget.profile.setProjCont(entries);
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
                      onChanged: (value) {
                        setState(() {
                          widget.profile.setProjCont(entries);
                        });
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  Tooltip(
                    message: 'Completed project ${index + 1}?',
                    child: Checkbox(
                      value: entry.completed,
                      onChanged: (bool? value) {
                        setState(() {
                          entry.completed = value ?? false;
                          widget.profile.setProjCont(entries);
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
                        widget.profile.setProjCont(entries);
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
                onChanged: (value) {
                  setState(() {
                    widget.profile.setProjCont(entries);
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
                    widget.profile.setProjCont(entries);
                  });
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
                      onPressed: () {
                        addEntry(index);
                        widget.profile.setProjCont(entries);
                      },
                    ),
                  ),
                  Tooltip(
                    message: 'Clear Entries For Project ${index + 1}',
                    child: IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        clearEntry(index);
                        widget.profile.setProjCont(entries);
                      },
                    ),
                  ),
                  Tooltip(
                    message: 'Delete Entry For Project ${index + 1}',
                    child: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        deleteEntry(index);
                        widget.profile.setProjCont(entries);
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

  void addEntry(int index) {
    setState(() {
      entries.insert(index + 1, ProfileSkillsCont());
      widget.profile.setSkillsCont(entries);
    });
  }

  void clearEntry(int index) {
    setState(() {
      entries[index].skillCategory.text = '';
      entries[index].desInfo.text = '';
      widget.profile.setSkillsCont(entries);
    });
  }

  void deleteEntry(int index) {
    if (entries.length > 1) {
      setState(() {
        entries.removeAt(index);
        widget.profile.setSkillsCont(entries);
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
                      onChanged: (value) {
                        setState(() {
                          widget.profile.setSkillsCont(entries);
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: standardSizedBoxHeight),
              TextFormField(
                controller: entry.desInfo,
                keyboardType: TextInputType.multiline,
                maxLines: 10,
                decoration: InputDecoration(hintText: 'Enter skills here...'),
                onChanged: (value) {
                  setState(() {
                    widget.profile.setSkillsCont(entries);
                  });
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
                        widget.profile.setSkillsCont(entries);
                      },
                    ),
                  ),
                  Tooltip(
                    message: 'Clear Entries For Skill Category ${index + 1}',
                    child: IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        clearEntry(index);
                        widget.profile.setSkillsCont(entries);
                      },
                    ),
                  ),
                  Tooltip(
                    message: 'Delete Entry Skill Category ${index + 1}',
                    child: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        deleteEntry(index);
                        widget.profile.setSkillsCont(entries);
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
