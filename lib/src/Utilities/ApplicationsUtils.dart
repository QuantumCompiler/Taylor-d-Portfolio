import 'dart:async';
import 'dart:convert';
import 'dart:io';
// import 'package:flutter/gestures.dart';
// import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
// import '../Globals/ApplicationsGlobals.dart';
// import 'package:archive/archive_io.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:path/path.dart' as p;
// import '../Globals/ApplicationsGlobals.dart';
// import '../Globals/Globals.dart';
// import '../Globals/JobsGlobals.dart';
// import '../Globals/ProfilesGlobals.dart';
// import '../Themes/Themes.dart';
import '../Utilities/GlobalUtils.dart';
import '../Utilities/JobUtils.dart';
import '../Utilities/ProfilesUtils.dart';

class Application {
  // Directories
  final Future<Directory> appDir = GetAppDir();
  final Future<Directory> cacheDir = GetCacheDir();
  final Future<Directory> supDir = GetSupportDir();
  final Future<Directory> appsDir = GetApplicationsDir();
  final Future<Directory> jobsDir = GetJobsDir();
  final Future<Directory> profsDir = GetProfilesDir();

  // Booleans
  final bool newApp;

  // Content
  late String name;
  late Job jobUsed;
  late Profile profileUsed;

  // Master Files
  late File coverLetterPDF;
  late File coverLetterZip;
  late File jobContFile;
  late File portfolioPDF;
  late File portfolioZip;
  late File profileContFile;
  late File resumePDF;
  late File resumeZip;

  // Recommendations Files
  late File eduRecFile;
  late File expRecFile;
  late File frameRecFile;
  late File mathSkillsRecFile;
  late File persSkillsRecFile;
  late File progLangRecFile;
  late File progSkillsRecFile;
  late File projRecFile;
  late File sciRecFile;
  late File whyJobFile;
  late File whyMeFile;

  // Constructor
  Application._({
    required this.newApp,
    required this.name,
    required this.jobUsed,
    required this.profileUsed,
    required this.coverLetterPDF,
    required this.coverLetterZip,
    required this.portfolioPDF,
    required this.portfolioZip,
    required this.resumePDF,
    required this.resumeZip,
    required this.eduRecFile,
    required this.expRecFile,
    required this.frameRecFile,
    required this.mathSkillsRecFile,
    required this.persSkillsRecFile,
    required this.progLangRecFile,
    required this.progSkillsRecFile,
    required this.projRecFile,
    required this.sciRecFile,
    required this.whyJobFile,
    required this.whyMeFile,
  });

  // Init
  static Future<Application> Init({String name = '', required bool newApp}) async {
    final masterDir = getApplicationDocumentsDirectory();
    Future<Job> futureJob = Job.Init(newJob: false);
    Future<Profile> futureProfile = Profile.Init(newProfile: false);
    Job jobUsed = await futureJob;
    Profile profileUsed = await futureProfile;
    // Main Files
    File cPDF = File('$masterDir/Temp/CoverLetter.pdf');
    File cZip = File('$masterDir/Temp/CoverLetter.zip');
    File pPDF = File('$masterDir/Temp/Portfolio.pdf');
    File pZip = File('$masterDir/Temp/Portfolio.zip');
    File rPDF = File('$masterDir/Temp/Resume.pdf');
    File rZip = File('$masterDir/Temp/Resume.zip');
    // Recommendation Files
    File eduRec = File('$masterDir/Temp/Education.txt');
    File expRec = File('$masterDir/Temp/Experience.txt');
    File frameRec = File('$masterDir/Temp/Frameworks.txt');
    File langRec = File('$masterDir/Temp/Languages.txt');
    File mathRec = File('$masterDir/Temp/Math.txt');
    File persRec = File('$masterDir/Temp/Personal.txt');
    File progRec = File('$masterDir/Temp/Programming.txt');
    File projRec = File('$masterDir/Temp/Projects.txt');
    File sciRec = File('$masterDir/Temp/Scientific.txt');
    File whyJob = File('$masterDir/Temp/WhyJob.txt');
    File whyMe = File('$masterDir/Temp/WhyMe.txt');
    return Application._(
      newApp: newApp,
      name: name,
      jobUsed: jobUsed,
      profileUsed: profileUsed,
      coverLetterPDF: cPDF,
      coverLetterZip: cZip,
      portfolioPDF: pPDF,
      portfolioZip: pZip,
      resumePDF: rPDF,
      resumeZip: rZip,
      eduRecFile: eduRec,
      expRecFile: expRec,
      frameRecFile: frameRec,
      progLangRecFile: langRec,
      mathSkillsRecFile: mathRec,
      persSkillsRecFile: persRec,
      progSkillsRecFile: progRec,
      projRecFile: projRec,
      sciRecFile: sciRec,
      whyJobFile: whyJob,
      whyMeFile: whyMe,
    );
  }

