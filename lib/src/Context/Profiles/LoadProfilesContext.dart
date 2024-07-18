import 'package:flutter/material.dart';
import '../Globals/GlobalContext.dart';
import '../../Globals/Globals.dart';
import '../../Profiles/EditProfile.dart';
import '../../Utilities/GlobalUtils.dart';

Widget LoadProfileContent(BuildContext context, dynamic profiles, Function setState) {
  return Center(
    child: Container(
      width: MediaQuery.of(context).size.width * titleContainerWidth,
      child: ListView.builder(
        itemCount: profiles.length,
        itemBuilder: (context, index) {
          return Tooltip(
            message: 'Click To Edit ${profiles[index].name}',
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GenListTileWithDelFunc(
                context,
                '${profiles[index].name}',
                profiles[index],
                () => GenAlertDialogWithFunctions(
                  'Delete ${profiles[index].name}?',
                  'Do you want to delete ${profiles[index].name}?\n This cannot be undone.',
                  'Cancel',
                  'Delete',
                  () => {},
                  () async {
                    await DeleteProfile('${profiles[index].name}');
                    setState(() {
                      profiles.removeAt(index);
                    });
                    Navigator.pop(context);
                  },
                  setState,
                ),
                (context, profile) async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfilePage(profileName: profiles[index].name),
                    ),
                  ).then((_) {
                    setState(() {});
                  });
                },
                setState,
              ),
            ),
          );
        },
      ),
    ),
  );
}

// SingleChildScrollView loadApplicationContent(BuildContext context, ApplicationContent content, Function state) {
//   return SingleChildScrollView(
//     child: Center(
//       child: Container(
//         width: MediaQuery.of(context).size.width * applicationsContainerWidth,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             SizedBox(height: standardSizedBoxHeight),
//             Text(
//               'Choose A Job To Apply To',
//               style: TextStyle(
//                 color: themeTextColor(context),
//                 fontSize: secondaryTitles,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             SizedBox(height: standardSizedBoxHeight),
//             Container(
//               width: MediaQuery.of(context).size.width * applicationsContainerWidth,
//               height: MediaQuery.of(context).size.height * 0.5,
//               child: ListView.builder(
//                 itemCount: content.jobs.length,
//                 itemBuilder: (context, index) {
//                   return StatefulBuilder(
//                     builder: (BuildContext context, StateSetter setState) {
//                       return Tooltip(
//                         message: 'Click To Edit ${content.jobs[index].path.split('/').last}',
//                         child: MouseRegion(
//                           cursor: SystemMouseCursors.click,
//                           child: ListTile(
//                             title: Text(content.jobs[index].path.split('/').last),
//                             trailing: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Tooltip(
//                                   message: 'Select ${content.jobs[index].path.split('/').last}',
//                                   child: Checkbox(
//                                     value: content.checkedJobs.contains(content.jobs[index].path.split('/').last),
//                                     onChanged: (bool? value) {
//                                       content.updateBoxes(content.checkedJobs, content.jobs[index].path.split('/').last, value, setState);
//                                     },
//                                   ),
//                                 ),
//                                 Tooltip(
//                                   message: 'Delete ${content.jobs[index].path.split('/').last}',
//                                   child: IconButton(
//                                     icon: Icon(Icons.delete),
//                                     onPressed: () async {
//                                       // await DeleteJob(content.jobs[index].path.split('/').last);
//                                       state(() {});
//                                     },
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => EditJobPage(jobName: content.jobs[index].path.split('/').last),
//                                 ),
//                               ).then(
//                                 (_) {
//                                   state(() {});
//                                 },
//                               );
//                             },
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 },
//               ),
//             ),
//             SizedBox(height: standardSizedBoxHeight),
//             Text(
//               'Choose A Profile To Apply With',
//               style: TextStyle(
//                 color: themeTextColor(context),
//                 fontSize: secondaryTitles,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             SizedBox(height: standardSizedBoxHeight),
//             Container(
//               width: MediaQuery.of(context).size.width * applicationsContainerWidth,
//               height: MediaQuery.of(context).size.height * 0.5,
//               child: ListView.builder(
//                 itemCount: content.profiles.length,
//                 itemBuilder: (context, index) {
//                   return StatefulBuilder(
//                     builder: (BuildContext context, StateSetter setState) {
//                       return Tooltip(
//                         message: 'Click To Edit ${content.profiles[index].path.split('/').last}',
//                         child: MouseRegion(
//                           cursor: SystemMouseCursors.click,
//                           child: ListTile(
//                             title: Text(content.profiles[index].path.split('/').last),
//                             trailing: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Tooltip(
//                                   message: 'Select ${content.profiles[index].path.split('/').last}',
//                                   child: Checkbox(
//                                     value: content.checkedProfiles.contains(content.profiles[index].path.split('/').last),
//                                     onChanged: (bool? value) {
//                                       content.updateBoxes(content.checkedProfiles, content.profiles[index].path.split('/').last, value, setState);
//                                     },
//                                   ),
//                                 ),
//                                 Tooltip(
//                                   message: 'Delete ${content.profiles[index].path.split('/').last}',
//                                   child: IconButton(
//                                     icon: Icon(Icons.delete),
//                                     onPressed: () async {
//                                       // await DeleteProfile(content.profiles[index].path.split('/').last);
//                                       state(() {});
//                                     },
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             onTap: () {
//                               // Navigator.push(
//                               //   context,
//                               //   MaterialPageRoute(
//                               //     builder: (context) => EditProfilePage(profileName: content.profiles[index].path.split('/').last),
//                               //   ),
//                               // ).then(
//                               //   (_) {
//                               //     state(() {});
//                               //   },
//                               // );
//                             },
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     ),
//   );
// }