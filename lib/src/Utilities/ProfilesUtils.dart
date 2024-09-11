// ignore_for_file: unused_local_variable
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../Context/Globals/GlobalContext.dart';
import '../Globals/Globals.dart';
import '../Globals/ProfilesGlobals.dart';
import '../Utilities/GlobalUtils.dart';

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Profile Class
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
/*  Profile Class - Class for the Profile
      Fields:
        newProfile - Boolean for whether the profile is new
        proFile - File for the profile
        name - String for the name of the profile
        coverLetterContList - List of ProfileCLCont objects
        eduContList - List of ProfileEduCont objects
        expContList - List of ProfileExpCont objects
        projContList - List of ProfileProjCont objects
        skillsContList - List of ProfileSkillsCont objects
        nameController - Text Editing Controller for the name field
      Methods:
        Init - Initializes a profile
        CreateProfile - Creates a profile with the given name
        LoadContent - Loads content from a JSON file into a list
        SetContent - Sets content from one list to another
        SetProfName - Sets the name of the profile
        SetProfDir - Sets the directory for the profile
        StringifyCLCont - Stringifies the cover letter content
        StringifyEduCont - Stringifies the education content
        StringifyExpCont - Stringifies the experience content
        StringifyProjCont - Stringifies the project content
        StringifySkillsCont - Stringifies the skills content
        WriteProfile - Writes the profile to a JSON file
        WriteContentToJSON - Writes content to a JSON file
*/
class Profile {
  // Boolean
  final bool newProfile;
  bool isSelected;

  // Files
  late File proFile;

  // Strings
  late String name;

  // Lists Of Types
  late List<ProfileCLCont> coverLetterContList = [];
  late List<ProfileEduCont> eduContList = [];
  late List<ProfileExpCont> expContList = [];
  late List<ProfileProjCont> projContList = [];
  late List<ProfileSkillsCont> skillsContList = [];

  // Text Editing Controller
  TextEditingController nameController = TextEditingController();

  // Constructor
  Profile._({
    required this.newProfile,
    required this.name,
    required this.coverLetterContList,
    required this.eduContList,
    required this.expContList,
    required this.projContList,
    required this.skillsContList,
    required this.nameController,
    required this.isSelected,
  });

  /*  Init - Initializes a profile
        Input:
          name - String for the name of the profile (optional)
          newProfile - Boolean for whether the profile is new or not
        Algorithm:
          * Create empty lists for each section
          * If the profile is new
            * Load content from Temp application directory
          * If the profile already exists
            * Load content from existing profile
        Output:
          Profile object
  */
  static Future<Profile> Init({String name = '', required bool newProfile}) async {
    // Lists of content for each section
    List<ProfileCLCont> coverLetterContList = [];
    List<ProfileEduCont> eduContList = [];
    List<ProfileExpCont> expContList = [];
    List<ProfileProjCont> projContList = [];
    List<ProfileSkillsCont> skillsContList = [];
    // New profile initializer
    String finalDir = '';
    if (newProfile == true) {
      finalDir = 'Temp';
    } else if (newProfile == false) {
      finalDir = 'Profiles/$name';
    }
    // Set lists
    coverLetterContList = await LoadContent<ProfileCLCont>(coverLetterJSONFile, finalDir, (entry) => ProfileCLCont.fromJSON(entry));
    eduContList = await LoadContent<ProfileEduCont>(educationJSONFile, finalDir, (entry) => ProfileEduCont.fromJSON(entry));
    expContList = await LoadContent<ProfileExpCont>(experienceJSONFile, finalDir, (entry) => ProfileExpCont.fromJSON(entry));
    projContList = await LoadContent<ProfileProjCont>(projectsJSONFile, finalDir, (entry) => ProfileProjCont.fromJSON(entry));
    skillsContList = await LoadContent<ProfileSkillsCont>(skillsJSONFile, finalDir, (entry) => ProfileSkillsCont.fromJSON(entry));
    // Return profile
    return Profile._(
      newProfile: newProfile,
      name: name,
      coverLetterContList: coverLetterContList,
      eduContList: eduContList,
      expContList: expContList,
      projContList: projContList,
      skillsContList: skillsContList,
      nameController: TextEditingController(text: name),
      isSelected: false,
    );
  }

