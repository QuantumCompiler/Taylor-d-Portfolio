import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import '../Globals/ApplicationsGlobals.dart';
import '../Globals/Globals.dart';
import '../Globals/JobsGlobals.dart';
import '../Globals/ProfilesGlobals.dart';
import '../Themes/Themes.dart';

class Application {
  // Directories
  final Future<Directory> appDir = GetAppDir();
  final Future<Directory> cacheDir = GetCacheDir();
  final Future<Directory> appsDir = GetApplicationsDir();
  final Future<Directory> supDir = GetSupportDir();

  // Required Content
  final String applicationName;
  final String profileName;
  final List<TextEditingController> controllers;

  // Files
  late File resumeZip;
  late File resumePDF;
  late File cletterZip;
  late File cletterPDF;
  late File eduRecFile;
  late File expRecFile;
  late File projRecFile;
  late File mathRecFile;
  late File persRecFile;
  late File framRecFile;
  late File langRecFile;
  late File progRecFile;
  late File sciRecFile;

  // Strings
  late String eduRecString;
  late String expRecString;
  late String projRecString;
  late String mathRecString;
  late String persRecString;
  late String framRecString;
  late String langRecString;
  late String progRecString;
  late String sciRecString;

  // Controllers
  late TextEditingController eduRecCont;
  late TextEditingController expRecCont;
  late TextEditingController projRecCont;
  late TextEditingController mathRecCont;
  late TextEditingController persRecCont;
  late TextEditingController framRecCont;
  late TextEditingController langRecCont;
  late TextEditingController progRecCont;
  late TextEditingController sciRecCont;

  // Constructor
  Application({
    required this.applicationName,
    required this.profileName,
    required this.controllers,
  }) {
    eduRecCont = controllers[0];
    expRecCont = controllers[1];
    projRecCont = controllers[2];
    mathRecCont = controllers[3];
    persRecCont = controllers[4];
    framRecCont = controllers[5];
    langRecCont = controllers[6];
    progRecCont = controllers[7];
    sciRecCont = controllers[8];
  }

  // Create New Application
  Future<void> CreateNewApplication() async {
    await setAppDir();
    await setWriteRecFiles();
    await finDoc('Resume');
  }

  // Load Previous Application
  Future<void> LoadAppData() async {
    final applicationsDir = await appsDir;
    final currApp = Directory('${applicationsDir.path}/$applicationName');
    eduRecFile = File('${currApp.path}/Recommendations/EducationRec.txt');
    expRecFile = File('${currApp.path}/Recommendations/ExperienceRec.txt');
    projRecFile = File('${currApp.path}/Recommendations/ProjectsRec.txt');
    mathRecFile = File('${currApp.path}/Recommendations/MathSkillsRec.txt');
    persRecFile = File('${currApp.path}/Recommendations/PersSkillsRec.txt');
    framRecFile = File('${currApp.path}/Recommendations/FrameworkRec.txt');
    langRecFile = File('${currApp.path}/Recommendations/ProgLangRec.txt');
    progRecFile = File('${currApp.path}/Recommendations/ProgSkillsRec.txt');
    sciRecFile = File('${currApp.path}/Recommendations/ScientificSkillsRec.txt');
    if (eduRecFile.existsSync()) {
      eduRecString = await eduRecFile.readAsString();
    }
    if (expRecFile.existsSync()) {
      expRecString = await expRecFile.readAsString();
    }
    if (projRecFile.existsSync()) {
      projRecString = await projRecFile.readAsString();
    }
    if (mathRecFile.existsSync()) {
      mathRecString = await mathRecFile.readAsString();
    }
    if (persRecFile.existsSync()) {
      persRecString = await persRecFile.readAsString();
    }
    if (framRecFile.existsSync()) {
      framRecString = await framRecFile.readAsString();
    }
    if (langRecFile.existsSync()) {
      langRecString = await langRecFile.readAsString();
    }
    if (progRecFile.existsSync()) {
      progRecString = await progRecFile.readAsString();
    }
    if (sciRecFile.existsSync()) {
      sciRecString = await sciRecFile.readAsString();
    }
  }

  // Setters

