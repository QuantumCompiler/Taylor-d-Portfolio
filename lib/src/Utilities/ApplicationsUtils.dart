import 'dart:io';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
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
  final String openAIModel;
  final String systemRole;
  final String userPrompt;
  final int maxTokens;

  OpenAI({
    required this.openAIModel,
    required this.systemRole,
    required this.userPrompt,
    required this.maxTokens,
  });

  Future<Map<String, dynamic>> testPrompt() async {
    const url = 'https://api.openai.com/v1/chat/completions';
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apikey',
    };
    final body = jsonEncode({
      'model': openAIModel,
      'messages': [
        {'role': 'system', 'content': systemRole},
        {'role': 'user', 'content': userPrompt}
      ],
      'max_tokens': maxTokens,
    });

    try {
      final response = await http.post(Uri.parse(url), headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String responseText = data['choices'][0]['message']['content'].trim();
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
  File posFile = File('${currJob.path}/$positionFile');
  File qualFile = File('${currJob.path}/$qualificationsFile');
  File roleFile = File('${currJob.path}/$roleInfoFile');
  File taskFile = File('${currJob.path}/$tasksFile');
  files.add(desFile);
  files.add(othFile);
  files.add(posFile);
  files.add(qualFile);
  files.add(roleFile);
  files.add(taskFile);
  return files;
}

Future<List<String>> convertJobDescToString(List<File> files) async {
  List<String> contents = [];
  String description = await files[0].readAsString();
  String other = await files[1].readAsString();
  String position = await files[2].readAsString();
  String qualifications = await files[3].readAsString();
  String roleInfo = await files[4].readAsString();
  String tasks = await files[5].readAsString();
  contents.add(description);
  contents.add(other);
  contents.add(position);
  contents.add(qualifications);
  contents.add(roleInfo);
  contents.add(tasks);
  return contents;
}

Future<List<File>> getProfileFiles(String name) async {
  List<File> files = [];
  final profsDir = await GetProfilesDir();
  final currProf = Directory('${profsDir.path}/$name');
  File eduFile = File('${currProf.path}/$educationFile');
  File expFile = File('${currProf.path}/$experienceFile');
  File extFile = File('${currProf.path}/$extracurricularFile');
  File honFile = File('${currProf.path}/$honorsFile');
  File projFile = File('${currProf.path}/$projectsFile');
  File refFile = File('${currProf.path}/$referencesFile');
  File skiFile = File('${currProf.path}/$skillsFile');
  files.add(eduFile);
  files.add(expFile);
  files.add(extFile);
  files.add(honFile);
  files.add(projFile);
  files.add(refFile);
  files.add(skiFile);
  return files;
}

Future<List<String>> convertProfDescToString(List<File> files) async {
  List<String> contents = [];
  String education = await files[0].readAsString();
  String experience = await files[1].readAsString();
  String extracurricular = await files[2].readAsString();
  String honors = await files[3].readAsString();
  String projects = await files[4].readAsString();
  String references = await files[5].readAsString();
  String skills = await files[6].readAsString();
  contents.add(education);
  contents.add(experience);
  contents.add(extracurricular);
  contents.add(honors);
  contents.add(projects);
  contents.add(references);
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
