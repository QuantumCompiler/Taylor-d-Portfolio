import 'package:flutter/material.dart';
import '../Globals/Globals.dart';
import 'JobsUtils.dart';

class EditJobPage extends StatelessWidget {
  // Job Name
  final String jobName;
  const EditJobPage({required this.jobName, super.key});
  @override
  // Main Widget
  Widget build(BuildContext context) {
    Job prevJob = Job(name: jobName);
    prevJob.LoadJobData();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.dashboard),
            onPressed: () {
              if (isDesktop()) {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              } else if (isMobile()) {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              }
            },
          ),
        ],
        title: Text(
          prevJob.name,
          style: TextStyle(
            fontSize: appBarTitle,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Job Name
            ...JobEntry(context, jobsNameTitle, prevJob.nameCont, '', lines: 1),
            // Description
            ...JobEntry(context, jobsDesTitle, prevJob.desCont, jobsDesHint),
            // Other
            ...JobEntry(context, jobsOtherTitle, prevJob.otherCont, jobsOtherHint),
            // Position
            ...JobEntry(context, jobsPosTitle, prevJob.posCont, jobsPosHint),
            // Qualifications
            ...JobEntry(context, jobsQualsTitle, prevJob.qualsCont, jobsQualsHint),
            // Role
            ...JobEntry(context, jobsRoleTitle, prevJob.roleCont, jobsRoleHint),
            // Tasks
            ...JobEntry(context, jobsTasksTitle, prevJob.tasksCont, jobsTasksHint),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isDesktop()) ...[
              ElevatedButton(
                onPressed: () {
                  prevJob.setOverwriteFiles();
                  Navigator.of(context).pop();
                },
                child: Text('Overwrite'),
              ),
              SizedBox(width: standardSizedBoxWidth),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancel'),
              ),
            ] else if (isMobile()) ...[
              IconButton(
                onPressed: () {
                  prevJob.setOverwriteFiles();
                  Navigator.of(context).pop();
                },
                icon: Icon(Icons.save),
              ),
              SizedBox(width: standardSizedBoxWidth),
              IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: Icon(Icons.cancel),
              ),
              SizedBox(width: standardSizedBoxWidth),
            ]
          ],
        ),
      ),
    );
  }
}