  // Set App Dir
  Future<void> setAppDir() async {
    final parentDir = await appsDir;
    Directory appNameDir = Directory('${(await appsDir).path}/$applicationName');
    const String recs = 'Recommendations';
    const String zips = 'Zip Files';
    const String docs = 'Finished Documents';
    await CreateDir(parentDir, applicationName);
    await CreateDir(appNameDir, recs);
    await CreateDir(appNameDir, zips);
    await CreateDir(appNameDir, docs);
  }

  // Set Write Rec Files
  Future<void> setWriteRecFiles() async {
    final dir = await appsDir;
    final currDir = Directory('${dir.path}/$applicationName');
    eduRecFile = File('${currDir.path}/Recommendations/EducationRec.txt');
    expRecFile = File('${currDir.path}/Recommendations/ExperienceRec.txt');
    projRecFile = File('${currDir.path}/Recommendations/ProjectsRec.txt');
    mathRecFile = File('${currDir.path}/Recommendations/MathSkillsRec.txt');
    persRecFile = File('${currDir.path}/Recommendations/PersSkillsRec.txt');
    framRecFile = File('${currDir.path}/Recommendations/FrameworkRec.txt');
    langRecFile = File('${currDir.path}/Recommendations/ProgLangRec.txt');
    progRecFile = File('${currDir.path}/Recommendations/ProgSkillsRec.txt');
    sciRecFile = File('${currDir.path}/Recommendations/ScientificSkillsRec.txt');
    WriteFile(dir, eduRecFile, eduRecCont.text);
    WriteFile(dir, expRecFile, expRecCont.text);
    WriteFile(dir, projRecFile, projRecCont.text);
    WriteFile(dir, mathRecFile, mathRecCont.text);
    WriteFile(dir, persRecFile, persRecCont.text);
    WriteFile(dir, framRecFile, framRecCont.text);
    WriteFile(dir, langRecFile, langRecCont.text);
    WriteFile(dir, progRecFile, progRecCont.text);
    WriteFile(dir, sciRecFile, sciRecCont.text);
  }

  Future<void> moveAndDelZip(String sourceSubDir, String targetSubDir, String zipName, bool deleteSrc) async {
    final masterAppDir = await appDir;
    Directory sourceDir = Directory('${masterAppDir.path}/$sourceSubDir');
    Directory targetDir = Directory('${masterAppDir.path}/$targetSubDir');
    final File sourceZip = File('${sourceDir.path}/$zipName');
    await sourceZip.copy('${targetDir.path}/$zipName');
    if (deleteSrc) {
      await sourceZip.delete();
    }
  }

  Future<void> unzipFile(String sourceSubDir, String targetSubDir, String zipName, bool deleteSrc) async {
    final masterAppDir = await appDir;
    Directory sourceDir = Directory('${masterAppDir.path}/$sourceSubDir/$zipName');
    Directory targetDir = Directory('${masterAppDir.path}/$targetSubDir');
    final bytes = File(sourceDir.path).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive) {
      final filename = p.join(targetDir.path, file.name);
      if (file.isFile) {
        final data = file.content as List<int>;
        File(filename)
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
      } else {
        Directory(filename).createSync(recursive: true);
      }
    }
    if (deleteSrc) {
      final File oldZip = File(sourceDir.path);
      await oldZip.delete();
    }
  }

  Future<void> renameAndZipDir(String sourceSubDir, String newName, bool rename) async {
    final masterAppDir = await appDir;
    Directory originalDir = Directory('${masterAppDir.path}/$sourceSubDir/');
    String finalDirPath = originalDir.path;
    Directory dirToDelete = originalDir;
    if (rename) {
      var newPath = '${originalDir.parent.path}/$newName';
      await originalDir.rename(newPath);
      finalDirPath = newPath;
      dirToDelete = Directory(newPath);
    }
    final zipFilePath = '${finalDirPath.trimRight()}.zip';
    final zipFile = File(zipFilePath);
    final archive = Archive();
    List<FileSystemEntity> entities = Directory(finalDirPath).listSync(recursive: true);
    for (FileSystemEntity entity in entities) {
      if (entity is File) {
        final filename = p.relative(entity.path, from: finalDirPath);
        final data = entity.readAsBytesSync();
        archive.addFile(ArchiveFile(filename, data.length, data));
      }
    }
    final bytes = ZipEncoder().encode(archive);
    if (bytes != null) {
      zipFile.writeAsBytesSync(bytes);
    }
    await dirToDelete.delete(recursive: true);
  }

  Future<void> finDoc(String newDirName) async {
    await moveAndDelZip('Temp', 'Applications/$applicationName/Zip Files/', 'Return.zip', true);
    await unzipFile('Applications/$applicationName/Zip Files/', 'Applications/$applicationName/Zip Files/', 'Return.zip', true);
    await renameAndZipDir('Applications/$applicationName/Zip Files/Return', newDirName, true);
    await moveAndDelZip('Applications/$applicationName/Zip Files/', 'Applications/$applicationName/Finished Documents/', '$newDirName.zip', false);
    await unzipFile('Applications/$applicationName/Finished Documents/', 'Applications/$applicationName/Finished Documents/$newDirName', '$newDirName.zip', true);
  }

  Future<String> retrievePDFDir(String subDir, String pdfFileName) async {
    final masterAppsDir = await appsDir;
    final pdfFilePath = '${masterAppsDir.path}/$applicationName/Finished Documents/$subDir/$pdfFileName';
    return pdfFilePath;
  }
}

