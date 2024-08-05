import 'dart:async';
import 'dart:convert';
import 'dart:io';
// import 'package:flutter/gestures.dart';
// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../Context/Globals/GlobalContext.dart';
import '../Globals/ApplicationsGlobals.dart';
import '../Globals/JobsGlobals.dart';
import '../Globals/ProfilesGlobals.dart';
// import '../Globals/ApplicationsGlobals.dart';
// import 'package:archive/archive_io.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:path/path.dart' as p;
// import '../Globals/Globals.dart';
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
  late File aboutMeFile;
  late File eduRecFile;
  late File expRecFile;
  late File frameRecFile;
  late File mathSkillsRecFile;
  late File openAIRecFile;
  late File persSkillsRecFile;
  late File progLangRecFile;
  late File progSkillsRecFile;
  late File projRecFile;
  late File sciRecFile;
  late File whyJobFile;
  late File whyMeFile;

  // Mater Recommendations
  late Map<String, dynamic> masterRecs;
  late List<String> recommendations;

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
    required this.aboutMeFile,
    required this.eduRecFile,
    required this.expRecFile,
    required this.frameRecFile,
    required this.masterRecs,
    required this.mathSkillsRecFile,
    required this.openAIRecFile,
    required this.persSkillsRecFile,
    required this.progLangRecFile,
    required this.progSkillsRecFile,
    required this.projRecFile,
    required this.recommendations,
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
    File aboutMe = File('$masterDir/Temp/Open AI Recommendations/About.txt');
    File eduRec = File('$masterDir/Temp/Open AI Recommendations/Education.txt');
    File expRec = File('$masterDir/Temp/Open AI Recommendations/Experience.txt');
    File frameRec = File('$masterDir/Temp/Open AI Recommendations/Frameworks.txt');
    File langRec = File('$masterDir/Temp/Open AI Recommendations/Languages.txt');
    File mathRec = File('$masterDir/Temp/Open AI Recommendations/Math.txt');
    File openAIRec = File('$masterDir/Temp/Open AI Recommendations/OpenAIRecs.json');
    File persRec = File('$masterDir/Temp/Open AI Recommendations/Personal.txt');
    File progRec = File('$masterDir/Temp/Open AI Recommendations/Programming.txt');
    File projRec = File('$masterDir/Temp/Open AI Recommendations/Projects.txt');
    File sciRec = File('$masterDir/Temp/Open AI Recommendations/Scientific.txt');
    File whyJob = File('$masterDir/Temp/Open AI Recommendations/WhyJob.txt');
    File whyMe = File('$masterDir/Temp/Open AI Recommendations/WhyMe.txt');
    // Recommendations
    List<String> recs = [];
    Map<String, dynamic> masterRecs = {};
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
      aboutMeFile: aboutMe,
      eduRecFile: eduRec,
      expRecFile: expRec,
      frameRecFile: frameRec,
      masterRecs: masterRecs,
      mathSkillsRecFile: mathRec,
      openAIRecFile: openAIRec,
      persSkillsRecFile: persRec,
      progLangRecFile: langRec,
      progSkillsRecFile: progRec,
      projRecFile: projRec,
      recommendations: recs,
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

  // Convert Job Content To String
  Future<String> ConvertJobCont() async {
    String ret = '';
    final appDir = await getApplicationDocumentsDirectory();
    Directory tempDir = Directory('${appDir.path}/Temp/Job And Profile Content/${jobUsed.name}');
    File jobContFile = File('${tempDir.path}/$finalJobTextFile');
    ret = await jobContFile.readAsString();
    return ret;
  }

  // Convert Profile Content To String
  Future<String> ConvertProfCont() async {
    String ret = '';
    final appDir = await getApplicationDocumentsDirectory();
    Directory tempDir = Directory('${appDir.path}/Temp/Job And Profile Content/${profileUsed.name}');
    File profContFile = File('${tempDir.path}/$finalProfileTextFile');
    ret = await profContFile.readAsString();
    return ret;
  }

  // Set Recommendations
  Future<void> SetRecs(Map<String, dynamic> recs, List<String> listRecs) async {
    recommendations = listRecs;
    masterRecs = recs;
    // Master directories
    final appDir = await getApplicationDocumentsDirectory();
    Directory tempDir = Directory('${appDir.path}/Temp');
    Directory recsDir = Directory('${tempDir.path}/Open AI Recommendations');
    // Create recs dir if needed
    if (recsDir.existsSync()) {
      await recsDir.delete(recursive: true);
    }
    await recsDir.create();
    // Master JSON file
    File jsonRecFile = File('${recsDir.path}/$openAIRecsJSONFile');
    if (jsonRecFile.existsSync()) {
      await jsonRecFile.delete();
    }
    String jsonString = jsonEncode(recs);
    await WriteFile(recsDir, jsonRecFile, jsonString);
    openAIRecFile = jsonRecFile;
    // Cover Letter About Me File
    File covAboutFile = File('${recsDir.path}/$openAICAboutMeTxtFile');
    if (covAboutFile.existsSync()) {
      await covAboutFile.delete();
    }
    await WriteFile(recsDir, covAboutFile, recommendations[0]);
    aboutMeFile = covAboutFile;
    // Cover Letter Why Job File
    File covWhyJobFile = File('${recsDir.path}/$openAICLWJRecsTxtFile');
    if (covWhyJobFile.existsSync()) {
      await covWhyJobFile.delete();
    }
    await WriteFile(recsDir, covWhyJobFile, recommendations[1]);
    whyJobFile = covWhyJobFile;
    // Cover Letter Why Me File
    File covWhyMeFile = File('${recsDir.path}/$openAICLWMRecsTxtFile');
    if (covWhyMeFile.existsSync()) {
      await covWhyMeFile.delete();
    }
    await WriteFile(recsDir, covWhyMeFile, recommendations[2]);
    whyMeFile = covWhyMeFile;
    // Education Rec File
    File eduFile = File('${recsDir.path}/$openAIEduRecsTxtFile');
    if (eduFile.existsSync()) {
      await eduFile.delete();
    }
    await WriteFile(recsDir, eduFile, recommendations[3]);
    eduRecFile = eduFile;
    // Experience Rec File
    File expFile = File('${recsDir.path}/$openAIExpRecsTxtFile');
    if (expFile.existsSync()) {
      await expFile.delete();
    }
    await WriteFile(recsDir, expFile, recommendations[4]);
    expRecFile = expFile;
    // Frameworks Rec file
    File framFile = File('${recsDir.path}/$openAIFramRecsTxtFile');
    if (framFile.existsSync()) {
      await framFile.delete();
    }
    await WriteFile(recsDir, framFile, recommendations[5]);
    frameRecFile = framFile;
    // Math Rec File
    File mathFile = File('${recsDir.path}/$openAIMathRecsTxtFile');
    if (mathFile.existsSync()) {
      await mathFile.delete();
    }
    await WriteFile(recsDir, mathFile, recommendations[6]);
    mathSkillsRecFile = mathFile;
    // Personal Rec File
    File persFile = File('${recsDir.path}/$openAIPersRecsTxtFile');
    if (persFile.existsSync()) {
      await persFile.delete();
    }
    await WriteFile(recsDir, persFile, recommendations[7]);
    persSkillsRecFile = persFile;
    // Programming Lang Rec File
    File progLangFile = File('${recsDir.path}/$openAIPLRecsTxtFile');
    if (progLangFile.existsSync()) {
      await progLangFile.delete();
    }
    await WriteFile(recsDir, progLangFile, recommendations[8]);
    progLangRecFile = progLangFile;
    // Programming Skills Rec File
    File progSkillsFile = File('${recsDir.path}/$openAIPSRecsTxtFile');
    if (progSkillsFile.existsSync()) {
      await progSkillsFile.delete();
    }
    await WriteFile(recsDir, progSkillsFile, recommendations[9]);
    // Projects Rec File
    File projFile = File('${recsDir.path}/$openAIProjRecsTxtFile');
    if (projFile.existsSync()) {
      await projFile.delete();
    }
    await WriteFile(recsDir, projFile, recommendations[10]);
    projRecFile = projFile;
    // Scientific Rec File
    File sciFile = File('${recsDir.path}/$openAISciRecsTxtFile');
    if (sciFile.existsSync()) {
      await sciFile.delete();
    }
    await WriteFile(recsDir, sciFile, recommendations[11]);
    sciRecFile = sciFile;
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

  Future<Map<String, dynamic>> portfolioRec() async {
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

Future<String> OpenAIPrompt(Application app) async {
  String ret = '';
  String jobCont = await app.ConvertJobCont();
  String profCont = await app.ConvertProfCont();
  ret = jobContentPrompt + jobCont + profContentPrompt + profCont + returnPrompt;
  return ret;
}

Future<Map<String, dynamic>> GetOpenAIRecs(BuildContext context, Application app, String openAIModel) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return ShowLoadingDialog(context, 'Producing OpenAI Recommendations');
    },
  );
  bool successful = false;
  Map<String, dynamic> ret = {};
  String userPrompt = await OpenAIPrompt(app);
  OpenAI testCall = OpenAI(
    openAIModel: openAIModel,
    systemRole: hiringManagerRole,
    userPrompt: userPrompt,
    maxTokens: 4000,
  );
  try {
    Map<String, dynamic> finalResponse = await testCall.portfolioRec();
    if (finalResponse.containsKey('error')) {
      return ret;
    } else {
      List<dynamic> choices = finalResponse['choices'];
      if (choices.isNotEmpty) {
        String content = choices[0]['message']['content'];
        content = content.replaceAll('```json', '').replaceAll('```', '').trim();
        ret = jsonDecode(content);
        successful = true;
        return ret;
      } else {
        return ret;
      }
    }
  } catch (e) {
    return ret;
  } finally {
    Navigator.of(context).pop();
    if (successful) {
      await ShowProducedDialog(context, 'Recommendations Successfully Produced', 'Proceed With Compiling Portfolio', Icons.done);
    } else {
      GenAlertDialogWithIcon('Failure In Producing Recommendations', 'An Error Occurred, Please Try Again', Icons.sms_failed);
    }
  }
}

