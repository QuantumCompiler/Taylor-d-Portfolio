import 'package:flutter/material.dart';
import '../Globals/ApplicationsGlobals.dart';
import '../Utilities/ApplicationsUtils.dart';
// import '../../Jobs/Edit/EditJob.dart';
import '../../Globals/Globals.dart';
import '../../Themes/Themes.dart';

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
      newApplicationTitle,
      style: TextStyle(
        color: themeTextColor(context),
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

SingleChildScrollView loadContent(BuildContext context, ApplicationContent content, Function state) {
  return SingleChildScrollView(
    child: Center(
      child: Container(
        width: MediaQuery.of(context).size.width * applicationsContainerWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: standardSizedBoxHeight),
            Text(
              'Choose A Job To Apply To',
              style: TextStyle(
                color: themeTextColor(context),
                fontSize: secondaryTitles,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: standardSizedBoxHeight),
            Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.5,
              child: ListView.builder(
                itemCount: content.jobs.length,
                itemBuilder: (context, index) {
                  return StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                      final jobName = content.jobs[index].path.split('/').last;
                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: ListTile(
                          title: Text(jobName),
                          trailing: Checkbox(
                            value: content.checkedProfiles.contains(jobName),
                            onChanged: (bool? value) {
                              content.updateBoxes(content.allProfiles, content.checkedProfiles, jobName, value, setState);
                            },
                          ),
                          onTap: () => {},
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SizedBox(height: standardSizedBoxHeight),
            Text(
              'Choose A Profile To Apply With',
              style: TextStyle(
                color: themeTextColor(context),
                fontSize: secondaryTitles,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: standardSizedBoxHeight),
            Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.5,
              child: ListView.builder(
                itemCount: content.profiles.length,
                itemBuilder: (context, index) {
                  return StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                      final jobName = content.profiles[index].path.split('/').last;
                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: ListTile(
                          title: Text(jobName),
                          trailing: Checkbox(
                            value: content.checkedJobs.contains(jobName),
                            onChanged: (bool? value) {
                              content.updateBoxes(content.allJobs, content.checkedJobs, jobName, value, setState);
                            },
                          ),
                          onTap: () => {},
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

BottomAppBar bottomAppBar(BuildContext context, ApplicationContent content, Function state) {
  return BottomAppBar(
    color: Colors.transparent,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {
            content.clearBoxes(content.checkedJobs, content.checkedProfiles, state);
          },
          child: Text(
            'Clear',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(width: standardSizedBoxWidth),
        ElevatedButton(
          onPressed: () => {
            // bool isValid = content.verifyBoxes();
          },
          child: Text(
            'Generate Application',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(width: standardSizedBoxWidth),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            'Cancel',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}