  /*  CreateProfile - Creates a profile with the given name
        Input:
          profName - String for the name of the profile
        Algorithm:
          * If the profile is new
            * Set profile name and directory
            * Write profile
            * Clean temp directory
          * If the profile already exists
            * Get directories for master, old, and existing
            * If the old directory exists and the existing directory does not
              * Rename the old directory to the existing directory
            * Set new directory to the old directory
            * Write profile
        Output:
          Writes files, creates directory for profile, and cleans temp directory
  */
  Future<void> CreateProfile(String profName) async {
    // Profile is new
    if (newProfile == true) {
      // Set profile name and directory
      await SetProfName(profName);
      await SetProfDir();
      // Attempt to write profile
      try {
        // Write profile
        await WriteProfile("Profiles/$name", "Profiles/$name");
        final masterDir = await GetAppDir();
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
    // Profile is existing
    if (newProfile == false) {
      // Grab name of profile from the controller
      final newName = nameController.text;
      // Get directories for master, old, and existing
      final masterDir = await GetAppDir();
      final oldDir = Directory('${masterDir.path}/Profiles/$name');
      final existing = Directory('${masterDir.path}/Profiles/$newName');
      Directory newDir;
      // Old directory exists and existing directory does not
      if (oldDir.existsSync() && !existing.existsSync()) {
        // Rename old directory to existing directory
        newDir = await oldDir.rename('${masterDir.path}/Profiles/$newName');
        name = newName;
      }
      // Set new directory to the old directory
      newDir = oldDir;
      // Attempt to write profile
      try {
        await WriteProfile("Profiles/$name", "Profiles/$name");
      } catch (e) {
        throw ('Error occurred in overwriting $name: $e');
      }
    }
  }

  /*  SetProfName - Sets the name of the profile
        Input:
          profName - String for the name of the profile
        Algorithm:
          * Set name to profName
        Output:
          Sets the name of the profile
  */
  Future<void> SetProfName(String profName) async {
    name = profName;
  }

  /*  SetProfDir - Sets the directory for the profile
        Input:
          None
        Algorithm:
          * Retrieve master directory
          * Create parent directory
          * Create directory for profile
        Output:
          Sets the directory for the profile
  */
  Future<void> SetProfDir() async {
    final masterDir = await GetAppDir();
    Directory parentDir = Directory('${masterDir.path}/Profiles/');
    CreateDir(parentDir, name);
  }

  /*  StringifyCLCont - Stringifies the cover letter content
        Input:
          subDir - String for the subdirectory to load the file from
        Algorithm:
          * Retrieve JSON file
          * If the file exists, map the JSON to the list
          * For each element in the list, add the about field to the return string
        Output:
          Stringified cover letter content
  */
  Future<String> StringifyCLCont(String subDir) async {
    String ret = '';
    // Grab JSON file
    final File jsonFile = await RetJSONFile(subDir, coverLetterJSONFile);
    // If the file exists, map the JSON to the list
    if (jsonFile.existsSync()) {
      try {
        // Map JSON to list
        List<dynamic> jsonData = await JSONList(jsonFile);
        // For each element in the list, add the about field to the return string
        for (int i = 0; i < jsonData.length; i++) {
          ret += "About Applicant:\n\n${jsonData[i]['about']}\n";
        }
      } catch (e) {
        throw ('Error occurred $e');
      }
    }
    return ret;
  }

  /*  StringifyEduCont - Stringifies the education content
        Input:
          subDir - String for the subdirectory to load the file from
        Algorithm:
          * Retrieve JSON file
          * If the file exists, map the JSON to the list
          * For each element in the list, add the name, degree, and description fields to the return string
        Output:
          Stringified education content
  */
  Future<String> StringifyEduCont(String subDir) async {
    String ret = '';
    // Grab JSON file
    final File jsonFile = await RetJSONFile(subDir, educationJSONFile);
    // If the file exists, map the JSON to the list
    if (jsonFile.existsSync()) {
      try {
        // Map JSON to list
        List<dynamic> jsonData = await JSONList(jsonFile);
        // For each element in the list, add the name, degree, and description fields to the return string
        for (int i = 0; i < jsonData.length; i++) {
          if (i == 0) {
            ret += "\nEducation Information:\n";
          }
          ret += "\nEducation Institution ${i + 1}:\n\nSchool Name: ${jsonData[i]['name']}\n\nDegree(s): ${jsonData[i]['degree']}\n\nDescription:\n\n${jsonData[i]['description']}\n";
        }
      } catch (e) {
        throw ("Error occurred $e");
      }
    }
    return ret;
  }

  /*  StringifyExpCont - Stringifies the experience content
        Input:
          subDir - String for the subdirectory to load the file from
        Algorithm:
          * Retrieve JSON file
          * If the file exists, map the JSON to the list
          * For each element in the list, add the name, position, and description fields to the return string
        Output:
          Stringified experience content
  */
  Future<String> StringifyExpCont(String subDir) async {
    String ret = '';
    // Grab JSON file
    final File jsonFile = await RetJSONFile(subDir, experienceJSONFile);
    // If the file exists, map the JSON to the list
    if (jsonFile.existsSync()) {
      try {
        // Map JSON to list
        List<dynamic> jsonData = await JSONList(jsonFile);
        // For each element in the list, add the name, position, and description fields to the return string
        for (int i = 0; i < jsonData.length; i++) {
          if (i == 0) {
            ret += "\nExperience Information:\n";
          }
          ret += "\nExperience Institution ${i + 1}:\n\nCompany Name: ${jsonData[i]['name']}\n\nPosition(s): ${jsonData[i]['position']}\n\nDescription:\n\n${jsonData[i]['description']}\n";
        }
      } catch (e) {
        throw ("Error occurred $e");
      }
    }
    return ret;
  }

  /*  StringifyProjCont - Stringifies the project content
        Input:
          subDir - String for the subdirectory to load the file from
        Algorithm:
          * Retrieve JSON file
          * If the file exists, map the JSON to the list
          * For each element in the list, add the name, role, and description fields to the return string
        Output:
          Stringified project content
  */
  Future<String> StringifyProjCont(String subDir) async {
    String ret = '';
    // Grab JSON file
    final File jsonFile = await RetJSONFile(subDir, projectsJSONFile);
    // If the file exists, map the JSON to the list
    if (jsonFile.existsSync()) {
      try {
        // Map JSON to list
        List<dynamic> jsonData = await JSONList(jsonFile);
        // For each element in the list, add the name, role, and description fields to the return string
        for (int i = 0; i < jsonData.length; i++) {
          if (i == 0) {
            ret += "\nProject Information:\n";
          }
          ret += "\nProject ${i + 1}:\n\nProject Name: ${jsonData[i]['name']}\n\nRole(s): ${jsonData[i]['role']}\n\nDescription:\n\n${jsonData[i]['description']}\n";
        }
      } catch (e) {
        throw ("Error occurred $e");
      }
    }
    return ret;
  }

  /*  StringifySkillsCont - Stringifies the skills content
        Input:
          subDir - String for the subdirectory to load the file from
        Algorithm:
          * Retrieve JSON file
          * If the file exists, map the JSON to the list
          * For each element in the list, add the name and description fields to the return string
        Output:
          Stringified skills content
  */
  Future<String> StringifySkillsCont(String subDir) async {
    String ret = '';
    // Grab JSON file
    final File jsonFile = await RetJSONFile(subDir, skillsJSONFile);
    // If the file exists, map the JSON to the list
    if (jsonFile.existsSync()) {
      try {
        // Map JSON to list
        List<dynamic> jsonData = await JSONList(jsonFile);
        // For each element in the list, add the name and description fields to the return string
        for (int i = 0; i < jsonData.length; i++) {
          if (i == 0) {
            ret += "\nSkills Information:\n";
          }
          ret += "\nSkill Category ${i + 1}:\n\nSkill Name: ${jsonData[i]['name']}\n\nDescription:\n\n${jsonData[i]['description']}\n";
        }
      } catch (e) {
        throw ("Error occurred $e");
      }
    }
    return ret;
  }

  /*  WriteProfile - Writes the profile to a JSON file
        Input:
          jsonDir - String for the subdirectory to write the JSON files
          destDir - String for the subdirectory to write the profile file
        Algorithm:
          * Write content to JSON
          * Write profile JSON files
          * If the necessary files exist
            * Create final profile JSON file
            * Decode JSON files
            * Combine JSON files
            * Write profile file
            * Create string for final profile
            * Concatenate strings
            * Write final profile (text) file
        Output:
          Writes profile files
  */
  Future<void> WriteProfile(String jsonDir, String destDir) async {
    // Grab master directory
    final masterDir = await GetAppDir();
    // Write profile JSON files
    final File covFile = File('${masterDir.path}/$jsonDir/$coverLetterJSONFile');
    final File eduFile = File('${masterDir.path}/$jsonDir/$educationJSONFile');
    final File expFile = File('${masterDir.path}/$jsonDir/$experienceJSONFile');
    final File proFile = File('${masterDir.path}/$jsonDir/$projectsJSONFile');
    final File skiFile = File('${masterDir.path}/$jsonDir/$skillsJSONFile');
    // Write content to JSON
    await WriteContentToJSON<ProfileCLCont>(jsonDir, coverLetterJSONFile, coverLetterContList);
    await WriteContentToJSON<ProfileEduCont>(jsonDir, educationJSONFile, eduContList);
    await WriteContentToJSON<ProfileExpCont>(jsonDir, experienceJSONFile, expContList);
    await WriteContentToJSON<ProfileProjCont>(jsonDir, projectsJSONFile, projContList);
    await WriteContentToJSON<ProfileSkillsCont>(jsonDir, skillsJSONFile, skillsContList);
    // If the necessary files exist, write the profile file
    if (covFile.existsSync() && eduFile.existsSync() && expFile.existsSync() && proFile.existsSync() && skiFile.existsSync()) {
      // Write profile JSON file
      final File profileFile = File('${masterDir.path}/$destDir/$finalProfileJSONFile');
      // Decode JSON files
      final List<dynamic> covData = jsonDecode(await covFile.readAsString());
      final List<dynamic> eduData = jsonDecode(await eduFile.readAsString());
      final List<dynamic> expData = jsonDecode(await expFile.readAsString());
      final List<dynamic> proData = jsonDecode(await proFile.readAsString());
      final List<dynamic> skiData = jsonDecode(await skiFile.readAsString());
      // Combine JSON files
      final Map<String, dynamic> combinedJSON = {
        'profileName': name,
        'profileCoverLetter': covData.isEmpty ? "" : covData,
        'profileEducation': eduData.isEmpty ? "" : eduData,
        'profileExperience': expData.isEmpty ? "" : expData,
        'profileProjects': proData.isEmpty ? "" : proData,
        'profileSkills': skiData.isEmpty ? "" : skiData,
      };
      // Write profile file
      try {
        // Encode JSON
        final String jsonString = jsonEncode(combinedJSON);
        // Write profile file
        await profileFile.writeAsString(jsonString);
        // Create string for final profile
        String clCont = await StringifyCLCont(jsonDir);
        String eduCont = await StringifyEduCont(jsonDir);
        String expCont = await StringifyExpCont(jsonDir);
        String proCont = await StringifyProjCont(jsonDir);
        String skillsCont = await StringifySkillsCont(jsonDir);
        // Concatenate strings
        String finalRet = clCont + eduCont + expCont + proCont + skillsCont;
        // Write final profile file
        Directory finalDir = Directory('${masterDir.path}/$destDir');
        final proFile = File('${finalDir.path}/$finalProfileTextFile');
        await WriteFile(finalDir, proFile, finalRet);
      }
      // Catch error if occurs
      catch (e) {
        throw ('Error ocurred in writing profile file: $e');
      }
    }
  }

  /*  WriteContentToJSON - Writes content to a JSON file
        Class Definition:
          T - Type of class list to write:
            * ProfileCLCont
            * ProfileEduCont
            * ProfileExpCont
            * ProfileProjCont
            * ProfileSkillsCont
        Input:
          subDir - String for the subdirectory to write the JSON files
          fileName - String for the name of the JSON file
          list - List of class type T to write
        Algorithm:
          * Grab master directory
          * Create directory
          * Create file
          * Map list to JSON
          * Encode JSON
          * Write JSON to file
        Output:
          Writes content to a JSON file
  */
  Future<void> WriteContentToJSON<T>(String subDir, String fileName, List<T> list) async {
    // Grab master directory
    final masterDir = await GetAppDir();
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
      // If the type is ProfileCLCont
      if (cont is ProfileCLCont) {
        return (cont as ProfileCLCont).toJSON();
      }
      // If the type is ProfileEduCont
      else if (cont is ProfileEduCont) {
        return (cont as ProfileEduCont).toJSON();
      }
      // If the type is ProfileExpCont
      else if (cont is ProfileExpCont) {
        return (cont as ProfileExpCont).toJSON();
      }
      // If the type is ProfileProjCont
      else if (cont is ProfileProjCont) {
        return (cont as ProfileProjCont).toJSON();
      }
      // If the type is ProfileSkillsCont
      else if (cont is ProfileSkillsCont) {
        return (cont as ProfileSkillsCont).toJSON();
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
//  Cover Letter Pitch Profile Content
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
/*  ProfileCLCont - Class for the Cover Letter Profile Content
      Fields:
        about - Text Editing Controller for the about field
      Methods:
        ProfileCLCont - Constructor for the ProfileCLCont class
        ProfileCLCont.fromJSON - Constructor for the ProfileCLCont class from JSON
        toJSON - Converts the content to JSON
*/
class ProfileCLCont {
  late TextEditingController about;
  ProfileCLCont() {
    about = TextEditingController();
  }
  /*  ProfileCLCont - Constructor for the ProfileCLCont class
        Input:
          None
        Algorithm:
          * Initialize the about field
        Output:
          ProfileCLCont object
  */
  ProfileCLCont.fromJSON(Map<String, dynamic> json) {
    about = TextEditingController(text: json['about'] ?? '');
  }
  /*  toJSON - Converts the content to JSON
        Input:
          None
        Algorithm:
          * Return a map of the about field
        Output:
          Map of the about field
  */
  Map<String, dynamic> toJSON() {
    return {
      'about': about.text,
    };
  }
}

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Cover Letter Pitch Profile Entry
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
/*  CoverLetterProfilePitchEntry - Class for the Cover Letter Profile Pitch Entry
      Fields:
        profile - Profile object
      Methods:
        CoverLetterProfilePitchEntry - Constructor for the CoverLetterProfilePitchEntry class
        initState - Initializes the state of the CoverLetterProfilePitchEntry class
        initializeEntries - Initializes the entries for the CoverLetterProfilePitchEntry class
        clearEntry - Clears the entry for the CoverLetterProfilePitchEntry class
        build - Builds the CoverLetterProfilePitchEntry class
        buildContEntry - Builds the CoverLetterProfilePitchEntry class entry
*/
class CoverLetterProfilePitchEntry extends StatefulWidget {
  final Profile profile;
  final bool viewing;

  const CoverLetterProfilePitchEntry({
    super.key,
    required this.profile,
    required this.viewing,
  });

  @override
  CoverLetterProfilePitchEntryState createState() => CoverLetterProfilePitchEntryState();
}

/*  CoverLetterProfilePitchEntryState - State for the Cover Letter Profile Pitch Entry
      Fields:
        entries - List of ProfileCLCont objects
      Methods:
        initState - Initializes the state of the CoverLetterProfilePitchEntry class
        initializeEntries - Initializes the entries for the CoverLetterProfilePitchEntry class
        clearEntry - Clears the entry for the CoverLetterProfilePitchEntry class
        build - Builds the CoverLetterProfilePitchEntry class
        buildContEntry - Builds the CoverLetterProfilePitchEntry class entry
*/
class CoverLetterProfilePitchEntryState extends State<CoverLetterProfilePitchEntry> {
  List<ProfileCLCont> entries = [];

  @override
  void initState() {
    super.initState();
    initializeEntries();
  }

  /*  initializeEntries - Initializes the entries for the CoverLetterProfilePitchEntry class
        Input:
          None
        Algorithm:
          * If the cover letter content list is not empty
            * Set entries to the cover letter content list
          * If the cover letter content list is empty
            * Add a new entry to the entries list
        Output:
          Initializes the entries for the CoverLetterProfilePitchEntry class
  */
  void initializeEntries() async {
    if (widget.profile.coverLetterContList.isNotEmpty) {
      await SetContent<ProfileCLCont>(widget.profile.coverLetterContList, entries);
    } else {
      entries.add(ProfileCLCont());
    }
  }

  /*  clearEntry - Clears the entry for the CoverLetterProfilePitchEntry class
        Input:
          index - Integer for the index of the entry to clear
        Algorithm:
          * Set the about field of the entry to an empty string
        Output:
          Clears the entry for the CoverLetterProfilePitchEntry class
  */
  void clearEntry(int index) async {
    setState(() {
      entries[index].about.text = '';
    });
    await SetContent<ProfileCLCont>(entries, widget.profile.coverLetterContList);
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
        // About Title
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
              // About TextFormField
              TextFormField(
                controller: entry.about,
                keyboardType: TextInputType.multiline,
                minLines: 1,
                maxLines: 100,
                readOnly: widget.viewing,
                decoration: InputDecoration(hintText: 'Enter details about you here...'),
                onChanged: (value) async {
                  await SetContent<ProfileCLCont>(entries, widget.profile.coverLetterContList);
                },
              ),
            ],
          ),
        ),
        SizedBox(height: standardSizedBoxHeight),
        !widget.viewing
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Tooltip for clear Entry
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
              )
            : Container(width: 0, height: 0),
      ],
    );
  }
}

// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
//  Education Profile Content
// ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
/*  ProfileEduCont - Class for the Education Profile Content
      Fields:
        description - Text Editing Controller for the description field
        degree - Text Editing Controller for the degree field
        name - Text Editing Controller for the name field
        start - DateTime for the start date
        end - DateTime for the end date
        graduated - Boolean for whether the user graduated
        include - Boolean for whether to include the entry
      Methods:
        ProfileEduCont - Constructor for the ProfileEduCont class
        ProfileEduCont.fromJSON - Constructor for the ProfileEduCont class from JSON
        toJSON - Converts the content to JSON
*/
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
  /*  ProfileEduCont - Constructor for the ProfileEduCont class
        Input:
          None
        Algorithm:
          * Initialize the description, degree, name, start, end, graduated, and include fields
        Output:
          ProfileEduCont object
  */
  ProfileEduCont.fromJSON(Map<String, dynamic> json) {
    description = TextEditingController(text: json['description'] ?? '');
    degree = TextEditingController(text: json['degree'] ?? '');
    name = TextEditingController(text: json['name'] ?? '');
    start = json['start'] != null ? DateTime.parse(json['start']) : null;
    end = json['end'] != null ? DateTime.parse(json['end']) : null;
    graduated = json['graduated'] ?? false;
    include = json['include'] ?? false;
  }
  /*  toJSON - Converts the content to JSON
        Input:
          None
        Algorithm:
          * Return a map of the name, degree, description, start, end, graduated, and include fields
        Output:
          Map of the name, degree, description, start, end, graduated, and include fields
  */
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
/*  EducationProfileEntry - Class for the Education Profile Entry
      Fields:
        profile - Profile object
      Methods:
        EducationProfileEntry - Constructor for the EducationProfileEntry class
        initState - Initializes the state of the EducationProfileEntry class
        initializeEntries - Initializes the entries for the EducationProfileEntry class
        addEntry - Adds an entry for the EducationProfileEntry class
        clearEntry - Clears the entry for the EducationProfileEntry class
        deleteEntry - Deletes the entry for the EducationProfileEntry class
        build - Builds the EducationProfileEntry class
        buildContEntry - Builds the EducationProfileEntry class entry
*/
class EducationProfileEntry extends StatefulWidget {
  final Profile profile;
  final bool viewing;

