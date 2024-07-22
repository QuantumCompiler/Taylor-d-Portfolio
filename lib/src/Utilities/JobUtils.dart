import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../Globals/Globals.dart';
import '../Utilities/GlobalUtils.dart';

class Job {
  // Boolean
  final bool? newJob;

  // Files
  late File jobFile;

// late String qualTitle;
// late String roleTitle;

  // Strings
  late String name;

  // List Of Types
  late List<JobDesCont> descriptionContList = [];
  late List<JobOtherCont> otherInfoContList = [];
  late List<JobRoleCont> roleContList = [];

  // Text Editing Controller
  TextEditingController nameController = TextEditingController();

  Job._({
    required this.newJob,
    required this.name,
    required this.descriptionContList,
    required this.otherInfoContList,
    required this.roleContList,
    required this.nameController,
  });

  static Future<Job> Init({String name = '', required bool? newJob}) async {
    // Lists for each section
    List<JobDesCont> descriptionContList = [];
    List<JobOtherCont> otherInfoContList = [];
    List<JobRoleCont> roleContList = [];
    // New job initializer
    String finalDir = '';
    if (newJob == true) {
      finalDir = 'Temp';
    } else if (newJob == false) {
      finalDir = 'Jobs/$name';
    }
    // Set lists
    descriptionContList = [];
    otherInfoContList = [];
    roleContList = [];
    return Job._(
      newJob: newJob,
      name: name,
      descriptionContList: descriptionContList,
      otherInfoContList: otherInfoContList,
      roleContList: roleContList,
      nameController: TextEditingController(text: name),
    );
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
    if (widget.job.descriptionContList.isNotEmpty) {
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
