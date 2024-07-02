import 'dart:io';
import 'package:path/path.dart' as p;

class ApplicationContent {
  List<Directory> jobs;
  List<Directory> profiles;
  Map<String, bool> checkedJobs;
  Map<String, bool> checkedProfiles;

  ApplicationContent({
    required this.jobs,
    required this.profiles,
    required this.checkedJobs,
    required this.checkedProfiles,
  });

  void updateJobs(List<Directory> newJobs) {
    jobs = newJobs;
  }

  void updateProfiles(List<Directory> newProfiles) {
    profiles = newProfiles;
  }
}

String? getCheckedItem(Map<String, bool> items) {
  String? checked;
  items.forEach(
    (key, value) {
      if (value) {
        checked = key;
      }
    },
  );
  return checked;
}

bool verifyValidInput(ApplicationContent content) {
  bool jobValid = content.checkedJobs.values.contains(true);
  bool profilesValid = content.checkedProfiles.values.contains(true);
  bool valid = jobValid && profilesValid;
  return valid;
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