  // Set Previous Content
  void SetJobProfile(Job job, Profile profile) async {
    jobUsed = job;
    profileUsed = profile;
    await CopyJobProfileContent('Temp');
  }

  // Copy Profile Content
  Future<void> CopyJobProfileContent(String grandDir) async {
    final masterDir = await getApplicationDocumentsDirectory();
    Directory grandParentDir = Directory('${masterDir.path}/$grandDir');
    if (!grandParentDir.existsSync()) {
      await grandParentDir.create();
    }
    Directory parentDir = Directory('${grandParentDir.path}/Job And Profile Content');
    if (!parentDir.existsSync()) {
      await parentDir.create();
    } else {
      await parentDir.delete(recursive: true);
      await parentDir.create();
    }
    Directory profDir = Directory('${masterDir.path}/Profiles/${profileUsed.name}');
    if (!profDir.existsSync()) {
      return;
    }
    Directory jobDir = Directory('${masterDir.path}/Jobs/${jobUsed.name}');
    if (!jobDir.existsSync()) {
      return;
    }
    Directory profDestDir = Directory('${parentDir.path}/${profileUsed.name}');
    if (!profDestDir.existsSync()) {
      await profDestDir.create();
    } else {
      await profDestDir.delete(recursive: true);
      await profDestDir.create();
    }
    Directory jobDestDir = Directory('${parentDir.path}/${jobUsed.name}');
    if (!jobDestDir.existsSync()) {
      await jobDestDir.create();
    } else {
      await jobDestDir.delete(recursive: true);
      await jobDestDir.create();
    }
    await CopyDir(profDir, profDestDir, false);
    await CopyDir(jobDir, jobDestDir, false);
  }

  // Set App Name
  void SetAppName(String appName) {
    name = appName;
  }
}

class OpenAI {
  static final String _apikey = dotenv.env['OPENAI_API_KEY'] ?? '';
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

  final callHeaders = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_apikey',
  };

  String get callBody {
    return jsonEncode({
      'model': openAIModel,
      'messages': [
        {'role': 'system', 'content': systemRole},
        {'role': 'user', 'content': userPrompt}
      ],
      'max_tokens': maxTokens,
    });
  }

  Future<Map<String, dynamic>> testRec() async {
    const url = 'https://api.openai.com/v1/chat/completions';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: callHeaders,
        body: callBody,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {
          'error': 'Error: ${response.statusCode}',
          'message': response.body,
        };
      }
    } catch (e) {
      throw Exception('Failed to generate response: $e');
    }
  }
}

// Future<Map<String, dynamic>> getRecs() async {
//   await prepRecPrompt();
//   const url = 'https://api.openai.com/v1/chat/completions';
//   final headers = {
//     'Content-Type': 'application/json',
//     'Authorization': 'Bearer $_apikey',
//   };
//   final body = jsonEncode({
//     'model': openAIModel,
//     'messages': [
//       {'role': 'system', 'content': _systemRole},
//       {'role': 'user', 'content': _userPrompt}
//     ],
//     'max_tokens': maxTokens,
//   });
//   try {
//     final response = await http.post(Uri.parse(url), headers: headers, body: body);
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       String responseText = data['choices'][0]['message']['content'].trim();
//       responseText = responseText.replaceAll('```json\n', '').replaceAll('```', '');
//       Map<String, dynamic> jsonResponse = jsonDecode(responseText);
//       return jsonResponse;
//     } else {
//       throw Exception('Failed to load data: ${response.statusCode} ${response.reasonPhrase}');
//     }
//   } catch (e) {
//     throw Exception('Failed to load data: $e');
//   }
// }

// Create New Application
// Future<void> CreateNewApplication() async {
//   await SetAppDir();
// }

// Set App Dir
// Future<void> SetAppDir() async {
//   final parentDir = await appsDir;
//   Directory appNameDir = Directory('${(await appsDir).path}/$name');
//   String recs = 'Recommendations';
//   String zips = 'Zip Files';
//   String docs = 'Finished Documents';
//   await CreateDir(parentDir, name);
//   await CreateDir(appNameDir, recs);
//   await CreateDir(appNameDir, zips);
//   await CreateDir(appNameDir, docs);
// }

