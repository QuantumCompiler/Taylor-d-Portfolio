import 'package:flutter/material.dart';
import '../../Globals/Globals.dart';
import '../../Globals/JobsGlobals.dart';
import '../../Utilities/JobUtils.dart';

class JobContentEntry extends StatefulWidget {
  final Job job;
  final JobContentType type;
  final List<GlobalKey> keyList;
  const JobContentEntry({
    super.key,
    required this.job,
    required this.type,
    required this.keyList,
  });

  @override
  JobContentEntryState createState() => JobContentEntryState();
}

class JobContentEntryState extends State<JobContentEntry> {
  @override
  Widget build(BuildContext context) {
    switch (widget.type) {
      case JobContentType.description:
        return DescriptionJobEntry(job: widget.job, key: widget.keyList[0]);
      case JobContentType.other:
        return OtherInfoJobEntry(job: widget.job, key: widget.keyList[1]);
      case JobContentType.role:
        return RoleJobEntry(job: widget.job, key: widget.keyList[2]);
      case JobContentType.skills:
        return SkillsJobEntry(job: widget.job, key: widget.keyList[3]);
    }
  }
}

AppBar JobContentAppBar(BuildContext context, JobContentType type, String jobName) {
  String title = '';
  if (jobName == '') {
    jobName = 'New Job';
  }
  if (type == JobContentType.description) {
    title = 'Job Description - $jobName';
  } else if (type == JobContentType.other) {
    title = 'Other Information - $jobName';
  } else if (type == JobContentType.role) {
    title = 'Role Description - $jobName';
  } else if (type == JobContentType.skills) {
    title = 'Skill Requirements - $jobName';
  }
  return AppBar(
    title: Text(
      title,
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
    ),
    leading: IconButton(
      icon: Icon(Icons.arrow_back_ios_new_outlined),
      onPressed: () {
        Navigator.of(context).pop();
      },
    ),
  );
}

BottomAppBar JobContentBottomAppBar(BuildContext context, JobContentType type, Job job, List<GlobalKey> keyList) {
  String finalDir = '';
  if (job.newJob == true) {
    finalDir = 'Temp';
  } else if (job.newJob == false) {
    finalDir = 'Jobs/${job.name}';
  }
  String buttonText;
  if (type == JobContentType.description) {
    buttonText = 'Save Description';
  } else if (type == JobContentType.other) {
    buttonText = 'Save Other';
  } else if (type == JobContentType.role) {
    buttonText = 'Save Role';
  } else if (type == JobContentType.skills) {
    buttonText = 'Save Skills';
  } else {
    buttonText = 'Save Content';
  }
  return BottomAppBar(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          child: Text(buttonText),
          onPressed: () async {
            if (type == JobContentType.description) {
              await job.WriteContentToJSON<JobDesCont>(finalDir, descriptionJSONFile, job.descriptionContList);
            } else if (type == JobContentType.other) {
              await job.WriteContentToJSON<JobOtherCont>(finalDir, otherJSONFile, job.otherInfoContList);
            } else if (type == JobContentType.role) {
              await job.WriteContentToJSON<JobRoleCont>(finalDir, roleJSONFile, job.roleContList);
            } else if (type == JobContentType.skills) {
              await job.WriteContentToJSON<JobSkillsCont>(finalDir, skillsJSONFile, job.skillsContList);
            }
          },
        ),
      ],
    ),
  );
}
