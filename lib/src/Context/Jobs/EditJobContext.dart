import 'package:flutter/material.dart';
import '../Globals/GlobalContext.dart';
import '../../Applications/Applications.dart';
import '../../Context/Jobs/JobsContext.dart';
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
  );
}

SingleChildScrollView EditJobContent(BuildContext context, Job job, List<GlobalKey> keys, bool backToJobs) {
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
                SizedBox(height: standardSizedBoxHeight),
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
                )
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
