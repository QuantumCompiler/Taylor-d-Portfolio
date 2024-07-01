import 'dart:io';
import 'package:flutter/material.dart';
import '../../Globals/JobsGlobals.dart';
import '../../Utilities/JobUtils.dart';
import '../../../Globals/Globals.dart';
import '../../../Themes/Themes.dart';

/*  appBar - AppBar for the new job page
      Input:
        context - BuildContext for the page
      Algorithm:
        * Create icons in the AppBar for navigation
        * Modify the behavior of the icons based on the platform
        * Create the title for the AppBar
      Output:
        Returns the AppBar for the new job page
*/
AppBar appBar(BuildContext context) {
  return AppBar(
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
      createNewJob,
      style: TextStyle(
        color: themeTextColor(context),
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

/*  newJobContent - Content for the new job page
      Input:
        context - BuildContext for the page
        newJob - Job object for the new job
      Algorithm:
        * Create a scrollable column for the new job page
        * Add text fields for the job description, other information, position, qualifications, role information, and tasks
      Output:
        Returns the content for the new job page
*/
SingleChildScrollView newJobContent(BuildContext context, Job newJob) {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        // Description
        ...JobEntry(context, descriptionTitle, newJob.desCont, descriptionHint),
        // Other
        ...JobEntry(context, otherTitle, newJob.otherCont, otherHint),
        // Position
        ...JobEntry(context, positionTitle, newJob.posCont, positionHint),
        // Qualifications
        ...JobEntry(context, qualificationsTitle, newJob.qualsCont, qualificationsHint),
        // Role
        ...JobEntry(context, roleInfoTitle, newJob.roleCont, roleInfoHint),
        // Tasks
        ...JobEntry(context, tasksTitle, newJob.tasksCont, tasksHint),
      ],
    ),
  );
}

/*  bottomAppBar - BottomAppBar for the new job page
      Input:
        context - BuildContext for the page
        newJob - Job object for the new job
      Algorithm:
        * Create a row for the bottom app bar
        * Modify the behavior of the row based on the platform
      Output:
        Returns the BottomAppBar for the new job page
*/
BottomAppBar bottomAppBar(BuildContext context, Job newJob) {
  return BottomAppBar(
    color: Colors.transparent,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (isDesktop()) ...[
          desktopRender(context, newJob)
        ] else if (isMobile()) ...[
          mobileRender(context, newJob),
        ]
      ],
    ),
  );
}

/*  desktopRender - Render the desktop version of the new job page
      Input:
        context - BuildContext for the page
        newJob - Job object for the new job
      Algorithm:
        * Create an ElevatedButton for the desktop version of the new job page
        * Modify the behavior of the ElevatedButton based on the platform
      Output:
        Returns the ElevatedButton for the desktop version of the new job page
*/
ElevatedButton desktopRender(BuildContext context, Job newJob) {
  return ElevatedButton(
    onPressed: () async {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              newJobPrompt,
              style: TextStyle(
                fontSize: appBarTitle,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: TextField(
              controller: newJob.nameCont,
              decoration: InputDecoration(hintText: jobNameHint),
            ),
            actions: <Widget>[
              desktopRow(context, newJob),
            ],
          );
        },
      );
    },
    child: Text(saveJobButton),
  );
}

/*  desktopRow - Row for the desktop version of the new job page
      Input:
        context - BuildContext for the page
        newJob - Job object for the new job
      Algorithm:
        * Create two ElevatedButtons for the desktop version of the new job page
        * Modify the behavior of the ElevatedButtons based on the platform
      Output:
        Returns the Row for the desktop version of the new job page
*/
Row desktopRow(BuildContext context, Job newJob) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      ElevatedButton(
        child: Text(cancelButton),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
      SizedBox(width: 20),
      ElevatedButton(
        child: Text(saveButton),
        onPressed: () async {
          final dir = await newJob.jobsDir;
          final currDir = Directory('${dir.path}/${newJob.nameCont.text}');
          if (!currDir.existsSync()) {
            newJob.CreateNewJob(newJob.nameCont.text);
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          } else {
            Navigator.of(context).pop();
            jobAlreadyExist(context);
            newJob.nameCont.text = '';
          }
        },
      ),
    ],
  );
}

/*  mobileRender - Render the mobile version of the new job page
      Input:
        context - BuildContext for the page
        newJob - Job object for the new job
      Algorithm:
        * Create an IconButton for the mobile version of the new job page
        * Modify the behavior of the IconButton based on the platform
      Output:
        Returns the IconButton for the mobile version of the new job page
*/
IconButton mobileRender(BuildContext context, Job newJob) {
  return IconButton(
    onPressed: () async {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              newJobPrompt,
              style: TextStyle(
                fontSize: appBarTitle,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: TextField(
              controller: newJob.nameCont,
              decoration: InputDecoration(hintText: jobNameHint),
            ),
            actions: <Widget>[
              mobileButtons(context, newJob),
            ],
          );
        },
      );
    },
    icon: Icon(Icons.save),
  );
}

/*  mobileButtons - Row for the mobile version of the new job page
      Input:
        context - BuildContext for the page
        newJob - Job object for the new job
      Algorithm:
        * Create two IconButtons for the mobile version of the new job page
        * Modify the behavior of the IconButtons based on the platform
      Output:
        Returns the Row for the mobile version of the new job page
*/
Row mobileButtons(BuildContext context, Job newJob) {
  return Row(
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
            jobAlreadyExist(context);
            newJob.nameCont.text = '';
          }
        },
      ),
    ],
  );
}

/*  jobAlreadyExist - Dialog for when a job already exists
      Input:
        context - BuildContext for the page
      Algorithm:
        * Create an AlertDialog for when a job already exists
        * Modify the behavior of the AlertDialog based on the platform
      Output:
        Returns the AlertDialog for when a job already exists
*/
Future<dynamic> jobAlreadyExist(BuildContext context) async {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(
          jobAlreadyExistsPrompt,
          style: TextStyle(
            fontSize: appBarTitle,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          differentNamePrompt,
          textAlign: TextAlign.center,
        ),
      );
    },
  );
}
