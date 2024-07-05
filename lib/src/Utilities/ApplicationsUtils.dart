import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../Context/NewApplicationContext.dart';
import '../Globals/ApplicationsGlobals.dart';
import '../Globals/Globals.dart';
import '../Globals/JobsGlobals.dart';
import '../Globals/ProfilesGlobals.dart';

class ApplicationContent {
  final jobs;
  final profiles;
  List<String> checkedJobs = [];
  List<String> checkedProfiles = [];

  ApplicationContent({
    required this.jobs,
    required this.profiles,
    List<String>? checkedJobs,
    List<String>? checkedProfiles,
  }) {
    this.checkedJobs = checkedJobs ?? [];
    this.checkedProfiles = checkedProfiles ?? [];
  }

  // Clear Checkboxes
  void clearBoxes(List<String> checkedJ, List<String> checkedP, Function setState) {
    setState(() {
      checkedJ.clear();
      checkedP.clear();
    });
  }

  // Get Content
  List<String> getContent() {
    List<String> names = [];
    names.add(checkedJobs[0]);
    names.add(checkedProfiles[0]);
    return names;
  }

  // Update Checkboxes
  void updateBoxes(List<String> checks, String key, bool? value, Function setState) {
    setState(() {
      if (value == true && checks.isEmpty) {
        checks.add(key);
      } else if (value == false && checks.contains(key)) {
        checks.remove(key);
      }
    });
  }

  // Verify Checkboxes
  bool verifyBoxes() {
    bool jobsValid = checkedJobs.length == 1;
    bool profilesValid = checkedProfiles.length == 1;
    return jobsValid && profilesValid;
  }
}

class OpenAI {
  static final String _apikey = dotenv.env[apiKey]!;
  final ApplicationContent content;
  final String openAIModel;
  static String? _systemRole;
  static String? _userPrompt;
  final int maxTokens;

  OpenAI({
    required this.content,
    required this.openAIModel,
    required this.maxTokens,
  });

  Future<void> prepRecPrompt() async {
    List<String> names = content.getContent();
    List<List<String>> appContent = await prepContent(names);
    final jobContent = prepJobContent(
      appContent[0][1],
      appContent[0][1],
      appContent[0][2],
      appContent[0][3],
    );
    final profContent = prepProfContent(
      appContent[1][0],
      appContent[1][1],
      appContent[1][2],
      appContent[1][3],
    );
    String finalPrompt = "$jobContentPrompt ${jsonEncode(jobContent)}\\n$profContentPrompt ${jsonEncode(profContent)}\\n$returnPrompt";
    _systemRole = hiringManagerRole;
    _userPrompt = finalPrompt;
  }

  Future<Map<String, dynamic>> getRecs() async {
    await prepRecPrompt();
    const url = 'https://api.openai.com/v1/chat/completions';
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apikey',
    };
    final body = jsonEncode({
      'model': openAIModel,
      'messages': [
        {'role': 'system', 'content': _systemRole},
        {'role': 'user', 'content': _userPrompt}
      ],
      'max_tokens': maxTokens,
    });
    try {
      final response = await http.post(Uri.parse(url), headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String responseText = data['choices'][0]['message']['content'].trim();
        responseText = responseText.replaceAll('```json\n', '').replaceAll('```', '');
        Map<String, dynamic> jsonResponse = jsonDecode(responseText);
        return jsonResponse;
      } else {
        throw Exception('Failed to load data: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Failed to load data: $e');
    }
  }
}

Future<List<File>> getJobFiles(String name) async {
  List<File> files = [];
  final jobsDir = await GetJobsDir();
  final currJob = Directory('${jobsDir.path}/$name');
  File desFile = File('${currJob.path}/$descriptionFile');
  File othFile = File('${currJob.path}/$otherFile');
  File qualFile = File('${currJob.path}/$qualificationsFile');
  File roleFile = File('${currJob.path}/$roleInfoFile');
  files.add(desFile);
  files.add(othFile);
  files.add(qualFile);
  files.add(roleFile);
  return files;
}

Future<List<String>> convertJobDescToString(List<File> files) async {
  List<String> contents = [];
  String description = await files[0].readAsString();
  String other = await files[1].readAsString();
  String qualifications = await files[2].readAsString();
  String roleInfo = await files[3].readAsString();
  contents.add(description);
  contents.add(other);
  contents.add(qualifications);
  contents.add(roleInfo);
  return contents;
}

Future<List<File>> getProfileFiles(String name) async {
  List<File> files = [];
  final profsDir = await GetProfilesDir();
  final currProf = Directory('${profsDir.path}/$name');
  File eduFile = File('${currProf.path}/$educationFile');
  File expFile = File('${currProf.path}/$experienceFile');
  File projFile = File('${currProf.path}/$projectsFile');
  File skiFile = File('${currProf.path}/$skillsFile');
  files.add(eduFile);
  files.add(expFile);
  files.add(projFile);
  files.add(skiFile);
  return files;
}

Future<List<String>> convertProfDescToString(List<File> files) async {
  List<String> contents = [];
  String education = await files[0].readAsString();
  String experience = await files[1].readAsString();
  String projects = await files[2].readAsString();
  String skills = await files[3].readAsString();
  contents.add(education);
  contents.add(experience);
  contents.add(projects);
  contents.add(skills);
  return contents;
}

Future<List<List<String>>> prepContent(List<String> names) async {
  List<List<String>> content = [];
  List<File> jobFiles = await getJobFiles(names[0]);
  List<String> jobContent = await convertJobDescToString(jobFiles);
  List<File> profFiles = await getProfileFiles(names[1]);
  List<String> profContent = await convertProfDescToString(profFiles);
  content.add(jobContent);
  content.add(profContent);
  return content;
}

String prepJobContent(String des, String other, String quals, String role) {
  return jsonEncode({
    "Job Description:": des,
    "Other Information:": other,
    "Qualifications Information:": quals,
    "Role Information:": role,
  });
}

String prepProfContent(String edu, String exp, String proj, String skills) {
  return jsonEncode({
    "Education:": edu,
    "Experience:": exp,
    "Projects:": proj,
    "Skills:": skills,
  });
}

Future<Map<String, dynamic>> getOpenAIRecs(BuildContext context, ApplicationContent content) async {
  showLoadingDialog(context);
  try {
    final openAICall = OpenAI(
      content: content,
      openAIModel: gpt_4o,
      maxTokens: 500,
    );
    Map<String, dynamic> result = await openAICall.getRecs();
    Navigator.of(context).pop();
    return result;
  } catch (e) {
    if (kDebugMode) {
      print('Error: $e');
    }
    rethrow;
  } finally {
    showProducedDialog(context);
  }
}