// Load Previous Application
// Future<void> LoadAppData() async {
// final applicationsDir = await appsDir;
// final currApp = Directory('${applicationsDir.path}/$name');
// eduRecFile = File('${currApp.path}/Recommendations/EducationRec.txt');
// expRecFile = File('${currApp.path}/Recommendations/ExperienceRec.txt');
// projRecFile = File('${currApp.path}/Recommendations/ProjectsRec.txt');
// mathRecFile = File('${currApp.path}/Recommendations/MathSkillsRec.txt');
// persRecFile = File('${currApp.path}/Recommendations/PersSkillsRec.txt');
// framRecFile = File('${currApp.path}/Recommendations/FrameworkRec.txt');
// langRecFile = File('${currApp.path}/Recommendations/ProgLangRec.txt');
// progRecFile = File('${currApp.path}/Recommendations/ProgSkillsRec.txt');
// sciRecFile = File('${currApp.path}/Recommendations/ScientificSkillsRec.txt');
// if (eduRecFile.existsSync()) {
//   eduRecString = await eduRecFile.readAsString();
// }
// if (expRecFile.existsSync()) {
//   expRecString = await expRecFile.readAsString();
// }
// if (projRecFile.existsSync()) {
//   projRecString = await projRecFile.readAsString();
// }
// if (mathRecFile.existsSync()) {
//   mathRecString = await mathRecFile.readAsString();
// }
// if (persRecFile.existsSync()) {
//   persRecString = await persRecFile.readAsString();
// }
// if (framRecFile.existsSync()) {
//   framRecString = await framRecFile.readAsString();
// }
// if (langRecFile.existsSync()) {
//   langRecString = await langRecFile.readAsString();
// }
// if (progRecFile.existsSync()) {
//   progRecString = await progRecFile.readAsString();
// }
// if (sciRecFile.existsSync()) {
//   sciRecString = await sciRecFile.readAsString();
// }
// }

// Set Write Rec Files
// Future<void> setWriteRecFiles() async {
//   final dir = await appsDir;
//   final currDir = Directory('${dir.path}/$name');
//   eduRecFile = File('${currDir.path}/Recommendations/EducationRec.txt');
//   expRecFile = File('${currDir.path}/Recommendations/ExperienceRec.txt');
//   projRecFile = File('${currDir.path}/Recommendations/ProjectsRec.txt');
//   mathRecFile = File('${currDir.path}/Recommendations/MathSkillsRec.txt');
//   persRecFile = File('${currDir.path}/Recommendations/PersSkillsRec.txt');
//   framRecFile = File('${currDir.path}/Recommendations/FrameworkRec.txt');
//   langRecFile = File('${currDir.path}/Recommendations/ProgLangRec.txt');
//   progRecFile = File('${currDir.path}/Recommendations/ProgSkillsRec.txt');
//   sciRecFile = File('${currDir.path}/Recommendations/ScientificSkillsRec.txt');
//   WriteFile(dir, eduRecFile, eduRecCont.text);
//   WriteFile(dir, expRecFile, expRecCont.text);
//   WriteFile(dir, projRecFile, projRecCont.text);
//   WriteFile(dir, mathRecFile, mathRecCont.text);
//   WriteFile(dir, persRecFile, persRecCont.text);
//   WriteFile(dir, framRecFile, framRecCont.text);
//   WriteFile(dir, langRecFile, langRecCont.text);
//   WriteFile(dir, progRecFile, progRecCont.text);
//   WriteFile(dir, sciRecFile, sciRecCont.text);
// }

// Future<void> moveAndDelZip(String sourceSubDir, String targetSubDir, String zipName, bool deleteSrc) async {
//   final masterAppDir = await appDir;
//   Directory sourceDir = Directory('${masterAppDir.path}/$sourceSubDir');
//   Directory targetDir = Directory('${masterAppDir.path}/$targetSubDir');
//   final File sourceZip = File('${sourceDir.path}/$zipName');
//   await sourceZip.copy('${targetDir.path}/$zipName');
//   if (deleteSrc) {
//     await sourceZip.delete();
//   }
// }

