import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../Globals/GlobalContext.dart';
import '../../Applications/Applications.dart';
import '../../Dashboard/Dashboard.dart';
// import '../../Applications/SaveNewApplication.dart';
import '../../Globals/ApplicationsGlobals.dart';
// import '../../Utilities/ApplicationsUtils.dart';
import '../../Globals/Globals.dart';
import '../../Jobs/Jobs.dart';
import '../../Profiles/Profiles.dart';
import '../../Settings/Settings.dart';

AppBar NewApplicationAppBar(BuildContext context) {
  return AppBar(
    title: Text(
      'New Application',
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    ),
    leading: NavToPage(context, 'Applications', Icon(Icons.arrow_back_ios_new_outlined), ApplicationsPage(), false, false),
    actions: [
      Row(
        children: [
          NavToPage(context, 'Jobs', Icon(Icons.work), JobsPage(), true, false),
          NavToPage(context, 'Profiles', Icon(Icons.person), ProfilePage(), true, false),
          NavToPage(context, 'Settings', Icon(Icons.settings), SettingsPage(), true, false),
          NavToPage(context, 'Dashboard', Icon(Icons.dashboard), Dashboard(), true, false),
        ],
      ),
    ],
  );
}

SingleChildScrollView NewApplicationContent(BuildContext context, List<DropdownMenuEntry> menuEntries) {
  String openAIModel = gpt_4o;
  return SingleChildScrollView(
    child: Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 4 * standardSizedBoxHeight),
          DropdownMenu(
            dropdownMenuEntries: menuEntries,
            enableFilter: true,
            width: MediaQuery.of(context).size.width * 0.4,
            menuHeight: MediaQuery.of(context).size.height * 0.4,
            helperText: 'Select Model For OpenAI',
            onSelected: (value) {
              openAIModel = value.toString();
            },
          ),
          SizedBox(height: 4 * standardSizedBoxHeight),
          ElevatedButton(
            child: Text('Create Portfolio'),
            onPressed: () {
              if (kDebugMode) {
                print('Model that was selected: $openAIModel');
              }
              // Prep for OpenAI call here!!!!!!
            },
          ),
        ],
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

// BottomAppBar bottomAppBar(BuildContext context, ApplicationContent content, Function state) {
//   return BottomAppBar(
//     color: Colors.transparent,
//     child: Row(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         ElevatedButton(
//           onPressed: () {
//             content.clearBoxes(content.checkedJobs, content.checkedProfiles, state);
//           },
//           child: Text(
//             'Clear',
//             style: TextStyle(fontWeight: FontWeight.bold),
//           ),
//         ),
//         SizedBox(width: standardSizedBoxWidth),
//         ElevatedButton(
//           onPressed: () async {
//             bool valid = content.verifyBoxes();
//             if (valid) {
//               // Map<String, dynamic> openAIRecs = testOpenAIResults;
//               Map<String, dynamic> openAIRecs = await getOpenAIRecs(context, content);
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => SaveNewApplicationPage(
//                     openAIContent: openAIRecs,
//                     appContent: content,
//                   ),
//                 ),
//               );
//             }
//           },
//           child: Text(
//             'Generate Application',
//             style: TextStyle(fontWeight: FontWeight.bold),
//           ),
//         ),
//         SizedBox(width: standardSizedBoxWidth),
//         ElevatedButton(
//           onPressed: () {
//             Navigator.of(context).pop();
//           },
//           child: Text(
//             'Cancel',
//             style: TextStyle(fontWeight: FontWeight.bold),
//           ),
//         ),
//       ],
//     ),
//   );
// }
