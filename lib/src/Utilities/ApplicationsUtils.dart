import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
import '../Applications/Applications.dart';
import '../Context/Applications/ViewApplicationContext.dart';
import '../Context/Globals/GlobalContext.dart';
import '../Globals/ApplicationsGlobals.dart';
import '../Globals/JobsGlobals.dart';
import '../Globals/ProfilesGlobals.dart';
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
  late bool applied;
  late bool interview;
  late bool offer;

  // Content
  late String name;
  late Job jobUsed;
  late Profile profileUsed;

  // Master Files
  late File coverLetterPDF;
  late File jobContFile;
  late File portfolioPDF;
  late File profileContFile;
  late File resumePDF;

  // Recommendations Files
  late File aboutMeFile;
  late File companyFile;
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

  // Application Information
  String appURL = '';
  DateTime? appDate;

  // Recommendation Controllers
  TextEditingController aboutMeCont = TextEditingController();
  TextEditingController eduRecCont = TextEditingController();
  TextEditingController expRecCont = TextEditingController();
  TextEditingController framRecCont = TextEditingController();
  TextEditingController mathSkillsRecCont = TextEditingController();
  TextEditingController persSkillsRecCont = TextEditingController();
  TextEditingController progLangRecCont = TextEditingController();
  TextEditingController progSkillsRecCont = TextEditingController();
  TextEditingController projRecCont = TextEditingController();
  TextEditingController sciRecCont = TextEditingController();
  TextEditingController whyJobCont = TextEditingController();
  TextEditingController whyMeCont = TextEditingController();

  // Master Recommendations
  late Map<String, dynamic> masterRecs;
  late List<String> recommendations;

  // OpenAI Specific
  String openAIModel = gpt_4o;

  // Constructor
  Application._({
    required this.newApp,
    required this.name,
    required this.jobUsed,
    required this.profileUsed,
    required this.coverLetterPDF,
    required this.portfolioPDF,
    required this.resumePDF,
    required this.aboutMeFile,
    required this.companyFile,
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
    required this.appURL,
    required this.applied,
    required this.interview,
    required this.offer,
    required this.appDate,
  });

  // Init
  static Future<Application> Init({String name = '', required bool newApp}) async {
    // Directories etc.
    final masterDir = await GetAppDir();
    Directory appsDir = Directory('${masterDir.path}/Applications');
    Directory currDir = Directory('${appsDir.path}/$name');
    Future<Job> futureJob = Job.Init(newJob: false);
    Future<Profile> futureProfile = Profile.Init(newProfile: false);
    Job jobUsed = await futureJob;
    Profile profileUsed = await futureProfile;
    // Sub Directory
    String pdfDir = '';
    if (!newApp) {
      pdfDir = '${currDir.path}/PDFs';
    } else {
      pdfDir = '${masterDir.path}/Temp';
    }
    // Main Files
    File cPDF = File('$pdfDir/CoverLetter.pdf');
    File pPDF = File('$pdfDir/Portfolio.pdf');
    File rPDF = File('$pdfDir/Resume.pdf');
    // Recommendation Files
    String recDir = '';
    if (!newApp) {
      recDir = '${currDir.path}/Open AI Recommendations';
    } else {
      recDir = '${masterDir.path}/Temp/Open AI Recommendations';
    }
    File aboutMe = File('$recDir/About.txt');
    File company = File('$recDir/Company.txt');
    File eduRec = File('$recDir/Education.txt');
    File expRec = File('$recDir/Experience.txt');
    File frameRec = File('$recDir/Frameworks.txt');
    File langRec = File('$recDir/Languages.txt');
    File mathRec = File('$recDir/Math.txt');
    File openAIRec = File('$recDir/OpenAIRecs.json');
    File persRec = File('$recDir/Personal.txt');
    File progRec = File('$recDir/Programming.txt');
    File projRec = File('$recDir/Projects.txt');
    File sciRec = File('$recDir/Scientific.txt');
    File whyJob = File('$recDir/WhyJob.txt');
    File whyMe = File('$recDir/WhyMe.txt');
    // Additional Information
    String appURL = await GetURL(name);
    bool applied = await GetApplied(name);
    bool interview = await GetInterview(name);
    bool offer = await GetOffer(name);
    DateTime? appDate = await GetDate(name);
    // Recommendations
    List<String> recs = [];
    Map<String, dynamic> masterRecs = {};
    return Application._(
      newApp: newApp,
      name: name,
      jobUsed: jobUsed,
      profileUsed: profileUsed,
      coverLetterPDF: cPDF,
      portfolioPDF: pPDF,
      resumePDF: rPDF,
      aboutMeFile: aboutMe,
      companyFile: company,
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
      appURL: appURL,
      applied: applied,
      interview: interview,
      offer: offer,
      appDate: appDate,
    );
  }

  Future<void> CreateApplication(BuildContext context, String appName) async {
    // Set Name And Files
    SetAppName(appName);
    await SetFinalFiles();
    await CompileDocuments(context);
    Navigator.pushAndRemoveUntil(context, LeftToRightPageRoute(page: ApplicationsPage()), (Route<dynamic> route) => false);
    // Directories
    final appDir = await GetAppDir();
    Directory tempDir = Directory('${appDir.path}/Temp');
    Directory appsDir = Directory('${appDir.path}/Applications');
    Directory newDir = Directory('${appsDir.path}/$name');
    // Create New Directory
    if (newDir.existsSync()) {
      await newDir.delete(recursive: true);
    }
    await newDir.create();
    // Copy Temp Directory Contents
    await CopyDir(tempDir, newDir, false);
    await CleanDir('Temp');
    await ShowProducedDialog(context, 'Application $name Created', 'Application $name Created Successfully', Icons.check);
  }

  Future<void> LoadApplication() async {
    final appDir = await GetAppDir();
    Directory appsDir = Directory('${appDir.path}/Applications');
    Directory jobsDir = Directory('${appDir.path}/Jobs');
    Directory profsDir = Directory('${appDir.path}/Profiles');
    Directory currDir = Directory('${appsDir.path}/$name');
    Directory jobProfDir = Directory('${currDir.path}/Job And Profile Content');
    String job = '';
    String profile = '';
    List<String> appContNames = [];
    if (jobProfDir.existsSync()) {
      List<FileSystemEntity> entities = jobProfDir.listSync();
      for (var entity in entities) {
        if (entity is Directory) {
          String directoryName = entity.path.split('/').last;
          appContNames.add(directoryName);
        }
      }
    }
    List<String> jobsNames = [];
    jobsDir.listSync().forEach((entity) {
      if (entity is Directory) {
        String directoryName = entity.path.split('/').last;
        jobsNames.add(directoryName);
      }
    });
    List<String> profsNames = [];
    profsDir.listSync().forEach((entity) {
      if (entity is Directory) {
        String directoryName = entity.path.split('/').last;
        profsNames.add(directoryName);
      }
    });
    for (int i = 0; i < appContNames.length; i++) {
      for (int j = 0; j < jobsNames.length; j++) {
        if (jobsNames[j] == appContNames[i]) {
          job = appContNames[i];
          break;
        }
      }
      for (int j = 0; j < profsNames.length; j++) {
        if (profsNames[j] == appContNames[i]) {
          profile = appContNames[i];
          break;
        }
      }
    }
    Job jobUsed = await Job.Init(name: job, newJob: false);
    Profile profUsed = await Profile.Init(name: profile, newProfile: false);
    SetJobProfile(jobUsed, profUsed, false);
    await SetCLPDF();
    await SetPortPDF();
    await SetResPDF();
    await GetRecs();
  }

  // Set Previous Content
  void SetJobProfile(Job job, Profile profile, bool copy) async {
    jobUsed = job;
    profileUsed = profile;
    if (copy) {
      await CopyJobProfileContent('Temp');
    }
  }

  // Copy Profile Content
  Future<void> CopyJobProfileContent(String grandDir) async {
    final masterDir = await GetAppDir();
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
    final appDir = await GetAppDir();
    Directory tempDir = Directory('${appDir.path}/Temp/Job And Profile Content/${jobUsed.name}');
    File jobContFile = File('${tempDir.path}/$finalJobTextFile');
    ret = await jobContFile.readAsString();
    return ret;
  }

  // Convert Profile Content To String
  Future<String> ConvertProfCont() async {
    String ret = '';
    final appDir = await GetAppDir();
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
    final appDir = await GetAppDir();
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

  // Get Recs
  Future<void> GetRecs() async {
    final appDir = await GetAppDir();
    Directory appsDir = Directory('${appDir.path}/Applications');
    Directory currDir = Directory('${appsDir.path}/$name');
    Directory recsDir = Directory('${currDir.path}/Open AI Recommendations');
    aboutMeFile = File('${recsDir.path}/$openAICAboutMeTxtFile');
    whyJobFile = File('${recsDir.path}/$openAICLWJRecsTxtFile');
    whyMeFile = File('${recsDir.path}/$openAICLWMRecsTxtFile');
    eduRecFile = File('${recsDir.path}/$openAIEduRecsTxtFile');
    expRecFile = File('${recsDir.path}/$openAIExpRecsTxtFile');
    frameRecFile = File('${recsDir.path}/$openAIFramRecsTxtFile');
    mathSkillsRecFile = File('${recsDir.path}/$openAIMathRecsTxtFile');
    persSkillsRecFile = File('${recsDir.path}/$openAIPersRecsTxtFile');
    progLangRecFile = File('${recsDir.path}/$openAIPLRecsTxtFile');
    progSkillsRecFile = File('${recsDir.path}/$openAIPSRecsTxtFile');
    projRecFile = File('${recsDir.path}/$openAIProjRecsTxtFile');
    sciRecFile = File('${recsDir.path}/$openAISciRecsTxtFile');
    openAIRecFile = File('${recsDir.path}/$openAIRecsJSONFile');
  }

  // Set Final Files
  Future<void> SetFinalFiles() async {
    // Master Directories
    final appDir = await GetAppDir();
    Directory tempDir = Directory('${appDir.path}/Temp');
    Directory finFiles = Directory('${tempDir.path}/Final Text Files');
    if (finFiles.existsSync()) {
      await finFiles.delete(recursive: true);
    }
    await finFiles.create();
    // About File
    File aboutFile = File('${finFiles.path}/$finCLAboutFile');
    if (aboutFile.existsSync()) {
      await aboutFile.delete();
    }
    await WriteFile(finFiles, aboutFile, EscapeLatex(aboutMeCont.text));
    aboutMeFile = aboutFile;
    // Company File
    File compFile = File('${finFiles.path}/$finCLCompFile');
    if (compFile.existsSync()) {
      await compFile.delete();
    }
    await WriteFile(finFiles, compFile, EscapeLatex(jobUsed.name));
    companyFile = compFile;
    // Job File
    File jobFile = File('${finFiles.path}/$finCLJobFile');
    if (jobFile.existsSync()) {
      await jobFile.delete();
    }
    await WriteFile(finFiles, jobFile, EscapeLatex(whyJobCont.text));
    whyJobFile = jobFile;
    // Why Me File
    File meFile = File('${finFiles.path}/$finCLMeFile');
    if (meFile.existsSync()) {
      await meFile.exists();
    }
    await WriteFile(finFiles, meFile, EscapeLatex(whyMeCont.text));
    whyMeFile = meFile;
    // Edu Rec File
    File eduFile = File('${finFiles.path}/$finEduRecFile');
    if (eduFile.existsSync()) {
      await eduFile.exists();
    }
    await WriteFile(finFiles, eduFile, EscapeLatex(eduRecCont.text));
    eduRecFile = eduFile;
    // Exp Rec File
    File expFile = File('${finFiles.path}/$finExpRecFile');
    if (expFile.existsSync()) {
      await expFile.delete();
    }
    await WriteFile(finFiles, expFile, EscapeLatex(expRecCont.text));
    expRecFile = expFile;
    // Fram Rec File
    File framFile = File('${finFiles.path}/$finFramFile');
    if (framFile.existsSync()) {
      await framFile.delete();
    }
    await WriteFile(finFiles, framFile, EscapeLatex(framRecCont.text));
    frameRecFile = framFile;
    // Math Rec File
    File mathFile = File('${finFiles.path}/$finMathRecFile');
    if (mathFile.existsSync()) {
      await mathFile.delete();
    }
    await WriteFile(finFiles, mathFile, EscapeLatex(mathSkillsRecCont.text));
    mathSkillsRecFile = mathFile;
    // Pers Rec File
    File persFile = File('${finFiles.path}/$finPersRecFile');
    if (persFile.existsSync()) {
      await persFile.delete();
    }
    await WriteFile(finFiles, persFile, EscapeLatex(persSkillsRecCont.text));
    persSkillsRecFile = persFile;
    // Prog Lang File
    File langFile = File('${finFiles.path}/$finLangFile');
    if (langFile.existsSync()) {
      await langFile.delete();
    }
    await WriteFile(finFiles, langFile, EscapeLatex(progLangRecCont.text));
    progLangRecFile = langFile;
    // Prog Skills File
    File progFile = File('${finFiles.path}/$finProgRecFile');
    if (progFile.existsSync()) {
      await progFile.delete();
    }
    await WriteFile(finFiles, progFile, EscapeLatex(progSkillsRecCont.text));
    progSkillsRecFile = progFile;
    // Proj File
    File projFile = File('${finFiles.path}/$finProjRecFile');
    if (projFile.existsSync()) {
      await projFile.delete();
    }
    await WriteFile(finFiles, projFile, EscapeLatex(projRecCont.text));
    projRecFile = projFile;
    // Sci File
    File sciFile = File('${finFiles.path}/$finSciRecFile');
    if (sciFile.existsSync()) {
      await sciFile.delete();
    }
    await WriteFile(finFiles, sciFile, EscapeLatex(sciRecCont.text));
    sciRecFile = sciFile;
    // Setup LaTeX
    await InitializeLaTeX();
    await PrepLaTeXDirs();
  }

  // Set App Name
  void SetAppName(String appName) {
    name = appName;
  }

  // Set Cover Letter PDF
  Future<void> SetCLPDF() async {
    final appDir = await GetAppDir();
    Directory appsDir = Directory('${appDir.path}/Applications');
    Directory currDir = Directory('${appsDir.path}/$name');
    Directory pdfDir = Directory('${currDir.path}/PDFs');
    File pdfFile = File('${pdfDir.path}/Cover Letter.pdf');
    coverLetterPDF = pdfFile;
  }

  Future<void> SetPortPDF() async {
    final appDir = await GetAppDir();
    Directory appsDir = Directory('${appDir.path}/Applications');
    Directory currDir = Directory('${appsDir.path}/$name');
    Directory pdfDir = Directory('${currDir.path}/PDFs');
    File pdfFile = File('${pdfDir.path}/Portfolio.pdf');
    portfolioPDF = pdfFile;
  }

  Future<void> SetResPDF() async {
    final appDir = await GetAppDir();
    Directory appsDir = Directory('${appDir.path}/Applications');
    Directory currDir = Directory('${appsDir.path}/$name');
    Directory pdfDir = Directory('${currDir.path}/PDFs');
    File pdfFile = File('${pdfDir.path}/Resume.pdf');
    resumePDF = pdfFile;
  }

  Future<void> SetURL(String url) async {
    final appDir = await GetAppDir();
    Directory appsDir = Directory('${appDir.path}/Applications');
    Directory currDir = Directory('${appsDir.path}/$name');
    Directory addDir = Directory('${currDir.path}/Additional');
    if (!addDir.existsSync()) {
      await addDir.create();
    }
    File file = File('${addDir.path}/URL.txt');
    appURL = url;
    await WriteFile(addDir, file, url);
  }

  static Future<String> GetURL(String name) async {
    String ret = '';
    final appDir = await GetAppDir();
    Directory appsDir = Directory('${appDir.path}/Applications');
    Directory currDir = Directory('${appsDir.path}/$name');
    Directory addDir = Directory('${currDir.path}/Additional');
    if (!addDir.existsSync()) {
      await addDir.create();
    }
    File file = File('${addDir.path}/Summary.json');
    if (file.existsSync()) {
      String jsonString = await file.readAsString();
      Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      ret = jsonMap['App-URL'] ?? '';
    }
    return ret;
  }

  static Future<bool> GetApplied(String name) async {
    final appDir = await GetAppDir();
    Directory appsDir = Directory('${appDir.path}/Applications');
    Directory currDir = Directory('${appsDir.path}/$name');
    Directory addDir = Directory('${currDir.path}/Additional');
    if (!addDir.existsSync()) {
      await addDir.create();
    }
    File file = File('${addDir.path}/Summary.json');
    if (file.existsSync()) {
      String jsonString = await file.readAsString();
      Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      bool ret = jsonMap['App-Applied'] ?? false;
      return ret;
    }
    return false;
  }

  void SetApplied(bool val) {
    applied = val;
  }

  static Future<bool> GetInterview(String name) async {
    final appDir = await GetAppDir();
    Directory appsDir = Directory('${appDir.path}/Applications');
    Directory currDir = Directory('${appsDir.path}/$name');
    Directory addDir = Directory('${currDir.path}/Additional');
    if (!addDir.existsSync()) {
      await addDir.create();
    }
    File file = File('${addDir.path}/Summary.json');
    if (file.existsSync()) {
      String jsonString = await file.readAsString();
      Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      bool ret = jsonMap['App-Interview'] ?? false;
      return ret;
    }
    return false;
  }

  void SetInterview(bool val) {
    interview = val;
  }

  static Future<bool> GetOffer(String name) async {
    final appDir = await GetAppDir();
    Directory appsDir = Directory('${appDir.path}/Applications');
    Directory currDir = Directory('${appsDir.path}/$name');
    Directory addDir = Directory('${currDir.path}/Additional');
    if (!addDir.existsSync()) {
      await addDir.create();
    }
    File file = File('${addDir.path}/Summary.json');
    if (file.existsSync()) {
      String jsonString = await file.readAsString();
      Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      bool ret = jsonMap['App-Offer'] ?? false;
      return ret;
    }
    return false;
  }

  void SetOffer(bool val) {
    offer = val;
  }

  static Future<DateTime?> GetDate(String name) async {
    final appDir = await GetAppDir();
    Directory appsDir = Directory('${appDir.path}/Applications');
    Directory currDir = Directory('${appsDir.path}/$name');
    Directory addDir = Directory('${currDir.path}/Additional');
    if (!addDir.existsSync()) {
      await addDir.create();
    }
    File file = File('${addDir.path}/Summary.json');
    if (file.existsSync()) {
      String jsonString = await file.readAsString();
      Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      DateTime? ret = jsonMap['App-Date'] != null ? DateTime.parse(jsonMap['App-Date']) : null;
      return ret;
    }
    return DateTime.now();
  }

  void SetDate(DateTime? date) {
    appDate = date;
  }

  Future<void> SetAdditional() async {
    final appDir = await GetAppDir();
    Directory appsDir = Directory('${appDir.path}/Applications');
    Directory currDir = Directory('${appsDir.path}/$name');
    Directory addDir = Directory('${currDir.path}/Additional');
    if (!addDir.existsSync()) {
      await addDir.create();
    }
    File file = File('${addDir.path}/Summary.json');
    Map<String, dynamic> summary = {
      'App-URL': appURL,
      'App-Applied': applied,
      'App-Interview': interview,
      'App-Offer': offer,
      'App-Date': appDate?.toIso8601String(),
    };
    String jsonString = jsonEncode(summary);
    await file.writeAsString(jsonString);
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
    barrierDismissible: false,
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
        content = content.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
        content = content.replaceAll('â', '');
        content = content.replaceAll('', '');
        try {
          ret = jsonDecode(content);
          successful = true;
        } catch (e) {
          print('JSON decoding error: $e');
        }
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
  var sectionContent = map[section];
  if (sectionContent != null && sectionContent.length != null) {
    for (int i = 0; i < sectionContent.length; i++) {
      if (i < sectionContent.length - 1) {
        if ((section == covLetWhyJobPrompt) || (section == covLetWhyMePrompt)) {
          ret += sectionContent[i] + '\n';
        } else {
          ret += sectionContent[i] + ', ';
        }
      } else {
        ret += sectionContent[i];
      }
    }
  }
  return ret;
}

Future<List<String>> StringifyRecs(Map<String, dynamic> openAIRecs, Application app) async {
  List<String> recs = [];
  if (app.profileUsed.coverLetterContList.isNotEmpty) {
    recs.add(app.profileUsed.coverLetterContList[0].about.text);
  } else {
    recs.add('');
  }
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

String EscapeLatex(String input) {
  input = input.replaceAll('&', r'\&');
  input = input.replaceAll('#', r'\#');
  input = input.replaceAll('%', r'\%');
  return input;
}

Future<void> InitializeLaTeX() async {
  // Master Directories
  final appDir = await GetAppDir();
  final latexDir = await GetLaTeXDir();
  Directory mainLatexDir = Directory('${latexDir.path}/Main LaTeX');
  Directory latexDocsDir = Directory('${appDir.path}/Temp/LaTeX Documents');
  Directory finTextFilesDir = Directory('${appDir.path}/Temp/Final Text Files/');
  Directory coverLetterDir = Directory('${latexDocsDir.path}/Cover Letter/Text Files/');
  Directory eduDir = Directory('${latexDocsDir.path}/Resume/First Page/Education/Txt/');
  Directory expDir = Directory('${latexDocsDir.path}/Resume/First Page/Experience/Txt/');
  Directory projDir = Directory('${latexDocsDir.path}/Resume/First Page/Projects/Txt/');
  Directory skillsDir = Directory('${latexDocsDir.path}/Resume/First Page/Qualifications/Txt/');
  // Delete Old LaTeX Dir If Needed
  if (latexDocsDir.existsSync()) {
    await latexDocsDir.delete(recursive: true);
  }
  // Create LaTeX Dir
  await latexDocsDir.create();
  // Copy LaTeX Directories
  await CopyDir(mainLatexDir, latexDocsDir, false);
  // Create Directories If Needed
  if (!coverLetterDir.existsSync()) {
    await coverLetterDir.create();
  }
  if (!eduDir.existsSync()) {
    await eduDir.create();
  }
  if (!expDir.existsSync()) {
    await expDir.create();
  }
  if (!projDir.existsSync()) {
    await projDir.create();
  }
  if (!skillsDir.existsSync()) {
    await skillsDir.create();
  }
  // Cover Letter Content - About
  File aboutFile = File('${finTextFilesDir.path}/$finCLAboutFile');
  await CopyFile(aboutFile, coverLetterDir);
  // Cover Letter Content - Company
  File compFile = File('${finTextFilesDir.path}/$finCLCompFile');
  await CopyFile(compFile, coverLetterDir);
  // Cover Letter Content - Job
  File jobFile = File('${finTextFilesDir.path}/$finCLJobFile');
  await CopyFile(jobFile, coverLetterDir);
  // Cover Letter Content - Me
  File meFile = File('${finTextFilesDir.path}/$finCLMeFile');
  await CopyFile(meFile, coverLetterDir);
  // Resume Content - Education
  File eduFile = File('${finTextFilesDir.path}$finEduRecFile');
  await CopyFile(eduFile, eduDir);
  // Resume Content - Experience
  File expFile = File('${finTextFilesDir.path}$finExpRecFile');
  await CopyFile(expFile, expDir);
  // Resume Content - Projects
  File projFile = File('${finTextFilesDir.path}$finProjRecFile');
  await CopyFile(projFile, projDir);
  // Resume Content - Frameworks
  File framFile = File('${finTextFilesDir.path}$finFramFile');
  await CopyFile(framFile, skillsDir);
  // Resume Content - Languages
  File langFile = File('${finTextFilesDir.path}/$finLangFile');
  await CopyFile(langFile, skillsDir);
  // Resume Content - Math
  File mathFile = File('${finTextFilesDir.path}/$finMathRecFile');
  await CopyFile(mathFile, skillsDir);
  // Resume Content - Personal
  File persFile = File('${finTextFilesDir.path}/$finPersRecFile');
  await CopyFile(persFile, skillsDir);
  // Resume Content - Programming
  File progFile = File('${finTextFilesDir.path}/$finProgRecFile');
  await CopyFile(progFile, skillsDir);
  // Resume Content - Scientific
  File sciFile = File('${finTextFilesDir.path}/$finSciRecFile');
  await CopyFile(sciFile, skillsDir);
}

Future<void> PrepLaTeXDirs() async {
  final appDir = await GetAppDir();
  Directory tempDir = Directory('${appDir.path}/Temp');
  Directory latexDir = Directory('${tempDir.path}/LaTeX Documents');
  Directory zipDir = Directory('${appDir.path}/Temp/Original Zip');
  Directory coverLetterDir = Directory('${latexDir.path}/Cover Letter');
  Directory portfolioDir = Directory('${latexDir.path}/Portfolio');
  Directory resumeDir = Directory('${latexDir.path}/Resume');
  if (zipDir.existsSync()) {
    await zipDir.delete(recursive: true);
  }
  await zipDir.create();
  await ZipDir(coverLetterDir, zipDir, true);
  await ZipDir(portfolioDir, zipDir, true);
  await ZipDir(resumeDir, zipDir, true);
}

Future<void> CompileDocuments(BuildContext context) async {
  // Master Directories
  final appDir = await GetAppDir();
  Directory tempDir = Directory('${appDir.path}/Temp');
  Directory origZipDir = Directory('${tempDir.path}/Original Zip');
  Directory finZipDir = Directory('${tempDir.path}/Zip');
  Directory latexDir = Directory('${tempDir.path}/LaTeX Documents');
  Directory finTextDir = Directory('${tempDir.path}/Final Text Files');
  Directory pdfDir = Directory('${tempDir.path}/PDFs');
  // Erase And Create Zip Directory
  if (finZipDir.existsSync()) {
    await finZipDir.delete(recursive: true);
  }
  await finZipDir.create();
  File coverLetter = File('${origZipDir.path}/Cover Letter.zip');
  File portfolio = File('${origZipDir.path}/Portfolio.zip');
  File resume = File('${origZipDir.path}/Resume.zip');
  // Compile Documents
  await LaTeXCompile(context, coverLetter, 'Cover Letter.zip', 'Cover Letter.zip', finZipDir, 'Compiling Cover Letter', 'Cover Letter Compiled Successfully');
  await LaTeXCompile(context, portfolio, 'Portfolio.zip', 'Portfolio.zip', finZipDir, 'Compiling Portfolio', 'Portfolio Compiled Successfully');
  await LaTeXCompile(context, resume, 'Resume.zip', 'Resume.zip', finZipDir, 'Compiling Resume', 'Resume Compiled Successfully');
  // Delete Old Zip Directory
  await origZipDir.delete(recursive: true);
  // Delete Text Files Directory
  await finTextDir.delete(recursive: true);
  // Erase And Create Latex Directory
  if (latexDir.existsSync()) {
    await latexDir.delete(recursive: true);
  }
  await latexDir.create();
  // Copy Zip Files
  coverLetter = File('${finZipDir.path}/Cover Letter.zip');
  portfolio = File('${finZipDir.path}/Portfolio.zip');
  resume = File('${finZipDir.path}/Resume.zip');
  await CopyFile(coverLetter, latexDir);
  await CopyFile(portfolio, latexDir);
  await CopyFile(resume, latexDir);
  // Delete Zip Directory
  await finZipDir.delete(recursive: true);
  // Unzip Files In LaTeX
  coverLetter = File('${latexDir.path}/Cover Letter.zip');
  portfolio = File('${latexDir.path}/Portfolio.zip');
  resume = File('${latexDir.path}/Resume.zip');
  await UnzipFile(latexDir, latexDir, 'Cover Letter.zip', true);
  await UnzipFile(latexDir, latexDir, 'Portfolio.zip', true);
  await UnzipFile(latexDir, latexDir, 'Resume.zip', true);
  // Copy PDFs Over
  File coverLetterPDF = File('${latexDir.path}/Cover Letter/main.pdf');
  File portfolioPDF = File('${latexDir.path}/Portfolio/main.pdf');
  File resumePDF = File('${latexDir.path}/Resume/main.pdf');
  if (pdfDir.existsSync()) {
    await pdfDir.delete(recursive: true);
  }
  await pdfDir.create();
  // Cover Letter
  await CopyFile(coverLetterPDF, pdfDir);
  coverLetterPDF = File('${pdfDir.path}/main.pdf');
  await coverLetterPDF.rename('${pdfDir.path}/Cover Letter.pdf');
  // Portfolio
  await CopyFile(portfolioPDF, pdfDir);
  portfolioPDF = File('${pdfDir.path}/main.pdf');
  await portfolioPDF.rename('${pdfDir.path}/Portfolio.pdf');
  // Resume
  await CopyFile(resumePDF, pdfDir);
  resumePDF = File('${pdfDir.path}/main.pdf');
  await resumePDF.rename('${pdfDir.path}/Resume.pdf');
}

Future<void> LaTeXCompile(BuildContext context, File zipFile, String inputZipName, String outputZipName, Directory destDir, String inProgressMessage, String completedMessage) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return ShowLoadingDialog(context, inProgressMessage);
    },
  );
  bool successful = false;
  var uri = Uri.parse(vpsLaTeX).replace(queryParameters: {
    'inputFileName': inputZipName,
    'returnFileName': outputZipName,
  });
  var request = http.MultipartRequest('POST', uri);
  var multipartFile = await http.MultipartFile.fromPath('file', zipFile.path);
  request.files.add(multipartFile);
  try {
    var response = await request.send();
    if (response.statusCode == 200) {
      var responseBody = await response.stream.toBytes();
      String filePath = path.join(destDir.path, outputZipName);
      File file = File(filePath);
      await file.writeAsBytes(responseBody);
      successful = true;
    }
  } catch (e) {
    throw ('Error occurred: $e');
  } finally {
    Navigator.of(context).pop();
    if (successful) {
      await ShowProducedDialog(context, 'Completed Successfully', completedMessage, Icons.done);
    } else {
      await ShowProducedDialog(context, 'Completed Unsuccessfully', 'An Error Has Occurred, Please Try Again', Icons.sms_failed);
    }
  }
}