// Future<void> unzipFile(String sourceSubDir, String targetSubDir, String zipName, bool deleteSrc) async {
//   final masterAppDir = await appDir;
//   Directory sourceDir = Directory('${masterAppDir.path}/$sourceSubDir/$zipName');
//   Directory targetDir = Directory('${masterAppDir.path}/$targetSubDir');
//   final bytes = File(sourceDir.path).readAsBytesSync();
//   final archive = ZipDecoder().decodeBytes(bytes);
//   for (final file in archive) {
//     final filename = p.join(targetDir.path, file.name);
//     if (file.isFile) {
//       final data = file.content as List<int>;
//       File(filename)
//         ..createSync(recursive: true)
//         ..writeAsBytesSync(data);
//     } else {
//       Directory(filename).createSync(recursive: true);
//     }
//   }
//   if (deleteSrc) {
//     final File oldZip = File(sourceDir.path);
//     await oldZip.delete();
//   }
// }

// Future<void> renameAndZipDir(String sourceSubDir, String newName, bool rename) async {
//   final masterAppDir = await appDir;
//   Directory originalDir = Directory('${masterAppDir.path}/$sourceSubDir/');
//   String finalDirPath = originalDir.path;
//   Directory dirToDelete = originalDir;
//   if (rename) {
//     var newPath = '${originalDir.parent.path}/$newName';
//     await originalDir.rename(newPath);
//     finalDirPath = newPath;
//     dirToDelete = Directory(newPath);
//   }
//   final zipFilePath = '${finalDirPath.trimRight()}.zip';
//   final zipFile = File(zipFilePath);
//   final archive = Archive();
//   List<FileSystemEntity> entities = Directory(finalDirPath).listSync(recursive: true);
//   for (FileSystemEntity entity in entities) {
//     if (entity is File) {
//       final filename = p.relative(entity.path, from: finalDirPath);
//       final data = entity.readAsBytesSync();
//       archive.addFile(ArchiveFile(filename, data.length, data));
//     }
//   }
//   final bytes = ZipEncoder().encode(archive);
//   if (bytes != null) {
//     zipFile.writeAsBytesSync(bytes);
//   }
//   await dirToDelete.delete(recursive: true);
// }

// Future<void> finDoc(String newDirName) async {
//   await moveAndDelZip('Temp', 'Applications/$name/Zip Files/', 'Return.zip', true);
//   await unzipFile('Applications/$name/Zip Files/', 'Applications/$name/Zip Files/', 'Return.zip', true);
//   await renameAndZipDir('Applications/$name/Zip Files/Return', newDirName, true);
//   await moveAndDelZip('Applications/$name/Zip Files/', 'Applications/$name/Finished Documents/', '$newDirName.zip', false);
//   await unzipFile('Applications/$name/Finished Documents/', 'Applications/$name/Finished Documents/$newDirName', '$newDirName.zip', true);
// }

// Future<String> retrievePDFDir(String subDir, String pdfFileName) async {
//   final masterAppsDir = await appsDir;
//   final pdfFilePath = '${masterAppsDir.path}/$name/Finished Documents/$subDir/$pdfFileName';
//   return pdfFilePath;
// }

// Future<List<File>> getJobFiles(String name) async {
//   List<File> files = [];
//   final jobsDir = await GetJobsDir();
//   final currJob = Directory('${jobsDir.path}/$name');
//   File desFile = File('${currJob.path}/$descriptionFile');
//   File othFile = File('${currJob.path}/$otherFile');
//   File qualFile = File('${currJob.path}/$qualificationsFile');
//   File roleFile = File('${currJob.path}/$roleInfoFile');
//   files.add(desFile);
//   files.add(othFile);
//   files.add(qualFile);
//   files.add(roleFile);
//   return files;
// }

// Future<List<String>> convertJobDescToString(List<File> files) async {
//   List<String> contents = [];
//   String description = await files[0].readAsString();
//   String other = await files[1].readAsString();
//   String qualifications = await files[2].readAsString();
//   String roleInfo = await files[3].readAsString();
//   contents.add(description);
//   contents.add(other);
//   contents.add(qualifications);
//   contents.add(roleInfo);
//   return contents;
// }

// Future<List<File>> getProfileFiles(String name) async {
//   List<File> files = [];
//   final profsDir = await GetProfilesDir();
//   final currProf = Directory('${profsDir.path}/$name');
//   File eduFile = File('${currProf.path}/$educationTextFile');
//   File expFile = File('${currProf.path}/$experienceTextFile');
//   File projFile = File('${currProf.path}/$projectsTextFile');
//   File skiFile = File('${currProf.path}/$skillsTextFile');
//   files.add(eduFile);
//   files.add(expFile);
//   files.add(projFile);
//   files.add(skiFile);
//   return files;
// }

