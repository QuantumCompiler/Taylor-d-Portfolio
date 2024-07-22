import 'package:flutter/material.dart';
import '../../Dashboard/Dashboard.dart';
import '../../Globals/Globals.dart';
import '../../Jobs/JobContent.dart';
import '../../Jobs/NewJob.dart';
import '../../Utilities/GlobalUtils.dart';
import '../../Utilities/JobUtils.dart';

AppBar JobsAppBar(BuildContext context, List<Job> jobs) {
  return AppBar(
    title: Text(
      jobs.isNotEmpty ? "Jobs, Edit Or Create New" : "Jobs, Create New",
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

SingleChildScrollView JobContent(BuildContext context, List<Job> jobs, Function setState) {
  return SingleChildScrollView(
    child: jobs.isNotEmpty
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: standardSizedBoxHeight),
              Center(
                child: Text(
                  'View / Edit Previous Jobs',
                  style: TextStyle(
                    fontSize: secondaryTitles,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: standardSizedBoxHeight),
              ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: 0,
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width * titleContainerWidth,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      return Tooltip(
                        message: 'Click To Edit ${jobs[index].name}',
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: ListTile(
                            title: Text(jobs[index].name),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Tooltip(
                                  message: 'Delete Job ${jobs[index].name}',
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      size: 30.0,
                                    ),
                                    onPressed: () async {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            content: Column(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Delete Job ${jobs[index].name}?',
                                                  style: TextStyle(
                                                    fontSize: appBarTitle,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(height: standardSizedBoxHeight),
                                                Icon(
                                                  Icons.warning,
                                                  size: 50.0,
                                                ),
                                                SizedBox(height: standardSizedBoxHeight),
                                                Text(
                                                  'Are you sure that you would like to delete this job?\nThis cannot be undone.',
                                                ),
                                                SizedBox(height: standardSizedBoxHeight),
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    ElevatedButton(
                                                      child: Text(
                                                        'Cancel',
                                                      ),
                                                      onPressed: () {
                                                        Navigator.of(context).pop();
                                                      },
                                                    ),
                                                    SizedBox(width: standardSizedBoxWidth),
                                                    ElevatedButton(
                                                      child: Text('Delete'),
                                                      onPressed: () async {
                                                        try {
                                                          await DeleteJob(jobs[index].name);
                                                          setState(
                                                            () {
                                                              jobs.removeAt(index);
                                                            },
                                                          );
                                                          Navigator.of(context).pop();
                                                        } catch (e) {
                                                          throw ('Error in deleting ${jobs[index].name}');
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              // Navigator.pushAndRemoveUntil(context, RightToLeftPageRoute(page: EditJob(profileName: jobs[index].name)), (Route<dynamic> route) => false);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: standardSizedBoxHeight),
              Center(
                child: Tooltip(
                  message: 'Create New Job',
                  child: IconButton(
                    icon: Icon(Icons.add_circle_outline_rounded),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(context, RightToLeftPageRoute(page: NewJobPage()), (Route<dynamic> route) => false);
                    },
                  ),
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Text(
                  'No Current Jobs',
                  style: TextStyle(
                    fontSize: secondaryTitles,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 4 * standardSizedBoxHeight),
              Center(
                child: CircularProgressIndicator(),
              ),
              SizedBox(height: 4 * standardSizedBoxHeight),
              Center(
                child: Tooltip(
                  message: 'Create A New Job',
                  child: IconButton(
                    icon: Icon(Icons.add_circle_outline_rounded),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(context, RightToLeftPageRoute(page: NewJobPage()), (Route<dynamic> route) => false);
                    },
                  ),
                ),
              ),
            ],
          ),
  );
}

List<Widget> JobOptionsContent(BuildContext context, Job job, List<GlobalKey> keys) {
  List<Widget> ret = [];
  ListTile DescriptionTile = ListTile(
    title: Text('Job Description'),
    onTap: () async {
      await Navigator.push(context, MaterialPageRoute(builder: (context) => JobContentPage(job: job, title: 'Job Description Entry', type: JobContentType.description, keyList: keys)));
    },
  );
  ListTile OtherInfoTile = ListTile(
    title: Text('Other Information'),
    onTap: () async {
      await Navigator.push(context, MaterialPageRoute(builder: (context) => JobContentPage(job: job, title: 'Other Information Entry', type: JobContentType.other, keyList: keys)));
    },
  );
  ListTile RoleInfoTile = ListTile(
    title: Text('Role Information'),
    onTap: () async {
      await Navigator.push(context, MaterialPageRoute(builder: (context) => JobContentPage(job: job, title: 'Role Information Entry', type: JobContentType.role, keyList: keys)));
    },
  );
  ret.add(DescriptionTile);
  ret.add(OtherInfoTile);
  ret.add(RoleInfoTile);
  return ret;
}
