import 'package:flutter/material.dart';
import '../Globals/GlobalContext.dart';
import '../../Applications/Applications.dart';
import '../../Context/Jobs/JobsContext.dart';
import '../../Dashboard/Dashboard.dart';
import '../../Globals/Globals.dart';
import '../../Jobs/Jobs.dart';
import '../../Utilities/GlobalUtils.dart';
import '../../Utilities/JobUtils.dart';

AppBar EditJobAppBar(BuildContext context, String jobName, bool? backToJobs) {
  return AppBar(
    title: Text(
      'Edit Job $jobName',
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
    ),
    leading: IconButton(
      icon: Icon(Icons.arrow_back_ios_new_outlined),
      onPressed: () {
        if (backToJobs == true) {
          Navigator.pushAndRemoveUntil(context, LeftToRightPageRoute(page: JobsPage()), (Route<dynamic> route) => false);
        } else if (backToJobs == false) {
          Navigator.pushAndRemoveUntil(context, LeftToRightPageRoute(page: ApplicationsPage()), (Route<dynamic> route) => false);
        }
      },
    ),
    actions: [
      Row(
        children: [
          IconButton(
            icon: Icon(Icons.dashboard),
            onPressed: () {
              Navigator.pushAndRemoveUntil(context, LeftToRightPageRoute(page: Dashboard()), (Route<dynamic> route) => false);
            },
          ),
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
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: standardSizedBoxHeight),
                ...JobOptionsContent(context, job, keys),
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
        ElevatedButton(
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