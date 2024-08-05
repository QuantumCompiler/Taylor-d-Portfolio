import 'package:flutter/material.dart';
import '../Globals/GlobalContext.dart';
import '../../Applications/Applications.dart';
import '../../Dashboard/Dashboard.dart';
// import '../../Applications/SaveNewApplication.dart';
import '../../Globals/ApplicationsGlobals.dart';
import '../../Globals/Globals.dart';
import '../../Jobs/Jobs.dart';
import '../../Profiles/Profiles.dart';
import '../../Settings/Settings.dart';
import '../../Utilities/ApplicationsUtils.dart';

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
    leading: NavToPage(context, 'Applications', Icon(Icons.arrow_back_ios_new_outlined), ApplicationsPage(), false, true),
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

SingleChildScrollView NewApplicationContent(BuildContext context, Application app, Function updateState) {
  String openAIModel = gpt_4o;
  return SingleChildScrollView(
    child: Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 4 * standardSizedBoxHeight),
          DropdownMenu(
            dropdownMenuEntries: openAIEntries,
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
            onPressed: () async {
              // Map<String, dynamic> recs = await GetOpenAIRecs(context, app, openAIModel);
              Map<String, dynamic> recs = testOpenAIResults;
              List<String> finRecs = await StringifyRecs(recs, app);
              app.SetRecs(recs, finRecs);
              updateState();
            },
          ),
        ],
      ),
    ),
  );
}

SingleChildScrollView NewApplicationRecsContent(BuildContext context, Application app, Function updateState) {
  return SingleChildScrollView(
    child: Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: standardSizedBoxHeight),
          Text(
            'OpenAI Recommendations',
            style: TextStyle(
              fontSize: appBarTitle,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: standardSizedBoxHeight),
          ElevatedButton(
            child: Text('Compile Portfolio'),
            onPressed: () async {
              updateState();
            },
          ),
        ],
      ),
    ),
  );
}

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
