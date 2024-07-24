import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../Globals/GlobalContext.dart';
import '../../Applications/Applications.dart';
import '../../Context/Jobs/JobsContext.dart';
import '../../Dashboard/Dashboard.dart';
import '../../Jobs/Jobs.dart';
import '../../Utilities/GlobalUtils.dart';
import '../../Utilities/JobUtils.dart';
import '../../Globals/Globals.dart';

AppBar NewJobAppBar(BuildContext context, bool? backToJobs) {
  return AppBar(
    title: Text(
      'Create New Job',
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
    ),
    leading: IconButton(
      icon: Icon(Icons.arrow_back_ios_new_outlined),
      onPressed: () async {
        await CleanDir('Temp');
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

SingleChildScrollView NewJobContent(BuildContext context, Job job, List<GlobalKey> keys) {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
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

BottomAppBar NewJobBottomAppBar(BuildContext context, Job job, bool? backToJobs) {
  TextEditingController nameController = TextEditingController();
  return BottomAppBar(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
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