import 'dart:io';
import 'package:flutter/material.dart';
import '../Globals/JobsGlobals.dart';
import '../Globals/Globals.dart';
import '../Themes/Themes.dart';

class Job {
  // Directories
  final Future<Directory> appDir = GetAppDir();
  final Future<Directory> cacheDir = GetCacheDir();
  final Future<Directory> jobsDir = GetJobsDir();
  final Future<Directory> supDir = GetSupportDir();

  // Files
  late File desFile;
  late File othFile;
  late File qualFile;
  late File roleFile;

  // Main Titles & Name
  late String desTitle;
  late String name;
  late String othTitle;
  late String qualTitle;
  late String roleTitle;

  // Contents
  late String description;
  late String other;
  late String quals;
  late String roleInfo;

  // Controllers
  late TextEditingController desCont;
  late TextEditingController nameCont;
  late TextEditingController otherCont;
  late TextEditingController qualsCont;
  late TextEditingController roleCont;

  // Constructor
  Job({this.name = ''}) {
    desTitle = descriptionTitle;
    othTitle = otherTitle;
    qualTitle = qualificationsTitle;
    roleTitle = roleInfoTitle;
    desCont = TextEditingController();
    nameCont = TextEditingController();
    otherCont = TextEditingController();
    qualsCont = TextEditingController();
    roleCont = TextEditingController();
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
    desFile = File('${currJob.path}/$descriptionFile');
    othFile = File('${currJob.path}/$otherFile');
    qualFile = File('${currJob.path}/$qualificationsFile');
    roleFile = File('${currJob.path}/$roleInfoFile');
    if (desFile.existsSync()) {
      description = await desFile.readAsString();
      desCont.text = description;
    }
    if (othFile.existsSync()) {
      other = await othFile.readAsString();
      otherCont.text = other;
    }
    if (qualFile.existsSync()) {
      quals = await qualFile.readAsString();
      qualsCont.text = quals;
    }
    if (roleFile.existsSync()) {
      roleInfo = await roleFile.readAsString();
      roleCont.text = roleInfo;
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
    final existing = Directory('${dir.path}/$newName');
    Directory newDir;
    if (oldDir.existsSync() && !existing.existsSync()) {
      newDir = await oldDir.rename('${dir.path}/$newName');
      name = newName;
    } else {
      newDir = oldDir;
    }
    desFile = File('${newDir.path}/$descriptionFile');
    othFile = File('${newDir.path}/$otherFile');
    qualFile = File('${newDir.path}/$qualificationsFile');
    roleFile = File('${newDir.path}/$roleInfoFile');
    WriteFile(dir, desFile, desCont.text);
    WriteFile(dir, othFile, otherCont.text);
    WriteFile(dir, qualFile, qualsCont.text);
    WriteFile(dir, roleFile, roleCont.text);
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
    desFile = File('${currDir.path}/$descriptionFile');
    othFile = File('${currDir.path}/$otherFile');
    qualFile = File('${currDir.path}/$qualificationsFile');
    roleFile = File('${currDir.path}/$roleInfoFile');
    WriteFile(dir, desFile, desCont.text);
    WriteFile(dir, othFile, otherCont.text);
    WriteFile(dir, qualFile, qualsCont.text);
    WriteFile(dir, roleFile, roleCont.text);
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
