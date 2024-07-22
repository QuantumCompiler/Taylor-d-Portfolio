// ignore_for_file: unused_local_variable
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../Globals/Globals.dart';
import '../Globals/JobsGlobals.dart';
import '../Utilities/GlobalUtils.dart';

class Job {
  // Boolean
  final bool? newJob;

  // Files
  late File jobFile;

  // Strings
  late String name;

  // List Of Types
  late List<JobDesCont> descriptionContList = [];
  late List<JobOtherCont> otherInfoContList = [];
  late List<JobRoleCont> roleContList = [];
  late List<JobSkillsCont> skillsContList = [];

  // Text Editing Controller
  TextEditingController nameController = TextEditingController();

  Job._({
    required this.newJob,
    required this.name,
    required this.descriptionContList,
    required this.otherInfoContList,
    required this.roleContList,
    required this.skillsContList,
    required this.nameController,
  });

  static Future<Job> Init({String name = '', required bool? newJob}) async {
    // Lists for each section
    List<JobDesCont> descriptionContList = [];
    List<JobOtherCont> otherInfoContList = [];
    List<JobRoleCont> roleContList = [];
    List<JobSkillsCont> skillsContList = [];
    // New job initializer
    String finalDir = '';
    if (newJob == true) {
      finalDir = 'Temp';
    } else if (newJob == false) {
      finalDir = 'Jobs/$name';
    }
    // Set lists
    descriptionContList = await LoadContent<JobDesCont>(descriptionJSONFile, finalDir, (entry) => JobDesCont.fromJSON(entry));
    otherInfoContList = await LoadContent<JobOtherCont>(otherJSONFile, finalDir, (entry) => JobOtherCont.fromJSON(entry));
    roleContList = await LoadContent<JobRoleCont>(roleJSONFile, finalDir, (entry) => JobRoleCont.fromJSON(entry));
    skillsContList = await LoadContent<JobSkillsCont>(skillsJSONFile, finalDir, (entry) => JobSkillsCont.fromJSON(entry));
    return Job._(
      newJob: newJob,
      name: name,
      descriptionContList: descriptionContList,
      otherInfoContList: otherInfoContList,
      roleContList: roleContList,
      skillsContList: skillsContList,
      nameController: TextEditingController(text: name),
    );
  }

  static Future<List<T>> LoadContent<T>(String fileName, String subDir, T Function(Map<String, dynamic>) fromJSON) async {
    // Declare empty list
    List<T> ret = [];
    // Try to load content
    try {
      // Retrieve directories and file
      final masterDir = await getApplicationDocumentsDirectory();
      final jsonFile = File('${masterDir.path}/$subDir/$fileName');
      final fileExists = await jsonFile.exists();
      // If the file exists, map the JSON to the list
      if (fileExists) {
        return await MapJSONToList<T>(jsonFile, fromJSON);
      }
    }
    // Catch error if occurs
    catch (e) {
      throw ('An error occurred while loading content: $e');
    }
    return ret;
  }

  Future<void> CreateJob(String jobName) async {
    // Job is new
    if (newJob == true) {
      // Set job name and directory
      await SetJobName(jobName);
      await SetJobDir();
      // Attempt to write job
      try {
        // Write profile
        await WriteJob("Jobs/$name", "Jobs/$name");
        final masterDir = await getApplicationDocumentsDirectory();
        final tempDir = Directory('${masterDir.path}/Temp');
        // If the temp directory exists, clean it
        if (await tempDir.exists()) {
          // Attempt to clean the directory
          try {
            await CleanDir('Temp');
          } catch (e) {
            throw ('Error occurred in cleaning $tempDir contents: $e');
          }
        }
      } catch (e) {
        throw ('Error occurred in creating $name profile: $e');
      }
    }
    // Job is existing
    if (newJob == false) {
      // Grab name of job from the controller
      final newName = nameController.text;
      // Get directories for master, old, and existing
      final masterDir = await getApplicationDocumentsDirectory();
      final oldDir = Directory('${masterDir.path}/Jobs/$name');
      final existing = Directory('${masterDir.path}/Jobs/$newName');
      Directory newDir;
      // Old directory exists and existing directory does not
      if (oldDir.existsSync() && !existing.existsSync()) {
        // Rename old directory to existing directory
        newDir = await oldDir.rename('${masterDir.path}/Jobs/$newName');
        name = newName;
      }
      // Set new directory to the old directory
      newDir = oldDir;
      // Attempt to write profile
      try {
        await WriteJob("Jobs/$name", "Jobs/$name");
      } catch (e) {
        throw ('Error occurred in overwriting $name: $e');
      }
    }
  }