  const EducationProfileEntry({
    super.key,
    required this.profile,
    required this.viewing,
  });

  @override
  EducationProfileEntryState createState() => EducationProfileEntryState();
}

/*  EducationProfileEntryState - State for the Education Profile Entry
      Fields:
        entries - List of ProfileEduCont objects
      Methods:
        initState - Initializes the state of the EducationProfileEntry class
        initializeEntries - Initializes the entries for the EducationProfileEntry class
        addEntry - Adds an entry for the EducationProfileEntry class
        clearEntry - Clears the entry for the EducationProfileEntry class
        deleteEntry - Deletes the entry for the EducationProfileEntry class
        build - Builds the EducationProfileEntry class
        buildContEntry - Builds the EducationProfileEntry class entry
*/
class EducationProfileEntryState extends State<EducationProfileEntry> {
  List<ProfileEduCont> entries = [];

  @override
  void initState() {
    super.initState();
    initializeEntries();
  }

  /*  initializeEntries - Initializes the entries for the EducationProfileEntry class
        Input:
          None
        Algorithm:
          * If the education content list is not empty
            * Set entries to the education content list
          * If the education content list is empty
            * Add a new entry to the entries list
        Output:
          Initializes the entries for the EducationProfileEntry class
  */
  void initializeEntries() async {
    if (widget.profile.eduContList.isNotEmpty) {
      SetContent<ProfileEduCont>(widget.profile.eduContList, entries);
    } else {
      entries.add(ProfileEduCont());
    }
  }

  /*  addEntry - Adds an entry for the EducationProfileEntry class
        Input:
          index - Integer for the index of the entry to add
        Algorithm:
          * Add a new entry to the entries list
        Output:
          Adds an entry for the EducationProfileEntry class
  */
  void addEntry(int index) async {
    setState(() {
      entries.insert(index + 1, ProfileEduCont());
    });
    await SetContent<ProfileEduCont>(entries, widget.profile.eduContList);
  }

