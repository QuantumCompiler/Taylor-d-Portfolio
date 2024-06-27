import 'dart:io';
import 'package:flutter/material.dart';
import '../Globals/Globals.dart';
import 'JobsUtils.dart';
import '../Themes/Themes.dart';

class NewJobPage extends StatelessWidget {
  const NewJobPage({super.key});
  @override
  Widget build(BuildContext context) {
    Job newJob = Job();
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
              } else if (isMobile()) {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              }
            },
          ),
        ],
        title: Text(
          jobsCreateNew,
          style: TextStyle(
            color: themeTextColor(context),
            fontSize: appBarTitle,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            // Description
            ...JobEntry(context, jobsDesTitle, newJob.desCont, jobsDesHint),
            // Other
            ...JobEntry(context, jobsOtherTitle, newJob.otherCont, jobsOtherHint),
            // Position
            ...JobEntry(context, jobsPosTitle, newJob.posCont, jobsPosHint),
            // Qualifications
            ...JobEntry(context, jobsQualsTitle, newJob.qualsCont, jobsQualsHint),
            // Role
            ...JobEntry(context, jobsRoleTitle, newJob.roleCont, jobsRoleHint),
            // Tasks
            ...JobEntry(context, jobsTasksTitle, newJob.tasksCont, jobsTasksHint),
          ],
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Save Job
            if (isDesktop()) ...[
              ElevatedButton(
                onPressed: () async {
                  // Show Dialog
                  await showDialog(
                    context: context,
                    builder: (context) {
                      // Alert Dialog
                      return AlertDialog(
                        title: Text(
                          'Enter Name Of Current Job',
                          style: TextStyle(
                            fontSize: appBarTitle,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: TextField(
                          controller: newJob.nameCont,
                          decoration: InputDecoration(hintText: "Job Name"),
                        ),
                        actions: <Widget>[
                          // Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              ElevatedButton(
                                child: Text('Cancel'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              SizedBox(width: 20),
                              ElevatedButton(
                                child: Text('Save'),
                                onPressed: () async {
                                  final dir = await newJob.jobsDir;
                                  final currDir = Directory('${dir.path}/${newJob.nameCont.text}');
                                  if (!currDir.existsSync()) {
                                    newJob.CreateNewJob(newJob.nameCont.text);
                                    Navigator.of(context).pop();
                                    Navigator.of(context).pop();
                                  } else {
                                    Navigator.of(context).pop();
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: Text(
                                            'Job Already Exists',
                                            style: TextStyle(
                                              fontSize: appBarTitle,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          content: Text(
                                            'Please choose a different name for this job.',
                                            textAlign: TextAlign.center,
                                          ),
                                        );
                                      },
                                    );
                                    newJob.nameCont.text = '';
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Text('Save Job'),
              ),
            ] else if (isMobile()) ...[
              IconButton(
                onPressed: () async {
                  // Show Dialog
                  await showDialog(
                    context: context,
                    builder: (context) {
                      // Alert Dialog
                      return AlertDialog(
                        title: Text(
                          'Enter Name Of Current Profile',
                          style: TextStyle(
                            fontSize: appBarTitle,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: TextField(
                          // controller: newProfile.nameCont,
                          decoration: InputDecoration(hintText: "Profile Name"),
                        ),
                        actions: <Widget>[
                          // Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              IconButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                icon: Icon(Icons.cancel),
                              ),
                              SizedBox(width: 20),
                              IconButton(
                                icon: Icon(Icons.save),
                                onPressed: () async {
                                  final dir = await newJob.jobsDir;
                                  final currDir = Directory('${dir.path}/${newJob.nameCont.text}');
                                  if (!currDir.existsSync()) {
                                    newJob.CreateNewJob(newJob.nameCont.text);
                                    Navigator.of(context).pop();
                                    Navigator.of(context).pop();
                                  } else {
                                    Navigator.of(context).pop();
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: Text(
                                            'Job Already Exists',
                                            style: TextStyle(
                                              fontSize: appBarTitle,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          content: Text(
                                            'Please choose a different name for this job.',
                                            textAlign: TextAlign.center,
                                          ),
                                        );
                                      },
                                    );
                                    newJob.nameCont.text = '';
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: Icon(Icons.save),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
