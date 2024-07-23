// ignore_for_file: unused_local_variable
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../Globals/Globals.dart';
import '../Globals/JobsGlobals.dart';
import '../Utilities/GlobalUtils.dart';

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Job Class
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
/*  Job - Job object
      Boolean:
        * newJob - Determines if the job is new or existing
      Files:
        * jobFile - File that is the job file
      Strings:
        * name - Name of the job
      List Of Types:
        * descriptionContList - List of Job Description Content
        * otherInfoContList - List of Job Other Information Content
        * roleContList - List of Job Role Content
        * skillsContList - List of Job Skills Content
      Text Editing Controller:
        * nameController - Text Editing Controller for the name
      Constructor:
        * Job._ - Initializes a job object
      Functions:
        * Init - Initializes a job object
        * LoadContent - Loads content from a JSON file
        * CreateJob - Creates a job object
        * SetContent - Sets the content of a list
        * SetJobName - Sets the name of the job
        * SetJobDir - Sets the directory of the job
        * StringifyDes - Stringifies the job description
        * StringifyOther - Stringifies the other information
        * StringifyRole - Stringifies the role
        * StringifySkills - Stringifies the skills
        * WriteJob - Writes the job to a file
        * WriteContentToJSON - Writes content to a JSON file
*/
class Job {
  // Boolean
  final bool newJob;
  bool isSelected;

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

  // Constructor
  Job._({
    required this.newJob,
    required this.name,
    required this.descriptionContList,
    required this.otherInfoContList,
    required this.roleContList,
    required this.skillsContList,
    required this.nameController,
    required this.isSelected,
  });

