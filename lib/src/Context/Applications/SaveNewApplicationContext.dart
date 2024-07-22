// import 'package:flutter/material.dart';
// import '../../Globals/ApplicationsGlobals.dart';
// import '../../Utilities/ApplicationsUtils.dart';
// import '../../Globals/Globals.dart';
// import '../../Themes/Themes.dart';

// AppBar appBar(BuildContext context, ApplicationContent content, Function state) {
//   return AppBar(
//     leading: IconButton(
//       icon: Icon(Icons.arrow_back_ios_new_outlined),
//       onPressed: () {
//         Navigator.of(context).pop();
//         state(() {});
//       },
//     ),
//     actions: <Widget>[
//       IconButton(
//         icon: Icon(Icons.dashboard),
//         onPressed: () {
//           if (isDesktop()) {
//             Navigator.of(context).pop();
//             Navigator.of(context).pop();
//             Navigator.of(context).pop();
//             Navigator.of(context).pop();
//           } else if (isMobile()) {
//             Navigator.of(context).pop();
//             Navigator.of(context).pop();
//             Navigator.of(context).pop();
//           }
//         },
//       ),
//     ],
//     title: Text(
//       content.checkedJobs[0].toString(),
//       style: TextStyle(
//         color: themeTextColor(context),
//         fontSize: appBarTitle,
//         fontWeight: FontWeight.bold,
//       ),
//     ),
//   );
// }

// SingleChildScrollView loadContent(BuildContext context, ApplicationContent content, List<TextEditingController> controllers, Function state) {
//   return SingleChildScrollView(
//     child: Center(
//       child: Container(
//         width: MediaQuery.of(context).size.width * applicationsContainerWidth,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               'OpenAI Recommendations',
//               style: TextStyle(
//                 color: themeTextColor(context),
//                 fontSize: appBarTitle,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             SizedBox(height: standardSizedBoxHeight),
//             // Education Recommendations
//             ...openAIEntry(context, 'Education Recommendations', controllers[0], 'No Recommendations Produced', lines: 3),
//             // Experience Recommendations
//             ...openAIEntry(context, 'Experience Recommendations', controllers[1], 'No Recommendations Produced', lines: 3),
//             // Project Recommendations
//             ...openAIEntry(context, 'Project Recommendations', controllers[2], 'No Recommendations Produced', lines: 3),
//             // Math Skills Recommendations
//             ...openAIEntry(context, 'Math Skills Recommendations', controllers[3], 'No Recommendations Produced', lines: 5),
//             // Personal Skills Recommendations
//             ...openAIEntry(context, 'Personal Skills Recommendations', controllers[4], 'No Recommendations Produced', lines: 5),
//             // Framework Recommendations
//             ...openAIEntry(context, 'Framework Recommendations', controllers[5], 'No Recommendations Produced', lines: 5),
//             // Programming Language Recommendations
//             ...openAIEntry(context, 'Programming Language Recommendations', controllers[6], 'No Recommendations Produced', lines: 5),
//             // Programming Skills Recommendations
//             ...openAIEntry(context, 'Programming Skills Recommendations', controllers[7], 'No Recommendations Produced', lines: 5),
//             // Scientific Skills Recommendations
//             ...openAIEntry(context, 'Scientific Skills Recommendations', controllers[8], 'No Recommendations Produced', lines: 5),
//             SizedBox(height: standardSizedBoxHeight),
//           ],
//         ),
//       ),
//     ),
//   );
// }

// BottomAppBar bottomAppBar(BuildContext context, ApplicationContent content, List<TextEditingController> controllers) {
//   return BottomAppBar(
//     child: Row(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         ElevatedButton(
//           onPressed: () async {
//             await compilePortfolio(context, controllers);
//             await CreateNewApplication(content, controllers);
//           },
//           child: Text(
//             'Generate Portfolio',
//           ),
//         ),
//         SizedBox(width: standardSizedBoxWidth),
//         ElevatedButton(
//           onPressed: () {
//             Navigator.of(context).pop();
//           },
//           child: Text(
//             'Cancel',
//           ),
//         ),
//       ],
//     ),
//   );
// }
