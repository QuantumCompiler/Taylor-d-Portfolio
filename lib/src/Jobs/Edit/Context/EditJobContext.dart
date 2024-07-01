import 'package:flutter/material.dart';
import '../../Globals/JobsGlobals.dart';
import '../../Utilities/JobUtils.dart';
import '../../../Globals/Globals.dart';

/*  appBar - AppBar for the Edit Job Page
      Input:
        context: BuildContext of the parent
        prevJob: Job object of the previous job
      Algorithm:
        * Create an AppBar with a leading back button and a dashboard button
        * Modify the button actions depending on the platform
        * Set the title of the AppBar to the name of the previous job
      Output:
        Returns an AppBar object
*/
AppBar appBar(BuildContext context, Job prevJob) {
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
  );
}

/*  editJobContent - SingleChildScrollView for the Edit Job Page
      Input:
        context: BuildContext of the parent
        prevJob: Job object of the previous job
      Algorithm:
        * Create a SingleChildScrollView with a Column of the following:
          * Job Name
          * Description
          * Other
          * Position
          * Qualifications
          * Role
          * Tasks
      Output:
        Returns a SingleChildScrollView object
*/
SingleChildScrollView editJobContent(BuildContext context, Job prevJob) {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Job Name
        ...JobEntry(context, jobNameTitle, prevJob.nameCont, '', lines: 1),
        // Description
        ...JobEntry(context, descriptionTitle, prevJob.desCont, descriptionHint),
        // Other
        ...JobEntry(context, otherTitle, prevJob.otherCont, otherHint),
        // Position
        ...JobEntry(context, positionTitle, prevJob.posCont, positionHint),
        // Qualifications
        ...JobEntry(context, qualificationsTitle, prevJob.qualsCont, qualificationsHint),
        // Role
        ...JobEntry(context, roleInfoTitle, prevJob.roleCont, roleInfoHint),
        // Tasks
        ...JobEntry(context, tasksTitle, prevJob.tasksCont, tasksHint),
      ],
    ),
  );
}

/*  bottomAppBar - BottomAppBar for the Edit Job Page
      Input:
        context: BuildContext of the parent
        prevJob: Job object of the previous job
      Algorithm:
        * Create a BottomAppBar with a Row of the following:
          * Overwrite Button
          * Cancel Button
        * Modify the button actions depending on the platform
      Output:
        Returns a BottomAppBar object
*/
BottomAppBar bottomAppBar(BuildContext context, Job prevJob) {
  return BottomAppBar(
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
            child: Text(overWriteButton),
          ),
          SizedBox(width: standardSizedBoxWidth),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(cancelButton),
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
  );
}
