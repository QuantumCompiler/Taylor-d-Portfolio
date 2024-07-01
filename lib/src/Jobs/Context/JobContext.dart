import 'package:flutter/material.dart';
import '../Globals/JobsGlobals.dart';
import '../Load/LoadJob.dart';
import '../New/NewJob.dart';
import '../../Globals/Globals.dart';

/*  appBar - AppBar for the jobs page
      Constructor:
        Input:
          context: BuildContext
        Algorithm:
            * Return AppBar with title and back button
      Output:
          Returns an AppBar
*/
AppBar appBar(BuildContext context) {
  return AppBar(
    leading: IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        if (isDesktop()) {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        } else if (isMobile()) {
          Navigator.of(context).pop();
        }
      },
    ),
    title: Text(
      jobsTitle,
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

/*  jobsContent - Body content for the jobs page
      Input:
        context: BuildContext
      Algorithm:
          * Return a center widget with a container for the jobs
          * Populate the container with a column of job options
      Output:
          Returns a Center widget with a container for the jobs
*/
Center jobsContent(BuildContext context) {
  return Center(
    child: Container(
      width: MediaQuery.of(context).size.width * jobTileContainerWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: standardSizedBoxHeight),
          ListTile(
            title: Text(
              createNewJob,
            ),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => NewJobPage()));
            },
          ),
          ListTile(
            title: Text(
              loadJobs,
            ),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => LoadJobPage()));
            },
          ),
        ],
      ),
    ),
  );
}
