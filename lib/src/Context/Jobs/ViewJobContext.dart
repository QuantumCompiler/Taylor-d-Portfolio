import 'package:flutter/material.dart';
import '../Globals/GlobalContext.dart';
import '../../Utilities/ApplicationsUtils.dart';
import '../../Applications/ViewApplication.dart';
import '../../Context/Jobs/JobsContext.dart';
import '../../Globals/Globals.dart';
import '../../Utilities/JobUtils.dart';

AppBar ViewJobAppBar(BuildContext context, String jobName, Application app) {
  return AppBar(
    title: Text(
      'View Content For $jobName',
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
    ),
    leading: NavToPage(context, app.name, Icon(Icons.arrow_back_ios_new_outlined), ViewApplicationPage(app: app), false, true),
  );
}

SingleChildScrollView ViewJobContent(BuildContext context, Job job, List<GlobalKey> keys) {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: standardSizedBoxHeight),
                ...JobOptionsContent(context, job, keys, true),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