  /*  clearEntry - Clears the entry for the EducationProfileEntry class
        Input:
          index - Integer for the index of the entry to clear
        Algorithm:
          * Set the name, degree, description, start, end, graduated, and include fields of the entry to empty strings
        Output:
          Clears the entry for the EducationProfileEntry class
  */
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
    await SetContent<ProfileEduCont>(entries, widget.profile.eduContList);
  }

  /*  deleteEntry - Deletes the entry for the EducationProfileEntry class
        Input:
          index - Integer for the index of the entry to delete
        Algorithm:
          * If the number of entries is greater than 1
            * Remove the entry at the index
        Output:
          Deletes the entry for the EducationProfileEntry class
  */
  void deleteEntry(int index) async {
    if (entries.length > 1) {
      setState(() {
        entries.removeAt(index);
      });
      await SetContent<ProfileEduCont>(entries, widget.profile.eduContList);
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
        // Title
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
                  // Name TextFormField
                  Expanded(
                    child: TextFormField(
                      controller: entry.name,
                      keyboardType: TextInputType.multiline,
                      maxLines: 1,
                      readOnly: widget.viewing,
                      decoration: InputDecoration(hintText: 'Enter name here...'),
                      onChanged: (value) async {
                        setState(() {});
                        await SetContent<ProfileEduCont>(entries, widget.profile.eduContList);
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  // Graduated Checkbox
                  Tooltip(
                    message: entry.name.text.isNotEmpty ? "Graduated From ${entry.name.text}?" : "Graduated From Institution ${index + 1}?",
                    child: Checkbox(
                      value: entry.graduated,
                      onChanged: (bool? value) async {
                        if (!widget.viewing) {
                          setState(() {
                            entry.graduated = value ?? false;
                          });
                          await SetContent<ProfileEduCont>(entries, widget.profile.eduContList);
                        }
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  // Include Checkbox
                  Tooltip(
                    message: entry.name.text.isNotEmpty ? "Include ${entry.name.text} In Portfolio?" : "Include Institution ${index + 1} In Portfolio?",
                    child: Checkbox(
                      value: entry.include,
                      onChanged: (bool? value) async {
                        if (!widget.viewing) {
                          setState(() {
                            entry.include = value ?? false;
                          });
                          await SetContent<ProfileEduCont>(entries, widget.profile.eduContList);
                        }
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  // Tooltip for Clear Entry
                  Tooltip(
                    message: entry.name.text.isNotEmpty ? "Start Date For ${entry.name.text}" : "Start Date For Institution ${index + 1}",
                    child: IconButton(
                      icon: Icon(Icons.date_range),
                      onPressed: () async {
                        if (!widget.viewing) {
                          entry.start = await SelectDate(context);
                          await SetContent<ProfileEduCont>(entries, widget.profile.eduContList);
                        }
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  // Tooltip for Clear Entry
                  Tooltip(
                    message: entry.name.text.isNotEmpty ? "End Date For ${entry.name.text}" : "End Date For Institution ${index + 1}",
                    child: IconButton(
                      icon: Icon(Icons.date_range),
                      onPressed: () async {
                        if (!widget.viewing) {
                          entry.end = await SelectDate(context);
                          await SetContent<ProfileEduCont>(entries, widget.profile.eduContList);
                        }
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: standardSizedBoxHeight),
              // Degree TextFormField
              TextFormField(
                controller: entry.degree,
                keyboardType: TextInputType.multiline,
                maxLines: 1,
                readOnly: widget.viewing,
                decoration: InputDecoration(
                  hintText: entry.name.text.isNotEmpty ? "Enter degree(s) information for ${entry.name.text} here..." : "Enter degree(s) information for Institution ${index + 1} here...",
                ),
                onChanged: (value) async {
                  await SetContent<ProfileEduCont>(entries, widget.profile.eduContList);
                },
              ),
              SizedBox(height: standardSizedBoxHeight),
              // Description TextFormField
              TextFormField(
                controller: entry.description,
                keyboardType: TextInputType.multiline,
                minLines: 10,
                maxLines: 100,
                readOnly: widget.viewing,
                decoration: InputDecoration(
                  hintText: entry.name.text.isNotEmpty ? "Enter description for ${entry.name.text} here..." : "Enter description for Institution ${index + 1} here...",
                ),
                onChanged: (value) async {
                  await SetContent<ProfileEduCont>(entries, widget.profile.eduContList);
                },
              ),
              SizedBox(height: standardSizedBoxHeight),
              !widget.viewing
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Tooltip for Add Entry
                        Tooltip(
                          message: entry.name.text.isNotEmpty ? "Add Entry After ${entry.name.text}" : "Add Entry After Institution ${index + 1}",
                          child: IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () async {
                              addEntry(index);
                            },
                          ),
                        ),
                        // Tooltip for Clear Entry
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
                          // Tooltip for Delete Entry
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
                    )
                  : Container(width: 0, height: 0),
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
/*  ProfileExpCont - Class for the Experience Profile Content
      Fields:
        description - Text Editing Controller for the description field
        name - Text Editing Controller for the name field
        position - Text Editing Controller for the position field
        start - DateTime for the start date
        end - DateTime for the end date
        working - Boolean for whether the user is still working
        include - Boolean for whether to include the entry
      Methods:
        ProfileExpCont - Constructor for the ProfileExpCont class
        ProfileExpCont.fromJSON - Constructor for the ProfileExpCont class from JSON
        toJSON - Converts the content to JSON
*/
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
  /*  ProfileExpCont - Constructor for the ProfileExpCont class
        Input:
          None
        Algorithm:
          * Initialize the name, position, description, start, end, working, and include fields
        Output:
          ProfileExpCont object
  */
  ProfileExpCont.fromJSON(Map<String, dynamic> json) {
    name = TextEditingController(text: json['name'] ?? '');
    position = TextEditingController(text: json['position'] ?? '');
    description = TextEditingController(text: json['description'] ?? '');
    start = json['start'] != null ? DateTime.parse(json['start']) : null;
    end = json['end'] != null ? DateTime.parse(json['end']) : null;
    working = json['working'] ?? false;
    include = json['include'] ?? false;
  }
  /*  toJSON - Converts the content to JSON
        Input:
          None
        Algorithm:
          * Return a map of the name, position, description, start, end, working, and include fields
        Output:
          Map of the name, position, description, start, end, working, and include fields
  */
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
/*  ExperienceProfileEntry - Class for the Experience Profile Entry
      Fields:
        profile - Profile object
      Methods:
        ExperienceProfileEntry - Constructor for the ExperienceProfileEntry class
        initState - Initializes the state of the ExperienceProfileEntry class
        initializeEntries - Initializes the entries for the ExperienceProfileEntry class
        addEntry - Adds an entry for the ExperienceProfileEntry class
        clearEntry - Clears the entry for the ExperienceProfileEntry class
        deleteEntry - Deletes the entry for the ExperienceProfileEntry class
        build - Builds the ExperienceProfileEntry class
        buildContEntry - Builds the ExperienceProfileEntry class entry
*/
class ExperienceProfileEntry extends StatefulWidget {
  final Profile profile;
  final bool viewing;

  const ExperienceProfileEntry({
    super.key,
    required this.profile,
    required this.viewing,
  });

  @override
  ExperienceProfileEntryState createState() => ExperienceProfileEntryState();
}

/*  ExperienceProfileEntryState - State for the Experience Profile Entry
      Fields:
        entries - List of ProfileExpCont objects
      Methods:
        initState - Initializes the state of the ExperienceProfileEntry class
        initializeEntries - Initializes the entries for the ExperienceProfileEntry class
        addEntry - Adds an entry for the ExperienceProfileEntry class
        clearEntry - Clears the entry for the ExperienceProfileEntry class
        deleteEntry - Deletes the entry for the ExperienceProfileEntry class
        build - Builds the ExperienceProfileEntry class
        buildContEntry - Builds the ExperienceProfileEntry class entry
*/
class ExperienceProfileEntryState extends State<ExperienceProfileEntry> {
  List<ProfileExpCont> entries = [];

  @override
  void initState() {
    super.initState();
    initializeEntries();
  }

  /*  initializeEntries - Initializes the entries for the ExperienceProfileEntry class
        Input:
          None
        Algorithm:
          * If the experience content list is not empty
            * Set entries to the experience content list
          * If the experience content list is empty
            * Add a new entry to the entries list
        Output:
          Initializes the entries for the ExperienceProfileEntry class
  */
  void initializeEntries() {
    if (widget.profile.expContList.isNotEmpty) {
      SetContent<ProfileExpCont>(widget.profile.expContList, entries);
    } else {
      entries.add(ProfileExpCont());
    }
  }

  /* addEntry - Adds an entry for the ExperienceProfileEntry class
        Input:
          index - Integer for the index of the entry to add
        Algorithm:
          * Add a new entry to the entries list
        Output:
          Adds an entry for the ExperienceProfileEntry class
  */
  void addEntry(int index) async {
    setState(() {
      entries.insert(index + 1, ProfileExpCont());
    });
    await SetContent<ProfileExpCont>(entries, widget.profile.expContList);
  }

  /*  clearEntry - Clears the entry for the ExperienceProfileEntry class
        Input:
          index - Integer for the index of the entry to clear
        Algorithm:
          * Set the name, position, description, start, end, working, and include fields of the entry to empty strings
        Output:
          Clears the entry for the ExperienceProfileEntry class
  */
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
    await SetContent<ProfileExpCont>(entries, widget.profile.expContList);
  }

  /*  deleteEntry - Deletes the entry for the ExperienceProfileEntry class
        Input:
          index - Integer for the index of the entry to delete
        Algorithm:
          * If the number of entries is greater than 1
            * Remove the entry at the index
        Output:
          Deletes the entry for the ExperienceProfileEntry class
  */
  void deleteEntry(int index) async {
    if (entries.length > 1) {
      setState(() {
        entries.removeAt(index);
      });
      await SetContent<ProfileExpCont>(entries, widget.profile.expContList);
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
        // Title
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
                    // Name TextFormField
                    child: TextFormField(
                      controller: entry.name,
                      keyboardType: TextInputType.multiline,
                      maxLines: 1,
                      readOnly: widget.viewing,
                      decoration: InputDecoration(hintText: 'Enter company name here...'),
                      onChanged: (value) async {
                        setState(() {});
                        await SetContent<ProfileExpCont>(entries, widget.profile.expContList);
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  // Still Working Checkbox
                  Tooltip(
                    message: entry.name.text.isNotEmpty ? "Sill Working At ${entry.name.text}?" : "Sill Working At Work Experience - ${index + 1}?",
                    child: Checkbox(
                      value: entry.working,
                      onChanged: (bool? value) async {
                        if (!widget.viewing) {
                          setState(() {
                            entry.working = value ?? false;
                          });
                          await SetContent<ProfileExpCont>(entries, widget.profile.expContList);
                        }
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  // Include Checkbox
                  Tooltip(
                    message: entry.name.text.isNotEmpty ? "Include ${entry.name.text} In Portfolio?" : "Include Work Experience ${index + 1} In Portfolio?",
                    child: Checkbox(
                      value: entry.include,
                      onChanged: (bool? value) async {
                        if (!widget.viewing) {
                          await SetContent<ProfileExpCont>(entries, widget.profile.expContList);
                          setState(() {
                            entry.include = value ?? false;
                          });
                        }
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  // Start Date
                  Tooltip(
                    message: entry.name.text.isNotEmpty ? "Start Date For ${entry.name.text}" : "Start Date For Work Experience ${index + 1}",
                    child: IconButton(
                      icon: Icon(Icons.date_range),
                      onPressed: () async {
                        if (!widget.viewing) {
                          entry.start = await SelectDate(context);
                          await SetContent<ProfileExpCont>(entries, widget.profile.expContList);
                        }
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  // End Date
                  Tooltip(
                    message: entry.name.text.isNotEmpty ? "End Date For ${entry.name.text}" : "End Date For Work Experience ${index + 1}",
                    child: IconButton(
                      icon: Icon(Icons.date_range),
                      onPressed: () async {
                        if (!widget.viewing) {
                          entry.end = await SelectDate(context);
                          await SetContent<ProfileExpCont>(entries, widget.profile.expContList);
                        }
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: standardSizedBoxHeight),
              // Position TextFormField
              TextFormField(
                controller: entry.position,
                keyboardType: TextInputType.multiline,
                maxLines: 1,
                readOnly: widget.viewing,
                decoration: InputDecoration(
                  hintText: entry.name.text.isNotEmpty ? "Enter position info for ${entry.name.text} here..." : "Enter position info for Work Experience ${index + 1} here...",
                ),
                onChanged: (value) async {
                  await SetContent<ProfileExpCont>(entries, widget.profile.expContList);
                },
              ),
              SizedBox(height: standardSizedBoxHeight),
              // Description TextFormField
              TextFormField(
                controller: entry.description,
                keyboardType: TextInputType.multiline,
                minLines: 10,
                maxLines: 100,
                readOnly: widget.viewing,
                decoration: InputDecoration(
                  hintText: entry.name.text.isNotEmpty ? "Enter description for ${entry.name.text} here..." : "Enter description for Work Experience ${index + 1} here...",
                ),
                onChanged: (value) async {
                  await SetContent<ProfileExpCont>(entries, widget.profile.expContList);
                },
              ),
              SizedBox(height: standardSizedBoxHeight),
              !widget.viewing
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Tooltip for Add Entry
                        Tooltip(
                          message: entry.name.text.isNotEmpty ? "Add Entry After ${entry.name.text}" : "Add Entry After Work Experience ${index + 1}",
                          child: IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () async {
                              addEntry(index);
                            },
                          ),
                        ),
                        // Tooltip for Clear Entry
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
                          // Tooltip for Delete Entry
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
                    )
                  : Container(width: 0, height: 0),
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
/*  ProfileProjCont - Class for the Projects Profile Content
      Fields:
        description - Text Editing Controller for the description field
        name - Text Editing Controller for the name field
        role - Text Editing Controller for the role field
        start - DateTime for the start date
        end - DateTime for the end date
        completed - Boolean for whether the project is completed
        include - Boolean for whether to include the entry
      Methods:
        ProfileProjCont - Constructor for the ProfileProjCont class
        ProfileProjCont.fromJSON - Constructor for the ProfileProjCont class from JSON
        toJSON - Converts the content to JSON
*/
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
  /*  ProfileProjCont - Constructor for the ProfileProjCont class
        Input:
          None
        Algorithm:
          * Initialize the name, role, description, start, end, completed, and include fields
        Output:
          ProfileProjCont object
  */
  ProfileProjCont.fromJSON(Map<String, dynamic> json) {
    name = TextEditingController(text: json['name'] ?? '');
    role = TextEditingController(text: json['role'] ?? '');
    description = TextEditingController(text: json['description'] ?? '');
    start = json['start'] != null ? DateTime.parse(json['start']) : null;
    start = json['end'] != null ? DateTime.parse(json['end']) : null;
    completed = json['completed'] ?? false;
    include = json['include'] ?? false;
  }
  /*  toJSON - Converts the content to JSON
        Input:
          None
        Algorithm:
          * Return a map of the name, role, description, start, end, completed, and include fields
        Output:
          Map of the name, role, description, start, end, completed, and include fields
  */
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
/*  ProjectProfileEntry - Class for the Project Profile Entry
      Fields:
        profile - Profile object
      Methods:
        ProjectProfileEntry - Constructor for the ProjectProfileEntry class
        initState - Initializes the state of the ProjectProfileEntry class
        initializeEntries - Initializes the entries for the ProjectProfileEntry class
        addEntry - Adds an entry for the ProjectProfileEntry class
        clearEntry - Clears the entry for the ProjectProfileEntry class
        deleteEntry - Deletes the entry for the ProjectProfileEntry class
        build - Builds the ProjectProfileEntry class
        buildContEntry - Builds the ProjectProfileEntry class entry
*/
class ProjectProfileEntry extends StatefulWidget {
  final Profile profile;
  final bool viewing;

  const ProjectProfileEntry({
    super.key,
    required this.profile,
    required this.viewing,
  });

  @override
  ProjectProfileEntryState createState() => ProjectProfileEntryState();
}

/*  ProjectProfileEntryState - State for the Project Profile Entry
      Fields:
        entries - List of ProfileProjCont objects
      Methods:
        initState - Initializes the state of the ProjectProfileEntry class
        initializeEntries - Initializes the entries for the ProjectProfileEntry class
        addEntry - Adds an entry for the ProjectProfileEntry class
        clearEntry - Clears the entry for the ProjectProfileEntry class
        deleteEntry - Deletes the entry for the ProjectProfileEntry class
        build - Builds the ProjectProfileEntry class
        buildContEntry - Builds the ProjectProfileEntry class entry
*/
class ProjectProfileEntryState extends State<ProjectProfileEntry> {
  List<ProfileProjCont> entries = [];

  @override
  void initState() {
    super.initState();
    initializeEntries();
  }

  /*  initializeEntries - Initializes the entries for the ProjectProfileEntry class
        Input:
          None
        Algorithm:
          * If the project content list is not empty
            * Set entries to the project content list
          * If the project content list is empty
            * Add a new entry to the entries list
        Output:
          Initializes the entries for the ProjectProfileEntry class
  */
  void initializeEntries() {
    if (widget.profile.projContList.isNotEmpty) {
      SetContent<ProfileProjCont>(widget.profile.projContList, entries);
    } else {
      entries.add(ProfileProjCont());
    }
  }

  /*  addEntry - Adds an entry for the ProjectProfileEntry class
        Input:
          index - Integer for the index of the entry to add
        Algorithm:
          * Add a new entry to the entries list
        Output:
          Adds an entry for the ProjectProfileEntry class
  */
  void addEntry(int index) async {
    setState(() {
      entries.insert(index + 1, ProfileProjCont());
    });
    await SetContent<ProfileProjCont>(entries, widget.profile.projContList);
  }

  /*  clearEntry - Clears the entry for the ProjectProfileEntry class
        Input:
          index - Integer for the index of the entry to clear
        Algorithm:
          * Set the name, role, description, start, end, completed, and include fields of the entry to empty strings
        Output:
          Clears the entry for the ProjectProfileEntry class
  */
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
    await SetContent<ProfileProjCont>(entries, widget.profile.projContList);
  }

  /*  deleteEntry - Deletes the entry for the ProjectProfileEntry class
        Input:
          index - Integer for the index of the entry to delete
        Algorithm:
          * If the number of entries is greater than 1
            * Remove the entry at the index
        Output:
          Deletes the entry for the ProjectProfileEntry class
  */
  void deleteEntry(int index) async {
    if (entries.length > 1) {
      setState(() {
        entries.removeAt(index);
      });
      await SetContent<ProfileProjCont>(entries, widget.profile.projContList);
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
        // Title
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
                    // Name TextFormField
                    child: TextFormField(
                      controller: entry.name,
                      keyboardType: TextInputType.multiline,
                      maxLines: 1,
                      readOnly: widget.viewing,
                      decoration: InputDecoration(hintText: 'Enter project name here...'),
                      onChanged: (value) async {
                        setState(() {});
                        await SetContent<ProfileProjCont>(entries, widget.profile.projContList);
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  // Completed Checkbox
                  Tooltip(
                    message: entry.name.text.isNotEmpty ? "Completed ${entry.name.text}?" : "Completed Project ${index + 1}?",
                    child: Checkbox(
                      value: entry.completed,
                      onChanged: (bool? value) async {
                        if (!widget.viewing) {
                          setState(() {
                            entry.completed = value ?? false;
                          });
                          await SetContent<ProfileProjCont>(entries, widget.profile.projContList);
                        }
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  // Include Checkbox
                  Tooltip(
                    message: entry.name.text.isNotEmpty ? "Include ${entry.name.text} In Portfolio?" : "Include Project ${index + 1} In Portfolio?",
                    child: Checkbox(
                      value: entry.include,
                      onChanged: (bool? value) async {
                        if (!widget.viewing) {
                          setState(() {
                            entry.include = value ?? false;
                          });
                          await SetContent<ProfileProjCont>(entries, widget.profile.projContList);
                        }
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  // Start Date
                  Tooltip(
                    message: entry.name.text.isNotEmpty ? "Start Date For ${entry.name.text}" : "Start Date For Project ${index + 1}",
                    child: IconButton(
                      icon: Icon(Icons.date_range),
                      onPressed: () async {
                        if (!widget.viewing) {
                          entry.start = await SelectDate(context);
                          await SetContent<ProfileProjCont>(entries, widget.profile.projContList);
                        }
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  // End Date
                  Tooltip(
                    message: entry.name.text.isNotEmpty ? "End Date For ${entry.name.text}" : "End Date For Project ${index + 1}",
                    child: IconButton(
                      icon: Icon(Icons.date_range),
                      onPressed: () async {
                        if (!widget.viewing) {
                          entry.end = await SelectDate(context);
                          await SetContent<ProfileProjCont>(entries, widget.profile.projContList);
                        }
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: standardSizedBoxHeight),
              // Role TextFormField
              TextFormField(
                controller: entry.role,
                keyboardType: TextInputType.multiline,
                maxLines: 1,
                readOnly: widget.viewing,
                decoration: InputDecoration(
                  hintText: entry.name.text.isNotEmpty ? "Enter role info for ${entry.name.text} here..." : "Enter role info for Project ${index + 1} here...",
                ),
                onChanged: (value) async {
                  await SetContent<ProfileProjCont>(entries, widget.profile.projContList);
                },
              ),
              SizedBox(height: standardSizedBoxHeight),
              // Description TextFormField
              TextFormField(
                controller: entry.description,
                keyboardType: TextInputType.multiline,
                minLines: 10,
                maxLines: 100,
                readOnly: widget.viewing,
                decoration: InputDecoration(
                  hintText: entry.name.text.isNotEmpty ? "Enter description for ${entry.name.text} here..." : "Enter description for Project ${index + 1} here...",
                ),
                onChanged: (value) async {
                  await SetContent<ProfileProjCont>(entries, widget.profile.projContList);
                },
              ),
              SizedBox(height: standardSizedBoxHeight),
              !widget.viewing
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Tooltip for Add Entry
                        Tooltip(
                          message: entry.name.text.isNotEmpty ? "Add Entry After ${entry.name.text}" : "Add Entry After Project ${index + 1}",
                          child: IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () async {
                              addEntry(index);
                            },
                          ),
                        ),
                        // Tooltip for Clear Entry
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
                          // Tooltip for Delete Entry
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
                    )
                  : Container(width: 0, height: 0),
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
/*  ProfileSkillsCont - Class for the Skills Profile Content
      Fields:
        description - Text Editing Controller for the description field
        name - Text Editing Controller for the name field
        include - Boolean for whether to include the entry
      Methods:
        ProfileSkillsCont - Constructor for the ProfileSkillsCont class
        ProfileSkillsCont.fromJSON - Constructor for the ProfileSkillsCont class from JSON
        toJSON - Converts the content to JSON
*/
class ProfileSkillsCont {
  late TextEditingController name;
  late TextEditingController description;
  late bool include;

  ProfileSkillsCont() {
    name = TextEditingController();
    description = TextEditingController();
    include = false;
  }
  /*  ProfileSkillsCont - Constructor for the ProfileSkillsCont class
        Input:
          None
        Algorithm:
          * Initialize the name, description, and include fields
        Output:
          ProfileSkillsCont object
  */
  ProfileSkillsCont.fromJSON(Map<String, dynamic> json) {
    name = TextEditingController(text: json['name'] ?? '');
    description = TextEditingController(text: json['description'] ?? '');
    include = json['include'] ?? false;
  }
  /*  toJSON - Converts the content to JSON
        Input:
          None
        Algorithm:
          * Return a map of the name, description, and include fields
        Output:
          Map of the name, description, and include fields
  */
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
/*  SkillsProjectEntry - Class for the Skills Project Entry
      Fields:
        profile - Profile object
      Methods:
        SkillsProjectEntry - Constructor for the SkillsProjectEntry class
        initState - Initializes the state of the SkillsProjectEntry class
        initializeEntries - Initializes the entries for the SkillsProjectEntry class
        addEntry - Adds an entry for the SkillsProjectEntry class
        clearEntry - Clears the entry for the SkillsProjectEntry class
        deleteEntry - Deletes the entry for the SkillsProjectEntry class
        build - Builds the SkillsProjectEntry class
        buildContEntry - Builds the SkillsProjectEntry class entry
*/
class SkillsProjectEntry extends StatefulWidget {
  final Profile profile;
  final bool viewing;

  const SkillsProjectEntry({
    super.key,
    required this.profile,
    required this.viewing,
  });

  @override
  SkillsProjectEntryState createState() => SkillsProjectEntryState();
}

/*  SkillsProjectEntryState - State for the Skills Project Entry
      Fields:
        entries - List of ProfileSkillsCont objects
      Methods:
        initState - Initializes the state of the SkillsProjectEntry class
        initializeEntries - Initializes the entries for the SkillsProjectEntry class
        addEntry - Adds an entry for the SkillsProjectEntry class
        clearEntry - Clears the entry for the SkillsProjectEntry class
        deleteEntry - Deletes the entry for the SkillsProjectEntry class
        build - Builds the SkillsProjectEntry class
        buildContEntry - Builds the SkillsProjectEntry class entry
*/
class SkillsProjectEntryState extends State<SkillsProjectEntry> {
  List<ProfileSkillsCont> entries = [];

  @override
  void initState() {
    super.initState();
    initializeEntries();
  }

  /*  initializeEntries - Initializes the entries for the SkillsProjectEntry class
        Input:
          None
        Algorithm:
          * If the skills content list is not empty
            * Set entries to the skills content list
          * If the skills content list is empty
            * Add a new entry to the entries list
        Output:
          Initializes the entries for the SkillsProjectEntry class
  */
  void initializeEntries() {
    if (widget.profile.skillsContList.isNotEmpty) {
      SetContent<ProfileSkillsCont>(widget.profile.skillsContList, entries);
    } else {
      entries.add(ProfileSkillsCont());
    }
  }

  /*  addEntry - Adds an entry for the SkillsProjectEntry class
        Input:
          index - Integer for the index of the entry to add
        Algorithm:
          * Add a new entry to the entries list
        Output:
          Adds an entry for the SkillsProjectEntry class
  */
  void addEntry(int index) async {
    setState(() {
      entries.insert(index + 1, ProfileSkillsCont());
    });
    await SetContent<ProfileSkillsCont>(entries, widget.profile.skillsContList);
  }

  /*  clearEntry - Clears the entry for the SkillsProjectEntry class
        Input:
          index - Integer for the index of the entry to clear
        Algorithm:
          * Set the name, description, and include fields of the entry to empty strings
        Output:
          Clears the entry for the SkillsProjectEntry class
  */
  void clearEntry(int index) async {
    setState(() {
      entries[index].name.text = '';
      entries[index].description.text = '';
      entries[index].include = false;
    });
    await SetContent<ProfileSkillsCont>(entries, widget.profile.skillsContList);
  }

  /*  deleteEntry - Deletes the entry for the SkillsProjectEntry class
        Input:
          index - Integer for the index of the entry to delete
        Algorithm:
          * If the number of entries is greater than 1
            * Remove the entry at the index
        Output:
          Deletes the entry for the SkillsProjectEntry class
  */
  void deleteEntry(int index) async {
    if (entries.length > 1) {
      setState(() {
        entries.removeAt(index);
      });
      await SetContent<ProfileSkillsCont>(entries, widget.profile.skillsContList);
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
        // Title
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
                    // Name TextFormField
                    child: TextFormField(
                      controller: entry.name,
                      keyboardType: TextInputType.multiline,
                      maxLines: 1,
                      readOnly: widget.viewing,
                      decoration: InputDecoration(hintText: 'Enter skill name here...'),
                      onChanged: (value) async {
                        setState(() {});
                        await SetContent<ProfileSkillsCont>(entries, widget.profile.skillsContList);
                      },
                    ),
                  ),
                  SizedBox(width: standardSizedBoxWidth),
                  // Include Checkbox
                  Tooltip(
                    message: entry.name.text.isNotEmpty ? "Include ${entry.name.text} In Portfolio?" : "Include Skill Category ${index + 1}",
                    child: Checkbox(
                      value: entry.include,
                      onChanged: (bool? value) async {
                        if (!widget.viewing) {
                          setState(() {
                            entry.include = value ?? false;
                          });
                          await SetContent<ProfileSkillsCont>(entries, widget.profile.skillsContList);
                        }
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: standardSizedBoxHeight),
              // Description TextFormField
              TextFormField(
                controller: entry.description,
                keyboardType: TextInputType.multiline,
                minLines: 10,
                maxLines: 100,
                readOnly: widget.viewing,
                decoration: InputDecoration(
                  hintText: entry.name.text.isNotEmpty ? "Enter skills info for ${entry.name.text} here..." : "Enter skills info for Skill Category ${index + 1} here...",
                ),
                onChanged: (value) async {
                  await SetContent<ProfileSkillsCont>(entries, widget.profile.skillsContList);
                },
              ),
              SizedBox(height: standardSizedBoxHeight),
              !widget.viewing
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Tooltip for Add Entry
                        Tooltip(
                          message: entry.name.text.isNotEmpty ? "Add Entry After ${entry.name.text}" : "Add Entry After Skill Category ${index + 1}",
                          child: IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () {
                              addEntry(index);
                            },
                          ),
                        ),
                        // Tooltip for Clear Entry
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
                          // Tooltip for Delete Entry
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
                    )
                  : Container(width: 0, height: 0),
            ],
          ),
        ),
      ],
    );
  }
}
