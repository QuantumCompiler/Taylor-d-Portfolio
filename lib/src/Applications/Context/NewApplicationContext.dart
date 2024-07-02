import 'dart:io';
import 'package:flutter/material.dart';
import '../Globals/ApplicationsGlobals.dart';
import '../Utilities/ApplicationsUtils.dart';
// import '../../Jobs/Edit/EditJob.dart';
import '../../Jobs/Utilities/JobUtils.dart';
import '../../Globals/Globals.dart';
// import '../../Profiles/Utilities/ProfilesUtils.dart';
// import '../../Profiles/Edit/EditProfile.dart';
import '../../Themes/Themes.dart';

AppBar appBar(BuildContext context, Function state) {
  return AppBar(
    leading: IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        Navigator.of(context).pop();
        state(() {});
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
                      return Tooltip(
                        message: 'Click To Edit $jobName',
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: ListTile(
                            title: Text(jobName),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Tooltip(
                                  message: 'Select $jobName',
                                  child: Checkbox(
                                    value: content.checkedProfiles.contains(jobName),
                                    onChanged: (bool? value) {
                                      content.updateBoxes(content.allProfiles, content.checkedProfiles, jobName, value, setState);
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text(
                                            "Delete $jobName?",
                                            style: TextStyle(
                                              fontSize: appBarTitle,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          content: Text(
                                            'Are you sure that you would like to delete this job? This cannot be undone.',
                                            style: TextStyle(
                                              fontSize: secondaryTitles,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          actions: <Widget>[
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                ElevatedButton(
                                                  child: Text('Cancel'),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                ),
                                                SizedBox(width: standardSizedBoxWidth),
                                                ElevatedButton(
                                                  child: Text('Delete'),
                                                  onPressed: () async {
                                                    await DeleteJob(jobName);
                                                    print('Actual jobs\n');
                                                    List<Directory> currJobs = await RetrieveSortedJobs();
                                                    for (int i = 0; i < currJobs.length; i++) {
                                                      print(currJobs[i]);
                                                    }
                                                    await content.refreshData();
                                                    print('Updated Jobs\n');
                                                    for (int i = 0; i < content.jobs.length; i++) {
                                                      print(content.jobs[i]);
                                                    }
                                                    Navigator.of(context).pop();
                                                    setState(() {});
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  tooltip: 'Delete $jobName',
                                ),
                              ],
                            ),
                            onTap: () => {},
                          ),
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

// SizedBox(height: standardSizedBoxHeight),
// Text(
//   'Choose A Profile To Apply With',
//   style: TextStyle(
//     color: themeTextColor(context),
//     fontSize: secondaryTitles,
//     fontWeight: FontWeight.bold,
//   ),
// ),
// SizedBox(height: standardSizedBoxHeight),
// Container(
//   width: MediaQuery.of(context).size.width * 0.8,
//   height: MediaQuery.of(context).size.height * 0.5,
//   child: ListView.builder(
//     itemCount: content.profiles.length,
//     itemBuilder: (context, index) {
//       return StatefulBuilder(
//         builder: (BuildContext context, StateSetter setState) {
//           final profileName = content.profiles[index].path.split('/').last;
//           return Tooltip(
//             message: 'Click To Edit $profileName',
//             child: MouseRegion(
//               cursor: SystemMouseCursors.click,
//               child: ListTile(
//                 title: Text(profileName),
//                 trailing: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Tooltip(
//                       message: 'Select $profileName',
//                       child: Checkbox(
//                         value: content.checkedJobs.contains(profileName),
//                         onChanged: (bool? value) {
//                           content.updateBoxes(content.allJobs, content.checkedJobs, profileName, value, setState);
//                         },
//                       ),
//                     ),
//                     IconButton(
//                       icon: Icon(Icons.delete),
//                       onPressed: () {
//                         showDialog(
//                           context: context,
//                           builder: (BuildContext context) {
//                             return AlertDialog(
//                               title: Text(
//                                 "Delete $profileName?",
//                                 style: TextStyle(
//                                   fontSize: appBarTitle,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                                 textAlign: TextAlign.center,
//                               ),
//                               content: Text(
//                                 'Are you sure that you would like to delete this profile? This cannot be undone.',
//                                 style: TextStyle(
//                                   fontSize: secondaryTitles,
//                                 ),
//                                 textAlign: TextAlign.center,
//                               ),
//                               actions: <Widget>[
//                                 Row(
//                                   crossAxisAlignment: CrossAxisAlignment.center,
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     ElevatedButton(
//                                       child: Text('Cancel'),
//                                       onPressed: () {
//                                         Navigator.of(context).pop();
//                                       },
//                                     ),
//                                     SizedBox(width: standardSizedBoxWidth),
//                                     ElevatedButton(
//                                       child: Text('Delete'),
//                                       onPressed: () async {
//                                         await DeleteProfile(profileName);
//                                         Navigator.of(context).pop();
//                                         state(() {});
//                                       },
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             );
//                           },
//                         );
//                       },
//                       tooltip: 'Delete $profileName',
//                     ),
//                   ],
//                 ),
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => EditProfilePage(profileName: profileName),
//                     ),
//                   ).then((_) {
//                     state(() => content.refreshData(setState));
//                   });
//                 },
//               ),
//             ),
//           );
//         },
//       );
//     },
//   ),
// ),