import 'package:flutter/material.dart';
import '../Globals/ApplicationsGlobals.dart';
import '../Utilities/ApplicationsUtils.dart';
import '../Globals/Globals.dart';
import '../Themes/Themes.dart';

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
      'Save New Application',
      style: TextStyle(
        color: themeTextColor(context),
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

SingleChildScrollView loadContent(BuildContext context, ApplicationContent content, Map<String, dynamic> openAIContent, Function state) {
  TextEditingController eduController = TextEditingController();
  TextEditingController expController = TextEditingController();
  TextEditingController projController = TextEditingController();
  TextEditingController mathController = TextEditingController();
  TextEditingController persController = TextEditingController();
  TextEditingController framController = TextEditingController();
  TextEditingController langController = TextEditingController();
  TextEditingController progController = TextEditingController();
  TextEditingController sciController = TextEditingController();

  String joinList(dynamic list) {
    return (list as List<dynamic>).map((e) => e.toString()).join(", ");
  }

  eduController.text = joinList(openAIContent["Education_Recommendations"]);
  expController.text = joinList(openAIContent["Experience_Recommendations"]);
  projController.text = joinList(openAIContent["Projects_Recommendations"]);
  mathController.text = joinList(openAIContent["Math_Skills_Recommendations"]);
  persController.text = joinList(openAIContent["Personal_Skills_Recommendations"]);
  framController.text = joinList(openAIContent["Framework_Recommendations"]);
  langController.text = joinList(openAIContent["Programming_Languages_Recommendations"]);
  progController.text = joinList(openAIContent["Programming_Skills_Recommendations"]);
  sciController.text = joinList(openAIContent["Scientific_Skills_Recommendations"]);
  return SingleChildScrollView(
    child: Center(
      child: Container(
        width: MediaQuery.of(context).size.width * applicationsContainerWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'OpenAI Recommendations',
              style: TextStyle(
                color: themeTextColor(context),
                fontSize: appBarTitle,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: standardSizedBoxHeight),
            // Education Recommendations
            ...openAIEntry(context, 'Education Recommendations', eduController, 'No Recommendations Produced', lines: 3),
            // Experience Recommendations
            ...openAIEntry(context, 'Experience Recommendations', expController, 'No Recommendations Produced', lines: 3),
            // Project Recommendations
            ...openAIEntry(context, 'Project Recommendations', projController, 'No Recommendations Produced', lines: 3),
            // Math Skills Recommendations
            ...openAIEntry(context, 'Math Skills Recommendations', mathController, 'No Recommendations Produced', lines: 5),
            // Personal Skills Recommendations
            ...openAIEntry(context, 'Personal Skills Recommendations', persController, 'No Recommendations Produced', lines: 5),
            // Framework Recommendations
            ...openAIEntry(context, 'Framework Recommendations', framController, 'No Recommendations Produced', lines: 5),
            // Programming Language Recommendations
            ...openAIEntry(context, 'Programming Language Recommendations', langController, 'No Recommendations Produced', lines: 5),
            // Programming Skills Recommendations
            ...openAIEntry(context, 'Programming Skills Recommendations', progController, 'No Recommendations Produced', lines: 5),
            // Scientific Skills Recommendations
            ...openAIEntry(context, 'Scientific Skills Recommendations', sciController, 'No Recommendations Produced', lines: 5),
            SizedBox(height: standardSizedBoxHeight),
          ],
        ),
      ),
    ),
  );
}
