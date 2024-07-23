import 'package:flutter/material.dart';
import 'package:taylord_portfolio/src/Context/Profiles/ProfileContext.dart';
import '../../Applications/LoadApplication.dart';
import '../../Applications/NewApplication.dart';
import '../../Dashboard/Dashboard.dart';
import '../../Globals/ApplicationsGlobals.dart';
import '../../Globals/Globals.dart';
import '../../Utilities/ApplicationsUtils.dart';
import '../../Utilities/GlobalUtils.dart';
import '../../Utilities/JobUtils.dart';
import '../../Utilities/ProfilesUtils.dart';

AppBar ApplicationsAppBar(BuildContext context) {
  return AppBar(
    title: Text(
      'Applications',
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
    ),
    leading: IconButton(
      icon: Icon(Icons.arrow_back_ios_new_outlined),
      onPressed: () {
        Navigator.pushAndRemoveUntil(context, LeftToRightPageRoute(page: Dashboard()), (Route<dynamic> route) => false);
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

SingleChildScrollView ApplicationsContent(BuildContext context, List<Application> apps, List<Job> jobs, List<Profile> profiles, Function setState) {
  return SingleChildScrollView(
    child: Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          AppsContent(context, apps, setState),
          JobsContent(context, jobs, setState),
          ProfilesContent(context, profiles, setState),
        ],
      ),
    ),
  );
}

SingleChildScrollView AppsContent(BuildContext context, List<Application> apps, Function setState) {
  return SingleChildScrollView(
    child: apps.isNotEmpty
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: standardSizedBoxHeight),
              Text(
                'Previous Applications',
                style: TextStyle(
                  fontSize: secondaryTitles,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: standardSizedBoxHeight),
              ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: 0,
                  maxHeight: MediaQuery.of(context).size.height * 0.40,
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: apps.length,
                    itemBuilder: (context, index) {
                      return Tooltip(
                        message: 'Click To View ${apps[index].applicationName}',
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: ListTile(
                            title: Text(apps[index].applicationName),
                            trailing: Tooltip(
                              message: 'Click To Delete - ${apps[index].applicationName}',
                              child: IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => {},
                              ),
                            ),
                            onTap: () => {},
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          )
        : Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'No Previous Applications',
                  style: TextStyle(
                    fontSize: secondaryTitles,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4 * standardSizedBoxHeight),
                CircularProgressIndicator(),
              ],
            ),
          ),
  );
}

SingleChildScrollView JobsContent(BuildContext context, List<Job> jobs, Function setState) {
  return SingleChildScrollView(
    child: jobs.isNotEmpty
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: standardSizedBoxHeight),
              Text(
                'Previous Jobs',
                style: TextStyle(
                  fontSize: secondaryTitles,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: standardSizedBoxHeight),
              ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: 0,
                  maxHeight: MediaQuery.of(context).size.height * 0.40,
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      return Tooltip(
                        message: 'Click To View ${jobs[index].name}',
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: ListTile(
                            title: Text(jobs[index].name),
                            trailing: Tooltip(
                              message: 'Click To Delete - ${jobs[index].name}',
                              child: IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => {},
                              ),
                            ),
                            onTap: () => {},
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          )
        : Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'No Previous Jobs',
                  style: TextStyle(
                    fontSize: secondaryTitles,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4 * standardSizedBoxHeight),
                CircularProgressIndicator(),
              ],
            ),
          ),
  );
}

SingleChildScrollView ProfilesContent(BuildContext context, List<Profile> profiles, Function setState) {
  return SingleChildScrollView(
    child: profiles.isNotEmpty
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: standardSizedBoxHeight),
              Text(
                'Previous Profiles',
                style: TextStyle(
                  fontSize: secondaryTitles,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: standardSizedBoxHeight),
              ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: 0,
                  maxHeight: MediaQuery.of(context).size.height * 0.40,
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: profiles.length,
                    itemBuilder: (context, index) {
                      return Tooltip(
                        message: 'Click To View ${profiles[index].name}',
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: ListTile(
                            title: Text(profiles[index].name),
                            trailing: Tooltip(
                              message: 'Click To Delete - ${profiles[index].name}',
                              child: IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => {},
                              ),
                            ),
                            onTap: () => {},
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          )
        : Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'No Previous Jobs',
                  style: TextStyle(
                    fontSize: secondaryTitles,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4 * standardSizedBoxHeight),
                CircularProgressIndicator(),
              ],
            ),
          ),
  );
}
