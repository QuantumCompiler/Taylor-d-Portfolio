import 'dart:io';
import 'package:path/path.dart' as p;

class ApplicationContent {
  List<Directory> jobs;
  List<Directory> profiles;
  List<String> allJobs;
  List<String> allProfiles;
  List<String> checkedJobs;
  List<String> checkedProfiles;

  ApplicationContent({
    required this.jobs,
    required this.profiles,
    List<String>? checkedJobs,
    List<String>? checkedProfiles,
  })  : allJobs = jobs.map((job) => job.path.split('/').last).toList(),
        allProfiles = profiles.map((profile) => profile.path.split('/').last).toList(),
        checkedJobs = checkedJobs ?? [],
        checkedProfiles = checkedProfiles ?? [];

  void clearBoxes(List<String> jobs, List<String> profiles, Function setState) {
    setState(() {
      jobs.clear();
      profiles.clear();
    });
  }

  void updateBoxes(List<String> items, List<String> checks, String key, bool? value, Function setState) {
    setState(() {
      if (value == true && checks.isEmpty) {
        checks.add(key);
      } else if (value == false && checks.contains(key)) {
        checks.remove(key);
      }
    });
  }

  bool verifyBoxes() {
    bool jobsValid = checkedJobs.length == 1;
    bool profilesValid = checkedProfiles.length == 1;
    return jobsValid && profilesValid;
  }
}

bool isJob(ApplicationContent content, String name) {
  for (int i = 0; i < content.jobs.length; i++) {
    String jobPath = content.jobs[i].toString();
    String jobName = p.basename(jobPath).trim().replaceAll("'", "");
    if (jobName == name) {
      return true;
    }
  }
  return false;
}

bool isProfile(ApplicationContent content, String name) {
  for (int i = 0; i < content.profiles.length; i++) {
    String profilePath = content.profiles[i].toString();
    String profileName = p.basename(profilePath).trim().replaceAll("'", "");
    if (profileName == name) {
      return true;
    }
  }
  return false;
}
