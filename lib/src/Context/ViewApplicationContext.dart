import 'package:flutter/material.dart';
// import '../Globals/ApplicationsGlobals.dart';
import '../Utilities/ApplicationsUtils.dart';
import '../Globals/Globals.dart';

AppBar appBar(BuildContext context, Application prevApp) {
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
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          }
        },
      )
    ],
    title: Text(
      prevApp.applicationName,
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

SingleChildScrollView loadAppContent(BuildContext context, Application prevApp) {
  return SingleChildScrollView(
    child: Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: standardSizedBoxHeight),
          recCont(context, 'Education Recommendations', prevApp.eduRecFile.readAsStringSync()),
          recCont(context, 'Experience Recommendations', prevApp.expRecFile.readAsStringSync()),
          recCont(context, 'Project Recommendations', prevApp.projRecFile.readAsStringSync()),
          recCont(context, 'Math Skills Recommendations', prevApp.mathRecFile.readAsStringSync()),
          recCont(context, 'Personal Skills Recommendations', prevApp.persRecFile.readAsStringSync()),
          recCont(context, 'Framework Recommendations', prevApp.framRecFile.readAsStringSync()),
          recCont(context, 'Programming Languages Recommendations', prevApp.langRecFile.readAsStringSync()),
          recCont(context, 'Programming Skills Recommendations', prevApp.progRecFile.readAsStringSync()),
          recCont(context, 'Scientific Skills Recommendations', prevApp.sciRecFile.readAsStringSync()),
        ],
      ),
    ),
  );
}

Center recCont(BuildContext context, String title, String content) {
  return Center(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: secondaryTitles,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: standardSizedBoxHeight),
        Container(
          width: MediaQuery.of(context).size.width * 0.75,
          child: Text(content),
        ),
        SizedBox(height: standardSizedBoxHeight),
      ],
    ),
  );
}
