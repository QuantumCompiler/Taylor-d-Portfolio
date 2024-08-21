import 'package:flutter/material.dart';
import '../../Context/Globals/GlobalContext.dart';
import '../../Globals/Globals.dart';
import '../../Globals/JobsGlobals.dart';
import '../../Utilities/JobUtils.dart';

class JobContentEntry extends StatefulWidget {
  final Job job;
  final JobContentType type;
  final List<GlobalKey> keyList;
  final bool viewing;
  const JobContentEntry({
    super.key,
    required this.job,
    required this.type,
    required this.keyList,
    required this.viewing,
  });

  @override
  JobContentEntryState createState() => JobContentEntryState();
}

class JobContentEntryState extends State<JobContentEntry> {
  @override
  Widget build(BuildContext context) {
    switch (widget.type) {
      case JobContentType.description:
        return DescriptionJobEntry(job: widget.job, key: widget.keyList[0], viewing: widget.viewing);
      case JobContentType.other:
        return OtherInfoJobEntry(job: widget.job, key: widget.keyList[1], viewing: widget.viewing);
      case JobContentType.role:
        return RoleJobEntry(job: widget.job, key: widget.keyList[2], viewing: widget.viewing);
      case JobContentType.skills:
        return SkillsJobEntry(job: widget.job, key: widget.keyList[3], viewing: widget.viewing);
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
              try {
                await job.WriteContentToJSON<JobDesCont>(finalDir, descriptionJSONFile, job.descriptionContList);
                GenSnackBar(context, 'Job Description Content Written Successfully');
              } catch (e) {
                throw ('Error occurred: $e');
              }
            } else if (type == JobContentType.other) {
              try {
                await job.WriteContentToJSON<JobOtherCont>(finalDir, otherJSONFile, job.otherInfoContList);
                GenSnackBar(context, 'Other Information Content Written Successfully');
              } catch (e) {
                throw ('Error occurred: $e');
              }
            } else if (type == JobContentType.role) {
              try {
                await job.WriteContentToJSON<JobRoleCont>(finalDir, roleJSONFile, job.roleContList);
                GenSnackBar(context, 'Role Description Content Written Successfully');
              } catch (e) {
                throw ('Error occurred: $e');
              }
            } else if (type == JobContentType.skills) {
              try {
                await job.WriteContentToJSON<JobSkillsCont>(finalDir, skillsJSONFile, job.skillsContList);
                GenSnackBar(context, 'Skill Requirements Content Written Successfully');
              } catch (e) {
                throw ('Error occurred: $e');
              }
            }
          },
        ),
      ],
    ),
  );
}
