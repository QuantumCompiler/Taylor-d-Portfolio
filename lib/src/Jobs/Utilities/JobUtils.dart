import 'dart:io';
import 'package:flutter/material.dart';
import '../../Globals/Globals.dart';
import '../../Themes/Themes.dart';

class Job {
  // Directories
  final Future<Directory> appDir = GetAppDir();
  final Future<Directory> cacheDir = GetCacheDir();
  final Future<Directory> jobsDir = GetJobsDir();
  final Future<Directory> supDir = GetSupportDir();

  // Files
  late File desFile;
  late File otherFile;
  late File posFile;
  late File qualsFile;
  late File roleFile;
  late File tasksFile;

  // Main Titles & Name
  late String descriptionTitle;
  late String name;
  late String otherTitle;
  late String positionTitle;
  late String qualsTitle;
  late String roleInfoTitle;
  late String tasksTitle;

  // Contents
  late String description;
  late String other;
  late String position;
  late String quals;
  late String roleInfo;
  late String tasks;

  // Controllers
  late TextEditingController desCont;
  late TextEditingController nameCont;
  late TextEditingController otherCont;
  late TextEditingController posCont;
  late TextEditingController qualsCont;
  late TextEditingController roleCont;
  late TextEditingController tasksCont;

  // Constructor
  Job({this.name = ''}) {
    descriptionTitle = jobsDesTitle;
    otherTitle = jobsOtherTitle;
    positionTitle = jobsPosTitle;
    qualsTitle = jobsQualsTitle;
    roleInfoTitle = jobsRoleTitle;
    tasksTitle = jobsTasksTitle;
    desCont = TextEditingController();
    nameCont = TextEditingController();
    otherCont = TextEditingController();
    posCont = TextEditingController();
    qualsCont = TextEditingController();
    roleCont = TextEditingController();
    tasksCont = TextEditingController();
  }

  // Create New Job
  Future<void> CreateNewJob(String jobName) async {
    setJobName(jobName);
    setJobDir();
    setWriteNewFiles();
  }

  // Load Job
  Future<void> LoadJobData() async {
    final jobsDirectory = await jobsDir;
    final currJob = Directory('${jobsDirectory.path}/$name');
    if (currJob.existsSync()) {
      nameCont.text = name;
    }
    desFile = File('${currJob.path}/$jobsDesFile');
    otherFile = File('${currJob.path}/$jobsOtherFile');
    posFile = File('${currJob.path}/$jobsPosFile');
    qualsFile = File('${currJob.path}/$jobsQualsFile');
    roleFile = File('${currJob.path}/$jobsRoleFile');
    tasksFile = File('${currJob.path}/$jobsTasksFile');
    if (await desFile.existsSync()) {
      description = await desFile.readAsString();
      desCont.text = description;
    }
    if (await otherFile.existsSync()) {
      other = await otherFile.readAsString();
      otherCont.text = other;
    }
    if (await posFile.existsSync()) {
      position = await posFile.readAsString();
      posCont.text = position;
    }
    if (await qualsFile.existsSync()) {
      quals = await qualsFile.readAsString();
      qualsCont.text = quals;
    }
    if (await roleFile.existsSync()) {
      roleInfo = await roleFile.readAsString();
      roleCont.text = roleInfo;
    }
    if (await tasksFile.existsSync()) {
      tasks = await tasksFile.readAsString();
      tasksCont.text = tasks;
    }
  }

  // Setters

  // Set Job Name
  Future<void> setJobName(String jobName) async {
    name = jobName;
  }

  // Set Overwrite Files
  Future<void> setOverwriteFiles() async {
    final dir = await jobsDir;
    final newName = nameCont.text;
    final oldDir = Directory('${dir.path}/$name');
    Directory newDir;
    if (await oldDir.existsSync()) {
      newDir = await oldDir.rename('${dir.path}/$newName');
    } else {
      newDir = Directory('${dir.path}/$newName');
      await newDir.create();
    }
    name = newName;
    desFile = File('${newDir.path}/$jobsDesFile');
    otherFile = File('${newDir.path}/$jobsOtherFile');
    posFile = File('${newDir.path}/$jobsPosFile');
    qualsFile = File('${newDir.path}/$jobsQualsFile');
    roleFile = File('${newDir.path}/$jobsRoleFile');
    tasksFile = File('${newDir.path}/$jobsTasksFile');
    WriteFile(dir, desFile, desCont.text);
    WriteFile(dir, otherFile, otherCont.text);
    WriteFile(dir, posFile, posCont.text);
    WriteFile(dir, qualsFile, qualsCont.text);
    WriteFile(dir, roleFile, roleCont.text);
    WriteFile(dir, tasksFile, tasksCont.text);
  }

  // Set Job Directory
  Future<void> setJobDir() async {
    final parentDir = await jobsDir;
    CreateDir(parentDir, name);
  }

  // Set Write New Files
  Future<void> setWriteNewFiles() async {
    final dir = await jobsDir;
    final currDir = Directory('${dir.path}/$name');
    desFile = File('${currDir.path}/$jobsDesFile');
    otherFile = File('${currDir.path}/$jobsOtherFile');
    posFile = File('${currDir.path}/$jobsPosFile');
    qualsFile = File('${currDir.path}/$jobsQualsFile');
    roleFile = File('${currDir.path}/$jobsRoleFile');
    tasksFile = File('${currDir.path}/$jobsTasksFile');
    WriteFile(dir, desFile, desCont.text);
    WriteFile(dir, otherFile, otherCont.text);
    WriteFile(dir, posFile, posCont.text);
    WriteFile(dir, qualsFile, qualsCont.text);
    WriteFile(dir, roleFile, roleCont.text);
    WriteFile(dir, tasksFile, tasksCont.text);
  }
}

Future<void> DeleteAllJobs() async {
  final jobsDir = await GetJobsDir();
  final List<FileSystemEntity> jobs = jobsDir.listSync();
  for (final job in jobs) {
    if (job is Directory) {
      await job.delete(recursive: true);
    }
  }
}

Future<void> DeleteJob(String jobName) async {
  final jobsDir = await GetJobsDir();
  final jobDir = Directory('${jobsDir.path}/$jobName');
  if (await jobDir.exists()) {
    await jobDir.delete(recursive: true);
  }
}

List<Widget> JobEntry(BuildContext context, String title, TextEditingController controller, String hintText, {int? lines = 10}) {
  return [
    Center(
      child: Text(
        title,
        style: TextStyle(
          color: themeTextColor(context),
          fontSize: jobTitleSize,
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

Future<List<Directory>> RetrieveSortedJobs() async {
  final jobsDir = await GetJobsDir();
  final jobsList = jobsDir.listSync().whereType<Directory>().toList();
  jobsList.sort((a, b) => a.path.split('/').last.compareTo(b.path.split('/').last));
  return jobsList;
}
