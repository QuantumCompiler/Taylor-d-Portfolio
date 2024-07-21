import 'package:flutter/material.dart';
import '../../Jobs/EditJob.dart';
import '../../Globals/JobsGlobals.dart';
import '../../Utilities/JobUtils.dart';
import '../../Globals/Globals.dart';

/*  appBar - AppBar for the load jobs page
      Input:
        context - BuildContext for the page
        jobs - List of jobs to display
        state - Function to set the state of the page
      Algorithm:
        * Create icons with actions for the app bar
        * Modify the behavior of the icons based on the platform
        * Create the app bar with the title
      Output:
        Returns an AppBar for the load jobs page
*/
AppBar appBar(BuildContext context, final jobs, Function state) {
  return AppBar(
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_outlined),
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
          } else if (isMobile()) {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          }
        },
      ),
    ],
    title: Text(
      jobs.isEmpty ? noJobsTitle : loadJobsTitle,
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

/*  loadingJobsAppBar - AppBar for the load jobs page when loading
      Input:
        context - BuildContext for the page
      Algorithm:
        * Create an icon with an action for the app bar
        * Modify the behavior of the icon based on the platform
        * Create the app bar with the title
      Output:
        Returns an AppBar for the load jobs page when loading
*/
AppBar loadingJobsAppBar(BuildContext context) {
  return AppBar(
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_outlined),
      onPressed: () => Navigator.of(context).pop(),
    ),
    title: Text(loadingJobsTitle),
  );
}

/*  loadJobsContent - Content for the load jobs page
      Input:
        context - BuildContext for the page
        jobs - List of jobs to display
        state - Function to set the state of the page
      Algorithm:
        * Create a container with a list of jobs
        * Create a list view with the jobs
        * Create a list tile for each job
        * Create a mouse region for each list tile
        * Create a list tile with a title and delete icon
        * Create an on tap function for the list tile
      Output:
        Returns a container with a list of jobs for the load jobs page
*/
Center loadJobsContent(BuildContext context, final jobs, Function state) {
  return Center(
    child: Container(
      width: MediaQuery.of(context).size.width * jobTileContainerWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: standardSizedBoxHeight),
          Expanded(
            child: ListView.builder(
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: ListTile(
                    title: Text(jobs[index].path.split('/').last),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text(
                                "$delete ${jobs[index].path.split('/').last}?",
                                style: TextStyle(
                                  fontSize: appBarTitle,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              content: Text(
                                deleteJobPrompt,
                                style: TextStyle(
                                  fontSize: secondaryTitles,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              actions: <Widget>[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton(
                                      child: Text(cancelButton),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    SizedBox(width: standardSizedBoxWidth),
                                    ElevatedButton(
                                      child: Text(deleteButton),
                                      onPressed: () async {
                                        await DeleteJob(jobs[index].path.split('/').last);
                                        Navigator.of(context).pop();
                                        state(() {});
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditJobPage(jobName: jobs[index].path.split('/').last),
                        ),
                      ).then(
                        (_) {
                          state(() {});
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

/*  loadingJobsContent - Content for the load jobs page when loading
      Input:
        None
      Algorithm:
        * Create a circular progress indicator
      Output:
        Returns a circular progress indicator for the load jobs page when loading
*/
Center loadingJobsContent() {
  return const Center(child: CircularProgressIndicator());
}
