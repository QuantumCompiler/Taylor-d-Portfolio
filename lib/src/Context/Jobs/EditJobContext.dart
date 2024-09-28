import 'package:flutter/material.dart';
import '../Globals/GlobalContext.dart';
import '../../Applications/Applications.dart';
import '../../Context/Jobs/JobsContext.dart';
import '../../Dashboard/Dashboard.dart';
import '../../Settings/Settings.dart';
import '../../Globals/Globals.dart';
import '../../Utilities/JobUtils.dart';

AppBar EditJobAppBar(BuildContext context, String jobName, bool backToJobs) {
  return AppBar(
    title: Text(
      'Edit Job $jobName',
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
    ),
    leading: NavToPage(context, 'Applications', Icon(Icons.arrow_back_ios_new_outlined), ApplicationsPage(), false, false),
    actions: [
      Row(
        children: [
          NavToPage(context, 'Settings', Icon(Icons.settings), SettingsPage(), true, false),
          NavToPage(context, 'Dashboard', Icon(Icons.dashboard), Dashboard(), true, false),
        ],
      ),
    ],
  );
}

SingleChildScrollView EditJobContent(BuildContext context, Job job, List<GlobalKey> keys) {
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
                ...JobOptionsContent(context, job, keys, false),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

BottomAppBar EditJobBottomAppBar(BuildContext context, Job job, bool? backToJobs, List<GlobalKey> keyList) {
  return BottomAppBar(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          child: Text('Overwrite Job'),
          onPressed: () async {
            await showDialog(
              context: context,
              builder: (context) {
                return EditJobDialog(context, job, backToJobs);
              },
            );
          },
        ),
      ],
    ),
  );
}