Future<String> ConvertIndRecs(Map<String, dynamic> map, String section) async {
  String ret = '';
  for (int i = 0; i < map[section].length; i++) {
    if (i < map[section].length - 1) {
      if ((section == covLetWhyJobPrompt) || (section == covLetWhyMePrompt)) {
        ret += map[section][i] + '\n';
      } else {
        ret += map[section][i] + ', ';
      }
    } else {
      ret += map[section][i];
    }
  }
  return ret;
}

Future<List<String>> StringifyRecs(Map<String, dynamic> openAIRecs, Application app) async {
  List<String> recs = [];
  recs.add(app.profileUsed.coverLetterContList[0].about.text);
  recs.add(await ConvertIndRecs(openAIRecs, covLetWhyJobPrompt));
  recs.add(await ConvertIndRecs(openAIRecs, covLetWhyMePrompt));
  recs.add(await ConvertIndRecs(openAIRecs, eduRecPrompt));
  recs.add(await ConvertIndRecs(openAIRecs, expRecPrompt));
  recs.add(await ConvertIndRecs(openAIRecs, framRecPrompt));
  recs.add(await ConvertIndRecs(openAIRecs, mathSkillPrompt));
  recs.add(await ConvertIndRecs(openAIRecs, persSkillPrompt));
  recs.add(await ConvertIndRecs(openAIRecs, progLangPrompt));
  recs.add(await ConvertIndRecs(openAIRecs, progSkillPrompt));
  recs.add(await ConvertIndRecs(openAIRecs, projPrompt));
  recs.add(await ConvertIndRecs(openAIRecs, sciSkillPrompt));
  return recs;
}

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