  // Set Content
  Future<void> SetContent<T>(List<T> inputList, List<T> outputList) async {
    outputList.clear();
    outputList.addAll(inputList);
  }

  // Set Job Name
  Future<void> SetJobName(String jobName) async {
    name = jobName;
  }

  // Set Job Dir
  Future<void> SetJobDir() async {
    final masterDir = await getApplicationDocumentsDirectory();
    Directory parentDir = Directory('${masterDir.path}/Jobs/');
    CreateDir(parentDir, name);
  }

  Future<String> StringifyDes(String subDir) async {
    String ret = '';
    // Grab JSON file
    final File jsonFile = await RetJSONFile(subDir, descriptionJSONFile);
    // If the file exists, map the JSON to the list
    if (jsonFile.existsSync()) {
      try {
        // Map JSON to list
        List<dynamic> jsonData = await JSONList(jsonFile);
        // For each element in the list, add the description field to the return string
        for (int i = 0; i < jsonData.length; i++) {
          ret += "Job Description:\n\n${jsonData[i]['description']}\n\n";
        }
      } catch (e) {
        throw ('Error occurred $e');
      }
    }
    return ret;
  }

  Future<String> StringifyOther(String subDir) async {
    String ret = '';
    // Grab JSON file
    final File jsonFile = await RetJSONFile(subDir, otherJSONFile);
    // If the file exists, map the JSON to the list
    if (jsonFile.existsSync()) {
      try {
        // Map JSON to list
        List<dynamic> jsonData = await JSONList(jsonFile);
        // For each element in the list, add the description field to the return string
        for (int i = 0; i < jsonData.length; i++) {
          ret += "Other Information:\n\n${jsonData[i]['description']}\n\n";
        }
      } catch (e) {
        throw ('Error occurred $e');
      }
    }
    return ret;
  }

  Future<String> StringifyRole(String subDir) async {
    String ret = '';
    // Grab JSON file
    final File jsonFile = await RetJSONFile(subDir, roleJSONFile);
    // If the file exists, map the JSON to the list
    if (jsonFile.existsSync()) {
      try {
        // Map JSON to list
        List<dynamic> jsonData = await JSONList(jsonFile);
        // For each element in the list, add the description field to the return string
        for (int i = 0; i < jsonData.length; i++) {
          ret += "Role Requirements:\n\n${jsonData[i]['description']}\n\n";
        }
      } catch (e) {
        throw ('Error occurred $e');
      }
    }
    return ret;
  }

  Future<String> StringifySkills(String subDir) async {
    String ret = '';
    // Grab JSON file
    final File jsonFile = await RetJSONFile(subDir, skillsJSONFile);
    // If the file exists, map the JSON to the list
    if (jsonFile.existsSync()) {
      try {
        // Map JSON to list
        List<dynamic> jsonData = await JSONList(jsonFile);
        // For each element in the list, add the description field to the return string
        for (int i = 0; i < jsonData.length; i++) {
          ret += "Skill Requirements:\n\n${jsonData[i]['description']}\n\n";
        }
      } catch (e) {
        throw ('Error occurred $e');
      }
    }
    return ret;
  }