// Future<List<String>> convertProfDescToString(List<File> files) async {
//   List<String> contents = [];
//   String education = await files[0].readAsString();
//   String experience = await files[1].readAsString();
//   String projects = await files[2].readAsString();
//   String skills = await files[3].readAsString();
//   contents.add(education);
//   contents.add(experience);
//   contents.add(projects);
//   contents.add(skills);
//   return contents;
// }

// Future<List<List<String>>> prepContent(List<String> names) async {
//   List<List<String>> content = [];
//   List<File> jobFiles = await getJobFiles(names[0]);
//   List<String> jobContent = await convertJobDescToString(jobFiles);
//   List<File> profFiles = await getProfileFiles(names[1]);
//   List<String> profContent = await convertProfDescToString(profFiles);
//   content.add(jobContent);
//   content.add(profContent);
//   return content;
// }

// String prepJobContent(String des, String other, String quals, String role) {
//   return jsonEncode({
//     "Job Description:": des,
//     "Other Information:": other,
//     "Qualifications Information:": quals,
//     "Role Information:": role,
//   });
// }

// String prepProfContent(String edu, String exp, String proj, String skills) {
//   return jsonEncode({
//     "Education:": edu,
//     "Experience:": exp,
//     "Projects:": proj,
//     "Skills:": skills,
//   });
// }

// Future<Map<String, dynamic>> getOpenAIRecs(BuildContext context, ApplicationContent content) async {
//   showLoadingDialog(context, 'Getting OpenAI Recommendations...');
//   try {
//     final openAICall = OpenAI(
//       content: content,
//       openAIModel: gpt_4o,
//       maxTokens: 1000,
//     );
//     Map<String, dynamic> result = await openAICall.getRecs();
//     Navigator.of(context).pop();
//     await showProducedDialog(context, 'Open AI Recommendations Produced!');
//     return result;
//   } catch (e) {
//     if (kDebugMode) {
//       print('Error: $e');
//     }
//     Navigator.of(context).pop();
//     rethrow;
//   }
// }

// List<Widget> openAIEntry(BuildContext context, String title, TextEditingController controller, String hintText, {int? lines = 10}) {
//   return [
//     Center(
//       child: Text(
//         title,
//         style: TextStyle(
//           color: themeTextColor(context),
//           fontSize: secondaryTitles,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     ),
//     SizedBox(height: standardSizedBoxHeight),
//     Center(
//       child: Container(
//         width: MediaQuery.of(context).size.width * jobContainerWidth,
//         child: TextField(
//           controller: controller,
//           keyboardType: TextInputType.multiline,
//           maxLines: lines,
//           decoration: InputDecoration(hintText: hintText.isEmpty ? null : hintText),
//         ),
//       ),
//     ),
//     SizedBox(height: 20),
//   ];
// }

// String escapeLatex(String input) {
//   return input.replaceAll('&', r'\&');
// }

// Future<void> getSkillsRecs(List<TextEditingController> controllers) async {
//   Directory appDir = await GetAppDir();
//   Directory temp = Directory('${appDir.path}/Temp');
//   if (temp.existsSync()) {
//     await temp.delete(recursive: true);
//   }
//   await temp.create();
//   File mathRecs = File('${temp.path}/Math.txt');
//   File persRecs = File('${temp.path}/Personal.txt');
//   File framRecs = File('${temp.path}/Frameworks.txt');
//   File langRecs = File('${temp.path}/Languages.txt');
//   File progRecs = File('${temp.path}/Programming.txt');
//   File sciRecs = File('${temp.path}/Scientific.txt');
//   WriteFile(temp, mathRecs, escapeLatex(controllers[3].text));
//   WriteFile(temp, persRecs, escapeLatex(controllers[4].text));
//   WriteFile(temp, framRecs, escapeLatex(controllers[5].text));
//   WriteFile(temp, langRecs, escapeLatex(controllers[6].text));
//   WriteFile(temp, progRecs, escapeLatex(controllers[7].text));
//   WriteFile(temp, sciRecs, escapeLatex(controllers[8].text));
// }

