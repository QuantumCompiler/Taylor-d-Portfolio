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
              await job.WriteContentToJSON(finalDir, descriptionJSONFile, job.descriptionContList);
            }
          },
        ),
      ],
    ),
  );
}