  Future<void> WriteJob(String jsonDir, String destDir) async {
    // Grab master directory
    final masterDir = await getApplicationDocumentsDirectory();
    // Write profile JSON files
    final File desFile = File('${masterDir.path}/$jsonDir/$descriptionJSONFile');
    final File othFile = File('${masterDir.path}/$jsonDir/$otherJSONFile');
    final File roleFile = File('${masterDir.path}/$jsonDir/$roleJSONFile');
    final File skillsFile = File('${masterDir.path}/$jsonDir/$skillsJSONFile');
    // Write content to JSON
    // await WriteContentToJSON<ProfileCLCont>(jsonDir, coverLetterJSONFile, coverLetterContList);
    await WriteContentToJSON<JobDesCont>(jsonDir, descriptionJSONFile, descriptionContList);
    await WriteContentToJSON<JobOtherCont>(jsonDir, otherJSONFile, otherInfoContList);
    await WriteContentToJSON<JobRoleCont>(jsonDir, roleJSONFile, roleContList);
    await WriteContentToJSON<JobSkillsCont>(jsonDir, skillsJSONFile, skillsContList);
    // If the necessary files exist, write the profile file
    if (desFile.existsSync() && othFile.existsSync() && roleFile.existsSync() && skillsFile.existsSync()) {
      // Write job JSON file
      final File jobFile = File('${masterDir.path}/$destDir/$finalJobJSONFile');
      // Decode JSON files
      final List<dynamic> desData = jsonDecode(await desFile.readAsString());
      final List<dynamic> othData = jsonDecode(await othFile.readAsString());
      final List<dynamic> roleData = jsonDecode(await roleFile.readAsString());
      final List<dynamic> skillsData = jsonDecode(await skillsFile.readAsString());
      // Combine JSON files
      final Map<String, dynamic> combinedJSON = {
        'jobName': name,
        'jobDescription': desData.isEmpty ? "" : desData,
        'jobOtherInfo': othData.isEmpty ? "" : othData,
        'jobRole': roleData.isEmpty ? "" : roleData,
        'jobSkills': skillsData.isEmpty ? "" : skillsData,
      };
      // Write profile file
      try {
        // Encode JSON
        final String jsonString = jsonEncode(combinedJSON);
        // Write job file
        await jobFile.writeAsString(jsonString);
        String desCont = await StringifyDes(jsonDir);
        String othCont = await StringifyOther(jsonDir);
        String roleCont = await StringifyRole(jsonDir);
        String skillsCont = await StringifySkills(jsonDir);
        // Concatenate strings
        String finalRet = desCont + othCont + roleCont + skillsCont;
        // Write final job file
        Directory finalDir = Directory('${masterDir.path}/$destDir');
        final finalJobFile = File('${finalDir.path}/$finalJobTextFile');
        await WriteFile(finalDir, finalJobFile, finalRet);
      }
      // Catch error if occurs
      catch (e) {
        throw ('Error ocurred in writing profile file: $e');
      }
    }
  }

  // Write Content To JSON
  Future<void> WriteContentToJSON<T>(String subDir, String fileName, List<T> list) async {
    // Grab master directory
    final masterDir = await getApplicationDocumentsDirectory();
    Directory desDir = Directory('${masterDir.path}/$subDir');
    // If the directory does not exist, create it
    if (!desDir.existsSync()) {
      desDir.createSync();
    }
    // Create file
    final file = File('${desDir.path}/$fileName');
    if (file.existsSync()) {
      file.deleteSync();
    }
    // Map list to JSON
    List<Map<String, dynamic>> contJSON = list.map((cont) {
      // If the type is job description
      if (cont is JobDesCont) {
        return (cont as JobDesCont).toJSON();
      }
      // If the type is other info
      else if (cont is JobOtherCont) {
        return (cont as JobOtherCont).toJSON();
      }
      // If the type is role
      else if (cont is JobRoleCont) {
        return (cont as JobRoleCont).toJSON();
      }
      // If the type is skills
      else if (cont is JobSkillsCont) {
        return (cont as JobSkillsCont).toJSON();
      }
      // If the type is not recognized
      else {
        throw Exception("Type T does not have a toJSON method");
      }
    }).toList();
    // Encode JSON
    String jsonString = jsonEncode(contJSON);
    // Write JSON to file
    await file.writeAsString(jsonString);
  }
}

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Description Content
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
class JobDesCont {
  late TextEditingController description;
  JobDesCont() {
    description = TextEditingController();
  }
  JobDesCont.fromJSON(Map<String, dynamic> json) {
    description = TextEditingController(text: json['description'] ?? '');
  }
  Map<String, dynamic> toJSON() {
    return {
      'description': description.text,
    };
  }
}

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Description Content Entry
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
class DescriptionJobEntry extends StatefulWidget {
  final Job job;