Future<void> PDFPage(BuildContext context, Application app, String fileName) async {
  final appDir = await GetAppDir();
  File pdfFile = File('${appDir.path}/Applications/${app.name}/PDFs/$fileName');
  Navigator.of(context).pushAndRemoveUntil(RightToLeftPageRoute(page: PDFScreen(pdfFile: pdfFile, prevApp: app)), (Route<dynamic> route) => false);
}

Future<void> OpenFile(String filePath) async {
  File file = File(filePath);
  if (await file.exists()) {
    final fileUri = file.uri;
    if (await canLaunchUrl(fileUri)) {
      await launchUrl(fileUri);
    } else {
      throw 'Could not launch $fileUri';
    }
  } else {
    throw 'File does not exist at $filePath';
  }
}

Future<void> SaveFile(BuildContext context, String filePath) async {
  File file = File(filePath);
  if (await file.exists()) {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      String fileName = path.basename(filePath);
      String newFilePath = path.join(selectedDirectory, fileName);
      await file.copy(newFilePath);
      GenSnackBar(context, 'File saved to $newFilePath');
    }
  } else {
    GenSnackBar(context, 'File does not exist');
  }
}

Future<void> SaveFiles(BuildContext context, Application app, bool coverLetter, bool portfolio, bool resume) async {
  if (coverLetter || portfolio || resume) {
    final appDir = await GetAppDir();
    File clFile = File('${appDir.path}/Applications/${app.name}/PDFs/Cover Letter.pdf');
    File poFile = File('${appDir.path}/Applications/${app.name}/PDFs/Portfolio.pdf');
    File reFile = File('${appDir.path}/Applications/${app.name}/PDFs/Resume.pdf');
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      if (coverLetter) {
        if (await clFile.exists()) {
          String newFilePath = '$selectedDirectory/Cover Letter.pdf';
          await clFile.copy(newFilePath);
          GenSnackBar(context, 'Cover Letter saved to $newFilePath');
        } else {
          GenSnackBar(context, 'Cover Letter does not exist.');
        }
      }
      if (portfolio) {
        if (await poFile.exists()) {
          String newFilePath = '$selectedDirectory/Portfolio.pdf';
          await poFile.copy(newFilePath);
          GenSnackBar(context, 'Portfolio saved to $newFilePath');
        } else {
          GenSnackBar(context, 'Portfolio does not exist');
        }
      }
      if (resume) {
        if (await reFile.exists()) {
          String newFilePath = '$selectedDirectory/Resume.pdf';
          await reFile.copy(newFilePath);
          GenSnackBar(context, 'Resume saved to $newFilePath');
        } else {
          GenSnackBar(context, 'Resume does not exist');
        }
      }
    }
  } else {
    GenSnackBar(context, 'No files selected.');
  }
}
