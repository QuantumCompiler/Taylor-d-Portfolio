import 'dart:io';
import '../../Profiles/Utilities/ProfilesUtils.dart';
import '../../Jobs/Utilities/JobUtils.dart';

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

  Future<void> refreshData() async {
    jobs.clear();
    allJobs.clear();
    List<Directory> newJobs = await RetrieveSortedJobs();
    List<String> newAllJobs = [];
    for (int i = 0; i < newJobs.length; i++) {
      newAllJobs.add(newJobs[i].path.split('/').last);
    }
    jobs = newJobs;
    allJobs = newAllJobs;
  }

  // void updateData(List<Directory> newJobs, List<Directory> newProfiles) {
  // updateJobs(newJobs);
  // updateProfiles(newProfiles);
  // }

  void updateBoxes(List<String> items, List<String> checks, String key, bool? value, Function setState) {
    setState(() {
      if (value == true && checks.isEmpty) {
        checks.add(key);
      } else if (value == false && checks.contains(key)) {
        checks.remove(key);
      }
    });
  }

  void updateJobs(List<Directory> newJobs) async {
    // newJobs = await RetrieveSortedJobs();
    // print(newJobs);
    // jobs = newJobs;
    // allJobs = jobs.map((job) => job.path.split('/').last).toList();
  }

  // void updateProfiles(List<Directory> newProfiles) {
  //   profiles = newProfiles;
  //   allProfiles = profiles.map((profile) => profile.path.split('/').last).toList();
  // }

  bool verifyBoxes() {
    bool jobsValid = checkedJobs.length == 1;
    bool profilesValid = checkedProfiles.length == 1;
    return jobsValid && profilesValid;
  }
}