  /*  Init - Initializes a job object
        Input:
          name - String that is the name of the job (optional)
          newJob - Boolean that determines if the job is new or existing
        Algorithm:
          * Initialize lists for each section
          * If the job is new, set the directory to Temp
          * If the job is existing, set the directory to Jobs/name
          * Load content for each section
        Output:
          Job object
  */
  static Future<Job> Init({String name = '', required bool newJob}) async {
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
      isSelected: false,
    );
  }

  /*  LoadContent - Loads content from a JSON file
        Class T Declaration:
          * JobDesCont - Job Description Content
          * JobOtherCont - Job Other Information Content
          * JobRoleCont - Job Role Content
          * JobSkillsCont - Job Skills Content
        Input:
          fileName - String that is the name of the file
          subDir - String that is the subdirectory of the file
          fromJSON - Function that maps JSON to a type
        Algorithm:
          * Declare empty list
          * Try to load content
            * If the file exists, map the JSON to the list
        Output:
          List of type T
  */
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

  /*  CreateJob - Creates a job object
        Input:
          jobName - String that is the name of the job
        Algorithm:
          * If the job is new
            * Set the job name and directory
            * Write the job
            * Clean the Temp directory
          * If the job is existing
            * Get the name of the job from the controller
            * Get directories for master, old, and existing
            * If the old directory exists and the existing directory does not
              * Rename the old directory to the existing directory
            * Set the new directory to the old directory
            * Attempt to write the job
        Output:
          Creates files for a job
  */
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
      // Attempt to write job
      try {
        await WriteJob("Jobs/$name", "Jobs/$name");
      } catch (e) {
        throw ('Error occurred in overwriting $name: $e');
      }
    }
  }

  /*  SetContent - Sets the content of a list
        Class T Declaration:
          * JobDesCont - Job Description Content
          * JobOtherCont - Job Other Information Content
          * JobRoleCont - Job Role Content
          * JobSkillsCont - Job Skills Content
        Input:
          inputList - List of type T that is the input list
          outputList - List of type T that is the output list
        Algorithm:
          * Clear the output list
          * Add all elements from the input list to the output list
        Output:
          Sets the content of a list
  */
  Future<void> SetContent<T>(List<T> inputList, List<T> outputList) async {
    outputList.clear();
    outputList.addAll(inputList);
  }

  /*  SetJobName - Sets the name of the job
        Input:
          jobName - String that is the name of the job
        Algorithm:
          * Set the name of the job to the class variable
        Output:
          Sets the name of the job
  */
  Future<void> SetJobName(String jobName) async {
    name = jobName;
  }

  /*  SetJobDir - Sets the directory of the job
        Input:
          None
        Algorithm:
          * Get the master directory
          * Set the parent directory to Jobs
          * Create the directory
        Output:
          Sets the directory of the job
  */
  Future<void> SetJobDir() async {
    final masterDir = await getApplicationDocumentsDirectory();
    Directory parentDir = Directory('${masterDir.path}/Jobs/');
    CreateDir(parentDir, name);
  }

  /*  StringifyDes - Stringifies the job description
        Input:
          subDir - String that is the subdirectory of the file
        Algorithm:
          * Declare empty string
          * Grab JSON file
          * If the file exists, map the JSON to the list
          * For each element in the list, add the description field to the return string
        Output:
          Stringified job description
  */
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

  /*  StringifyOther - Stringifies the other information
        Input:
          subDir - String that is the subdirectory of the file
        Algorithm:
          * Declare empty string
          * Grab JSON file
          * If the file exists, map the JSON to the list
          * For each element in the list, add the description field to the return string
        Output:
          Stringified other information
  */
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

  /*  StringifyRole - Stringifies the role
        Input:
          subDir - String that is the subdirectory of the file
        Algorithm:
          * Declare empty string
          * Grab JSON file
          * If the file exists, map the JSON to the list
          * For each element in the list, add the description field to the return string
        Output:
          Stringified role
  */
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

  /*  StringifySkills - Stringifies the skills
        Input:
          subDir - String that is the subdirectory of the file
        Algorithm:
          * Declare empty string
          * Grab JSON file
          * If the file exists, map the JSON to the list
          * For each element in the list, add the description field to the return string
        Output:
          Stringified skills
  */
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

  /*  WriteJob - Writes the job to a file
        Input:
          jsonDir - String that is the subdirectory of the JSON files
          destDir - String that is the subdirectory of the destination files
        Algorithm:
          * Grab master directory
          * Write profile JSON files
          * If the necessary files exist, write the job file
            * Decode JSON files
            * Combine JSON files
            * Write job file
          * Catch error if occurs
        Output:
          Writes the job to a file
  */
  Future<void> WriteJob(String jsonDir, String destDir) async {
    // Grab master directory
    final masterDir = await getApplicationDocumentsDirectory();
    // Write profile JSON files
    final File desFile = File('${masterDir.path}/$jsonDir/$descriptionJSONFile');
    final File othFile = File('${masterDir.path}/$jsonDir/$otherJSONFile');
    final File roleFile = File('${masterDir.path}/$jsonDir/$roleJSONFile');
    final File skillsFile = File('${masterDir.path}/$jsonDir/$skillsJSONFile');
    // Write content to JSON
    await WriteContentToJSON<JobDesCont>(jsonDir, descriptionJSONFile, descriptionContList);
    await WriteContentToJSON<JobOtherCont>(jsonDir, otherJSONFile, otherInfoContList);
    await WriteContentToJSON<JobRoleCont>(jsonDir, roleJSONFile, roleContList);
    await WriteContentToJSON<JobSkillsCont>(jsonDir, skillsJSONFile, skillsContList);
    // If the necessary files exist, write the job file
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
      // Write job file
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

  /*  WriteContentToJSON - Writes content to a JSON file
        Class T Declaration:
          * JobDesCont - Job Description Content
          * JobOtherCont - Job Other Information Content
          * JobRoleCont - Job Role Content
          * JobSkillsCont - Job Skills Content
        Input:
          subDir - String that is the subdirectory of the file
          fileName - String that is the name of the file
          list - List of type T that is the list to write
        Algorithm:
          * Grab master directory
          * If the directory does not exist, create it
          * Create file
          * Map list to JSON
          * Encode JSON
          * Write JSON to file
        Output:
          Writes content to a JSON file
  */
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
/*  JobDesCont - Job Description Content
      Text Editing Controller:
        * description - Text Editing Controller for the description
      Constructor:
        * JobDesCont - Initializes a job description content object
        * JobDesCont.fromJSON - Converts the description to JSON
      Functions:
        * toJSON - Converts the description to JSON
*/
class JobDesCont {
  late TextEditingController description;
  JobDesCont() {
    description = TextEditingController();
  }
  /*  JobDesCont.fromJSON - Converts the description to JSON
        Input:
          json - Map of strings to dynamic
        Algorithm:
          * Return the description as JSON
        Output:
          Description as JSON
  */
  JobDesCont.fromJSON(Map<String, dynamic> json) {
    description = TextEditingController(text: json['description'] ?? '');
  }
  /*  toJSON - Converts the description to JSON
        Input:
          None
        Algorithm:
          * Return the description as JSON
        Output:
          Description as JSON
  */
  Map<String, dynamic> toJSON() {
    return {
      'description': description.text,
    };
  }
}

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Description Content Entry
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
/*  DescriptionJobEntry - Description Job Entry
      Job:
        * job - Job object
      List Of Types:
        * entries - List of Job Description Content
      Functions:
        * initState - Initializes the description entries
        * initializeEntries - Initializes the description entries
        * clearEntry - Clears the description entry
        * build - Builds the description entry
        * buildContEntry - Builds the description content entry
*/
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

  /*  initializeEntries - Initializes the description entries
        Input:
          None
        Algorithm:
          * If the job description content list is not empty, set the content
          * Otherwise, add a new description entry
        Output:
          Initializes the description entries
  */
  void initializeEntries() async {
    if (widget.job.descriptionContList.isNotEmpty) {
      await widget.job.SetContent<JobDesCont>(widget.job.descriptionContList, entries);
    } else {
      entries.add(JobDesCont());
    }
  }

  /*  clearEntry - Clears the description entry
        Input:
          index - Integer that is the index of the entry
        Algorithm:
          * Set the description to an empty string
          * Set the state
          * Write the content to the job
        Output:
          Clears the description entry
  */
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
        // Title
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
              // Description
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
            // Clear Button
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
/*  JobOtherCont - Job Other Information Content
      Text Editing Controller:
        * description - Text Editing Controller for the description
      Constructor:
        * JobOtherCont - Initializes a job other information content object
        * JobOtherCont.fromJSON - Converts the description to JSON
      Functions:
        * toJSON - Converts the description to JSON
*/
class JobOtherCont {
  late TextEditingController description;
  JobOtherCont() {
    description = TextEditingController();
  }
  /*  JobOtherCont.fromJSON - Converts the description to JSON
        Input:
          json - Map of strings to dynamic
        Algorithm:
          * Return the description as JSON
        Output:
          Description as JSON
  */
  JobOtherCont.fromJSON(Map<String, dynamic> json) {
    description = TextEditingController(text: json['description'] ?? '');
  }
  /*  toJSON - Converts the description to JSON
        Input:
          None
        Algorithm:
          * Return the description as JSON
        Output:
          Description as JSON
  */
  Map<String, dynamic> toJSON() {
    return {
      'description': description.text,
    };
  }
}

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Other Information Content Entry
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
/*  OtherInfoJobEntry - Other Information Job Entry
      Job:
        * job - Job object
      List Of Types:
        * entries - List of Job Other Information Content
      Functions:
        * initState - Initializes the other information entries
        * initializeEntries - Initializes the other information entries
        * clearEntry - Clears the other information entry
        * build - Builds the other information entry
        * buildContEntry - Builds the other information content entry
*/
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

  /*  initializeEntries - Initializes the other information entries
        Input:
          None
        Algorithm:
          * If the job other information content list is not empty, set the content
          * Otherwise, add a new other information entry
        Output:
          Initializes the other information entries
  */
  void initializeEntries() async {
    if (widget.job.otherInfoContList.isNotEmpty) {
      await widget.job.SetContent<JobOtherCont>(widget.job.otherInfoContList, entries);
    } else {
      entries.add(JobOtherCont());
    }
  }

  /*  clearEntry - Clears the other information entry
        Input:
          index - Integer that is the index of the entry
        Algorithm:
          * Set the description to an empty string
          * Set the state
          * Write the content to the job
        Output:
          Clears the other information entry
  */
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
        // Title
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
              // Description
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
            // Clear Button
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
/*  JobRoleCont - Job Role Content
      Text Editing Controller:
        * description - Text Editing Controller for the description
      Constructor:
        * JobRoleCont - Initializes a job role content object
        * JobRoleCont.fromJSON - Converts the description to JSON
      Functions:
        * toJSON - Converts the description to JSON
*/
class JobRoleCont {
  late TextEditingController description;
  JobRoleCont() {
    description = TextEditingController();
  }
  /*  JobRoleCont.fromJSON - Converts the description to JSON
        Input:
          json - Map of strings to dynamic
        Algorithm:
          * Return the description as JSON
        Output:
          Description as JSON
  */
  JobRoleCont.fromJSON(Map<String, dynamic> json) {
    description = TextEditingController(text: json['description'] ?? '');
  }
  /*  toJSON - Converts the description to JSON
        Input:
          None
        Algorithm:
          * Return the description as JSON
        Output:
          Description as JSON
  */
  Map<String, dynamic> toJSON() {
    return {
      'description': description.text,
    };
  }
}

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Role Content Entry
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
/*  RoleJobEntry - Role Job Entry
      Job:
        * job - Job object
      List Of Types:
        * entries - List of Job Role Content
      Functions:
        * initState - Initializes the role entries
        * initializeEntries - Initializes the role entries
        * clearEntry - Clears the role entry
        * build - Builds the role entry
        * buildContEntry - Builds the role content entry
*/
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

  /*  initializeEntries - Initializes the role entries
        Input:
          None
        Algorithm:
          * If the job role content list is not empty, set the content
          * Otherwise, add a new role entry
        Output:
          Initializes the role entries
  */
  void initializeEntries() async {
    if (widget.job.roleContList.isNotEmpty) {
      await widget.job.SetContent<JobRoleCont>(widget.job.roleContList, entries);
    } else {
      entries.add(JobRoleCont());
    }
  }

  /*  clearEntry - Clears the role entry
        Input:
          index - Integer that is the index of the entry
        Algorithm:
          * Set the description to an empty string
          * Set the state
          * Write the content to the job
        Output:
          Clears the role entry
  */
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
        // Title
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
              // Description
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
            // Clear Button
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
/*  JobSkillsCont - Job Skills Content
      Text Editing Controller:
        * description - Text Editing Controller for the description
      Constructor:
        * JobSkillsCont - Initializes a job skills content object
        * JobSkillsCont.fromJSON - Converts the description to JSON
      Functions:
        * toJSON - Converts the description to JSON
*/
class JobSkillsCont {
  late TextEditingController description;
  JobSkillsCont() {
    description = TextEditingController();
  }
  /*  JobSkillsCont.fromJSON - Converts the description to JSON
        Input:
          json - Map of strings to dynamic
        Algorithm:
          * Return the description as JSON
        Output:
          Description as JSON
  */
  JobSkillsCont.fromJSON(Map<String, dynamic> json) {
    description = TextEditingController(text: json['description'] ?? '');
  }
  /*  toJSON - Converts the description to JSON
        Input:
          None
        Algorithm:
          * Return the description as JSON
        Output:
          Description as JSON
  */
  Map<String, dynamic> toJSON() {
    return {
      'description': description.text,
    };
  }
}

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Skills Content Entry
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
/*  SkillsJobEntry - Skills Job Entry
      Job:
        * job - Job object
      List Of Types:
        * entries - List of Job Skills Content
      Functions:
        * initState - Initializes the skill entries
        * initializeEntries - Initializes the skill entries
        * clearEntry - Clears the skill entry
        * build - Builds the skill entry
        * buildContEntry - Builds the skill content entry
*/
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

  /*  initializeEntries - Initializes the skill entries
        Input:
          None
        Algorithm:
          * If the job skill content list is not empty, set the content
          * Otherwise, add a new skill entry
        Output:
          Initializes the skill entries
  */
  void initializeEntries() async {
    if (widget.job.skillsContList.isNotEmpty) {
      await widget.job.SetContent<JobSkillsCont>(widget.job.skillsContList, entries);
    } else {
      entries.add(JobSkillsCont());
    }
  }

  /*  clearEntry - Clears the skill entry
        Input:
          index - Integer that is the index of the entry
        Algorithm:
          * Set the description to an empty string
          * Set the state
          * Write the content to the job
        Output:
          Clears the skill entry
  */
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
        // Title
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
              // Description
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
            // Clear Button
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