Future<void> DeleteAllApplications() async {
  final appsDir = await GetApplicationsDir();
  final List<FileSystemEntity> apps = appsDir.listSync();
  for (final app in apps) {
    if (app is Directory) {
      app.deleteSync(recursive: true);
    }
  }
}

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
  showLoadingDialog(context, 'Getting OpenAI Recommendations...');
  try {
    final openAICall = OpenAI(
      content: content,
      openAIModel: gpt_4o,
      maxTokens: 1000,
    );
    Map<String, dynamic> result = await openAICall.getRecs();
    Navigator.of(context).pop();
    await showProducedDialog(context, 'Open AI Recommendations Produced!');
    return result;
  } catch (e) {
    if (kDebugMode) {
      print('Error: $e');
    }
    Navigator.of(context).pop();
    rethrow;
  }
}

List<Widget> openAIEntry(BuildContext context, String title, TextEditingController controller, String hintText, {int? lines = 10}) {
  return [
    Center(
      child: Text(
        title,
        style: TextStyle(
          color: themeTextColor(context),
          fontSize: secondaryTitles,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    SizedBox(height: standardSizedBoxHeight),
    Center(
      child: Container(
        width: MediaQuery.of(context).size.width * jobContainerWidth,
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.multiline,
          maxLines: lines,
          decoration: InputDecoration(hintText: hintText.isEmpty ? null : hintText),
        ),
      ),
    ),
    SizedBox(height: 20),
  ];
}

String escapeLatex(String input) {
  return input.replaceAll('&', r'\&');
}

Future<void> getSkillsRecs(List<TextEditingController> controllers) async {
  Directory appDir = await GetAppDir();
  Directory temp = Directory('${appDir.path}/Temp');
  if (temp.existsSync()) {
    await temp.delete(recursive: true);
  }
  await temp.create();
  File mathRecs = File('${temp.path}/Math.txt');
  File persRecs = File('${temp.path}/Personal.txt');
  File framRecs = File('${temp.path}/Frameworks.txt');
  File langRecs = File('${temp.path}/Languages.txt');
  File progRecs = File('${temp.path}/Programming.txt');
  File sciRecs = File('${temp.path}/Scientific.txt');
  WriteFile(temp, mathRecs, escapeLatex(controllers[3].text));
  WriteFile(temp, persRecs, escapeLatex(controllers[4].text));
  WriteFile(temp, framRecs, escapeLatex(controllers[5].text));
  WriteFile(temp, langRecs, escapeLatex(controllers[6].text));
  WriteFile(temp, progRecs, escapeLatex(controllers[7].text));
  WriteFile(temp, sciRecs, escapeLatex(controllers[8].text));
}

Future<void> copyRecsToMainResumeLaTeX(List<TextEditingController> controllers) async {
  Directory appDir = await GetAppDir();
  Directory mainLaTeXDir = await GetLaTeXDir();
  Directory tempDir = Directory('${appDir.path}/Temp/');
  Directory resumeTxTDir = Directory('${mainLaTeXDir.path}/Main LaTeX/Resume/First Page/Qualifications/Txt/');
  if (!(await tempDir.exists())) {
    if (kDebugMode) {
      print("Temp directory does not exist");
    }
    return;
  }
  if (!(await resumeTxTDir.exists())) {
    await resumeTxTDir.create(recursive: true);
  }
  List<FileSystemEntity> tempEntities = tempDir.listSync();
  for (FileSystemEntity entity in tempEntities) {
    if (entity is File) {
      String newPath = '${resumeTxTDir.path}/${entity.uri.pathSegments.last}';
      File newFile = File(newPath);
      await entity.copy(newFile.path);
    }
  }
}

Future<void> compilePortfolio(BuildContext context, List<TextEditingController> controllers) async {
  showLoadingDialog(context, 'Compiling Portfolio');
  await getSkillsRecs(controllers);
  await copyRecsToMainResumeLaTeX(controllers);
  Directory mainLaTeXDir = await GetLaTeXDir();
  Directory resumeDir = Directory('${mainLaTeXDir.path}/Main LaTeX/Resume/');
  File resumeZip = await zipResume(resumeDir);
  try {
    await uploadZipFile(resumeZip);
    Navigator.of(context).pop();
    await showProducedDialog(context, 'Portfolio Compiled Successfully.');
  } catch (e) {
    if (kDebugMode) {
      print('Error: $e');
    }
  }
}

Future<void> uploadZipFile(File zipFile) async {
  var request = http.MultipartRequest('POST', Uri.parse('http://82.180.161.189:3000/compile'));
  request.files.add(await http.MultipartFile.fromPath('file', zipFile.path));
  var response = await request.send();
  if (response.statusCode == 200) {
    var responseBody = await response.stream.toBytes();
    Directory appDir = await GetAppDir();
    String filePath = p.join("${appDir.path}/Temp", 'Return.zip');
    File file = File(filePath);
    await file.writeAsBytes(responseBody);
  }
  zipFile.deleteSync();
}

Future<File> zipResume(Directory masterDir) async {
  Directory appDocDir = await GetAppDir();
  Directory tempDir = Directory('${appDocDir.path}/Temp');
  String zipFilePath = '${tempDir.path}/Resume.zip';
  var encoder = ZipFileEncoder();
  encoder.create(zipFilePath);
  encoder.addDirectory(masterDir, includeDirName: false);
  encoder.close();
  cleanTempResume();
  return File(zipFilePath);
}

Future<void> cleanTempResume() async {
  Directory appDocDir = await GetAppDir();
  Directory tempDir = Directory('${appDocDir.path}/Temp');
  List<FileSystemEntity> tempEntities = tempDir.listSync();
  for (FileSystemEntity entity in tempEntities) {
    if (entity is File) {
      if (p.extension(entity.path) == '.txt') {
        entity.deleteSync();
      }
    }
  }
}

Future<List<Application>> RetrieveSortedApplications() async {
  final appsDir = await GetApplicationsDir();
  List<Application> applications = [];
  if (appsDir.existsSync()) {
    for (var entity in appsDir.listSync()) {
      if (entity is Directory) {
        String appName = entity.path.split('/').last;
        applications.add(Application(
          applicationName: appName,
          profileName: '',
          controllers: List.generate(9, (index) => TextEditingController()),
        ));
      }
    }
  }
  applications.sort((a, b) => a.applicationName.compareTo(b.applicationName));
  return applications;
}

Future<void> CreateNewApplication(ApplicationContent content, List<TextEditingController> controllers) async {
  Application newApp = new Application(
    applicationName: content.checkedJobs[0].toString(),
    profileName: content.checkedProfiles[0].toString(),
    controllers: controllers,
  );
  Directory appsDir = await GetApplicationsDir();
  Directory newDir = Directory('${appsDir.path}/${newApp.applicationName}');
  if (newDir.existsSync()) {
    newDir.deleteSync(recursive: true);
  }
  newApp.CreateNewApplication();
}

void showLoadingDialog(BuildContext context, String content) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(content),
              SizedBox(width: standardSizedBoxHeight),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> showProducedDialog(BuildContext context, String content) async {
  Timer? timer;
  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      timer = Timer(Duration(seconds: 2), () {
        Navigator.of(context).pop();
      });
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [SizedBox(width: 16), Text(content)],
          ),
        ),
      );
    },
  );
  timer?.cancel();
}