// Future<void> copyRecsToMainResumeLaTeX(List<TextEditingController> controllers) async {
//   Directory appDir = await GetAppDir();
//   Directory mainLaTeXDir = await GetLaTeXDir();
//   Directory tempDir = Directory('${appDir.path}/Temp/');
//   Directory resumeTxTDir = Directory('${mainLaTeXDir.path}/Main LaTeX/Resume/First Page/Qualifications/Txt/');
//   if (!(await tempDir.exists())) {
//     if (kDebugMode) {
//       print("Temp directory does not exist");
//     }
//     return;
//   }
//   if (!(await resumeTxTDir.exists())) {
//     await resumeTxTDir.create(recursive: true);
//   }
//   List<FileSystemEntity> tempEntities = tempDir.listSync();
//   for (FileSystemEntity entity in tempEntities) {
//     if (entity is File) {
//       String newPath = '${resumeTxTDir.path}/${entity.uri.pathSegments.last}';
//       File newFile = File(newPath);
//       await entity.copy(newFile.path);
//     }
//   }
// }

// Future<void> compilePortfolio(BuildContext context, List<TextEditingController> controllers) async {
//   showLoadingDialog(context, 'Compiling Portfolio');
//   await getSkillsRecs(controllers);
//   await copyRecsToMainResumeLaTeX(controllers);
//   Directory mainLaTeXDir = await GetLaTeXDir();
//   Directory resumeDir = Directory('${mainLaTeXDir.path}/Main LaTeX/Resume/');
//   File resumeZip = await zipResume(resumeDir);
//   try {
//     await uploadZipFile(resumeZip);
//     Navigator.of(context).pop();
//     await showProducedDialog(context, 'Portfolio Compiled Successfully.');
//   } catch (e) {
//     if (kDebugMode) {
//       print('Error: $e');
//     }
//   }
// }

// Future<void> uploadZipFile(File zipFile) async {
//   var request = http.MultipartRequest('POST', Uri.parse('http://82.180.161.189:3000/compile'));
//   request.files.add(await http.MultipartFile.fromPath('file', zipFile.path));
//   var response = await request.send();
//   if (response.statusCode == 200) {
//     var responseBody = await response.stream.toBytes();
//     Directory appDir = await GetAppDir();
//     String filePath = p.join("${appDir.path}/Temp", 'Return.zip');
//     File file = File(filePath);
//     await file.writeAsBytes(responseBody);
//   }
//   zipFile.deleteSync();
// }

// Future<File> zipResume(Directory masterDir) async {
//   Directory appDocDir = await GetAppDir();
//   Directory tempDir = Directory('${appDocDir.path}/Temp');
//   String zipFilePath = '${tempDir.path}/Resume.zip';
//   var encoder = ZipFileEncoder();
//   encoder.create(zipFilePath);
//   encoder.addDirectory(masterDir, includeDirName: false);
//   encoder.close();
//   cleanTempResume();
//   return File(zipFilePath);
// }

// Future<void> cleanTempResume() async {
//   Directory appDocDir = await GetAppDir();
//   Directory tempDir = Directory('${appDocDir.path}/Temp');
//   List<FileSystemEntity> tempEntities = tempDir.listSync();
//   for (FileSystemEntity entity in tempEntities) {
//     if (entity is File) {
//       if (p.extension(entity.path) == '.txt') {
//         entity.deleteSync();
//       }
//     }
//   }
// }

// Future<void> CreateNewApplication(ApplicationContent content, List<TextEditingController> controllers) async {
//   Application newApp = Application(
//     name: content.checkedJobs[0].toString(),
//     profileName: content.checkedProfiles[0].toString(),
//     controllers: controllers,
//   );
//   Directory appsDir = await GetApplicationsDir();
//   Directory newDir = Directory('${appsDir.path}/${newApp.name}');
//   if (newDir.existsSync()) {
//     newDir.deleteSync(recursive: true);
//   }
//   newApp.CreateNewApplication();
// }

// void showLoadingDialog(BuildContext context, String content) {
//   showDialog(
//     context: context,
//     barrierDismissible: false,
//     builder: (BuildContext context) {
//       return Dialog(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(content),
//               SizedBox(width: standardSizedBoxHeight),
//               CircularProgressIndicator(),
//             ],
//           ),
//         ),
//       );
//     },
//   );
// }

// Future<void> showProducedDialog(BuildContext context, String content) async {
//   Timer? timer;
//   await showDialog(
//     context: context,
//     barrierDismissible: true,
//     builder: (BuildContext context) {
//       timer = Timer(Duration(seconds: 2), () {
//         Navigator.of(context).pop();
//       });
//       return Dialog(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [SizedBox(width: 16), Text(content)],
//           ),
//         ),
//       );
//     },
//   );
//   timer?.cancel();
// }
