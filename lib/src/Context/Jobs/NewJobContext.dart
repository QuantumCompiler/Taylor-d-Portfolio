import 'package:flutter/material.dart';
import '../Globals/GlobalContext.dart';
import '../../Applications/Applications.dart';
import '../../Context/Jobs/JobsContext.dart';
import '../../Utilities/JobUtils.dart';
import '../../Globals/Globals.dart';

AppBar NewJobAppBar(BuildContext context, bool backToJobs) {
  return AppBar(
    title: Text(
      'Create New Job',
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
    ),
    leading: NavToPage(context, 'Applications', Icon(Icons.arrow_back_ios_new_outlined), ApplicationsPage(), false, true),
  );
}

SingleChildScrollView NewJobContent(BuildContext context, Job job, List<GlobalKey> keys, bool? backToJobs) {
  TextEditingController nameController = TextEditingController();
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              children: [
                SizedBox(height: standardSizedBoxHeight),
                ...JobOptionsContent(context, job, keys, false),
                SizedBox(height: standardSizedBoxHeight),
                TextButton(
                  child: Text('Save Job'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return NewJobDialog(context, job, backToJobs, nameController);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

BottomAppBar NewJobBottomAppBar(BuildContext context, Job job, bool? backToJobs) {
  TextEditingController nameController = TextEditingController();
  return BottomAppBar(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          child: Text('Save Job'),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                return NewJobDialog(context, job, backToJobs, nameController);
              },
            );
          },
        ),
      ],
    ),
  );
}