  const DescriptionJobEntry({
    super.key,
    required this.job,
  });

  @override
  DescriptionJobEntryState createState() => DescriptionJobEntryState();
}

class DescriptionJobEntryState extends State<DescriptionJobEntry> {
  List<JobDesCont> entries = [];

  @override
  void initState() {
    super.initState();
    initializeEntries();
  }

  void initializeEntries() async {
    if (widget.job.descriptionContList.isNotEmpty) {
      await widget.job.SetContent<JobDesCont>(widget.job.descriptionContList, entries);
    } else {
      entries.add(JobDesCont());
    }
  }

  void clearEntry(int index) async {
    setState(() {
      entries[index].description.text = '';
    });
    await widget.job.SetContent<JobDesCont>(widget.job.descriptionContList, entries);
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
              JobDesCont entryData = entry.value;
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
    JobDesCont entry,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: standardSizedBoxHeight),
        Center(
          child: Text(
            'Enter Job Description',
            style: TextStyle(
              fontSize: secondaryTitles,
              fontWeight: FontWeight.bold,
            ),
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
                controller: entry.description,
                keyboardType: TextInputType.multiline,
                maxLines: 15,
                decoration: InputDecoration(hintText: 'Enter the job description here...'),
                onChanged: (value) async {
                  await widget.job.SetContent<JobDesCont>(entries, widget.job.descriptionContList);
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
              message: 'Clear Description Entry',
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
//  Other Information Content
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
class JobOtherCont {
  late TextEditingController description;
  JobOtherCont() {
    description = TextEditingController();
  }
  JobOtherCont.fromJSON(Map<String, dynamic> json) {
    description = TextEditingController(text: json['description'] ?? '');
  }
  Map<String, dynamic> toJSON() {
    return {
      'description': description.text,
    };
  }
}

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Other Information Content Entry
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
class OtherInfoJobEntry extends StatefulWidget {
  final Job job;

  const OtherInfoJobEntry({
    super.key,
    required this.job,
  });

  @override
  OtherInfoJobEntryState createState() => OtherInfoJobEntryState();
}

class OtherInfoJobEntryState extends State<OtherInfoJobEntry> {
  List<JobOtherCont> entries = [];

  @override
  void initState() {
    super.initState();
    initializeEntries();
  }

  void initializeEntries() async {
    if (widget.job.otherInfoContList.isNotEmpty) {
      await widget.job.SetContent<JobOtherCont>(widget.job.otherInfoContList, entries);
    } else {
      entries.add(JobOtherCont());
    }
  }

  void clearEntry(int index) async {
    setState(() {
      entries[index].description.text = '';
    });
    await widget.job.SetContent<JobOtherCont>(widget.job.otherInfoContList, entries);
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
              JobOtherCont entryData = entry.value;
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
    JobOtherCont entry,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: standardSizedBoxHeight),
        Center(
          child: Text(
            'Enter Other Information',
            style: TextStyle(
              fontSize: secondaryTitles,
              fontWeight: FontWeight.bold,
            ),
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
                controller: entry.description,
                keyboardType: TextInputType.multiline,
                maxLines: 15,
                decoration: InputDecoration(hintText: 'Enter the other information here...'),
                onChanged: (value) async {
                  await widget.job.SetContent<JobOtherCont>(entries, widget.job.otherInfoContList);
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
              message: 'Clear Other Info Entry',
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
//  Role Content
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
class JobRoleCont {
  late TextEditingController description;
  JobRoleCont() {
    description = TextEditingController();
  }
  JobRoleCont.fromJSON(Map<String, dynamic> json) {
    description = TextEditingController(text: json['description'] ?? '');
  }
  Map<String, dynamic> toJSON() {
    return {
      'description': description.text,
    };
  }
}

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Role Content Entry
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
class RoleJobEntry extends StatefulWidget {
  final Job job;

  const RoleJobEntry({
    super.key,
    required this.job,
  });

  @override
  RoleJobEntryState createState() => RoleJobEntryState();
}

class RoleJobEntryState extends State<RoleJobEntry> {
  List<JobRoleCont> entries = [];

  @override
  void initState() {
    super.initState();
    initializeEntries();
  }

  void initializeEntries() async {
    if (widget.job.roleContList.isNotEmpty) {
      await widget.job.SetContent<JobRoleCont>(widget.job.roleContList, entries);
    } else {
      entries.add(JobRoleCont());
    }
  }

  void clearEntry(int index) async {
    setState(() {
      entries[index].description.text = '';
    });
    await widget.job.SetContent<JobRoleCont>(widget.job.roleContList, entries);
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
              JobRoleCont entryData = entry.value;
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
    JobRoleCont entry,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: standardSizedBoxHeight),
        Center(
          child: Text(
            'Enter Role Information',
            style: TextStyle(
              fontSize: secondaryTitles,
              fontWeight: FontWeight.bold,
            ),
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
                controller: entry.description,
                keyboardType: TextInputType.multiline,
                maxLines: 15,
                decoration: InputDecoration(hintText: 'Enter role information here...'),
                onChanged: (value) async {
                  await widget.job.SetContent<JobRoleCont>(entries, widget.job.roleContList);
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
              message: 'Clear Role Info Entry',
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
//  Skills Content
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
class JobSkillsCont {
  late TextEditingController description;
  JobSkillsCont() {
    description = TextEditingController();
  }
  JobSkillsCont.fromJSON(Map<String, dynamic> json) {
    description = TextEditingController(text: json['description'] ?? '');
  }
  Map<String, dynamic> toJSON() {
    return {
      'description': description.text,
    };
  }
}

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Skills Content Entry
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
class SkillsJobEntry extends StatefulWidget {
  final Job job;

  const SkillsJobEntry({
    super.key,
    required this.job,
  });

  @override
  SkillsJobEntryState createState() => SkillsJobEntryState();
}

class SkillsJobEntryState extends State<SkillsJobEntry> {
  List<JobSkillsCont> entries = [];

  @override
  void initState() {
    super.initState();
    initializeEntries();
  }

  void initializeEntries() async {
    if (widget.job.skillsContList.isNotEmpty) {
      await widget.job.SetContent<JobSkillsCont>(widget.job.skillsContList, entries);
    } else {
      entries.add(JobSkillsCont());
    }
  }

  void clearEntry(int index) async {
    setState(() {
      entries[index].description.text = '';
    });
    await widget.job.SetContent<JobSkillsCont>(widget.job.skillsContList, entries);
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
              JobSkillsCont entryData = entry.value;
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
    JobSkillsCont entry,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: standardSizedBoxHeight),
        Center(
          child: Text(
            'Enter Skill Requirements',
            style: TextStyle(
              fontSize: secondaryTitles,
              fontWeight: FontWeight.bold,
            ),
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
                controller: entry.description,
                keyboardType: TextInputType.multiline,
                maxLines: 15,
                decoration: InputDecoration(hintText: 'Enter skill requirements here...'),
                onChanged: (value) async {
                  await widget.job.SetContent<JobSkillsCont>(entries, widget.job.skillsContList);
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
              message: 'Clear Skill Requirements Entry',
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
