import 'package:flutter/material.dart';
// import '../../Applications/LoadApplication.dart';
// import '../../Applications/NewApplication.dart';
// import '../../Globals/ApplicationsGlobals.dart';
import '../../Context/Globals/GlobalContext.dart';
import '../../Dashboard/Dashboard.dart';
import '../../Globals/Globals.dart';
import '../../Jobs/EditJob.dart';
import '../../Jobs/NewJob.dart';
import '../../Profiles/EditProfile.dart';
import '../../Profiles/NewProfile.dart';
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
          Apps(apps: apps),
          Jobs(jobs: jobs),
          Profiles(profiles: profiles),
        ],
      ),
    ),
  );
}

BottomAppBar ApplicationsBottomAppBar(BuildContext context, List<Job> jobs, List<Profile> profiles) {
  return BottomAppBar(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          child: Text('Create New Application'),
          onPressed: () {
            bool jobsValid = false;
            bool profilesValid = false;
            for (int i = 0; i < profiles.length; i++) {
              if (profiles[i].isSelected == true) {
                profilesValid = true;
                break;
              }
            }
            for (int i = 0; i < jobs.length; i++) {
              if (jobs[i].isSelected == true) {
                jobsValid = true;
              }
            }
          },
        )
      ],
    ),
  );
}

class Apps extends StatefulWidget {
  final List<Application> apps;
  const Apps({super.key, required this.apps});
  @override
  _AppsState createState() => _AppsState();
}

class _AppsState extends State<Apps> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: widget.apps.isNotEmpty
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
                      itemCount: widget.apps.length,
                      itemBuilder: (context, index) {
                        return StatefulBuilder(
                          builder: (BuildContext context, StateSetter setState) {
                            return Tooltip(
                              message: 'Click To View ${widget.apps[index].name}',
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: ListTile(
                                  title: Text(widget.apps[index].name),
                                  trailing: Tooltip(
                                    message: 'Click To Delete - ${widget.apps[index].name}',
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
}

class Jobs extends StatefulWidget {
  final List<Job> jobs;
  const Jobs({super.key, required this.jobs});

  @override
  _JobsState createState() => _JobsState();
}

class _JobsState extends State<Jobs> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: widget.jobs.isNotEmpty
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
                      itemCount: widget.jobs.length,
                      itemBuilder: (context, index) {
                        return Tooltip(
                          message: 'Click To Edit ${widget.jobs[index].name}',
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: ListTile(
                              title: Text(widget.jobs[index].name),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Tooltip(
                                    message: 'Click To Select ${widget.jobs[index].name} For Application',
                                    child: Checkbox(
                                      value: widget.jobs[index].isSelected,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          for (int i = 0; i < widget.jobs.length; i++) {
                                            if (i == index) {
                                              widget.jobs[i].isSelected = value!;
                                            } else {
                                              widget.jobs[i].isSelected = false;
                                            }
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                  Tooltip(
                                    message: 'Click To Delete - ${widget.jobs[index].name}',
                                    child: IconButton(
                                      icon: Icon(Icons.delete),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return DeleteJobDialog(context, widget.jobs, index, setState);
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  RightToLeftPageRoute(
                                    page: EditJobPage(
                                      jobName: widget.jobs[index].name,
                                      backToJobs: false,
                                    ),
                                  ),
                                  (Route<dynamic> route) => false,
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: standardSizedBoxHeight),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Tooltip(
                      message: 'Create A New Job',
                      child: IconButton(
                        icon: Icon(Icons.add_circle_outline_rounded),
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(context, RightToLeftPageRoute(page: NewJobPage(backToJobs: false)), (Route<dynamic> route) => false);
                        },
                      ),
                    ),
                    Tooltip(
                      message: 'Clear Selection For Jobs',
                      child: IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          for (int i = 0; i < widget.jobs.length; i++) {
                            setState(() {
                              widget.jobs[i].isSelected = false;
                            });
                          }
                        },
                      ),
                    )
                  ],
                ),
              ],
            )
          : Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 4 * standardSizedBoxHeight),
                  Text(
                    'No Previous Jobs',
                    style: TextStyle(
                      fontSize: secondaryTitles,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4 * standardSizedBoxHeight),
                  CircularProgressIndicator(),
                  SizedBox(height: 4 * standardSizedBoxHeight),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Tooltip(
                        message: 'Create A New Job',
                        child: IconButton(
                          icon: Icon(Icons.add_circle_outline_rounded),
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(context, RightToLeftPageRoute(page: NewJobPage(backToJobs: false)), (Route<dynamic> route) => false);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class Profiles extends StatefulWidget {
  final List<Profile> profiles;
  const Profiles({super.key, required this.profiles});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profiles> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: widget.profiles.isNotEmpty
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
                      itemCount: widget.profiles.length,
                      itemBuilder: (context, index) {
                        return StatefulBuilder(
                          builder: (BuildContext context, StateSetter setState) {
                            return Tooltip(
                              message: 'Click To View ${widget.profiles[index].name}',
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: ListTile(
                                  title: Text(widget.profiles[index].name),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Tooltip(
                                        message: 'Click To Select ${widget.profiles[index].name} For Application',
                                        child: Checkbox(
                                          value: widget.profiles[index].isSelected,
                                          onChanged: (bool? value) {
                                            setState(() {
                                              for (int i = 0; i < widget.profiles.length; i++) {
                                                if (i == index) {
                                                  widget.profiles[i].isSelected = value!;
                                                } else {
                                                  widget.profiles[i].isSelected = false;
                                                }
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                      Tooltip(
                                        message: 'Click To Delete - ${widget.profiles[index].name}',
                                        child: IconButton(
                                          icon: Icon(Icons.delete),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) {
                                                return DeleteProfileDialog(context, widget.profiles, index, setState);
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.pushAndRemoveUntil(
                                        context, RightToLeftPageRoute(page: EditProfilePage(profileName: widget.profiles[index].name, backToProfile: false)), (Route<dynamic> route) => false);
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: standardSizedBoxHeight),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Tooltip(
                      message: 'Create A New Profile',
                      child: IconButton(
                        icon: Icon(Icons.add_circle_outline_rounded),
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(context, RightToLeftPageRoute(page: NewProfilePage(backToProfile: false)), (Route<dynamic> route) => false);
                        },
                      ),
                    ),
                    Tooltip(
                      message: 'Clear Selection For Profiles',
                      child: IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          for (int i = 0; i < widget.profiles.length; i++) {
                            setState(() {
                              widget.profiles[i].isSelected = false;
                            });
                          }
                        },
                      ),
                    )
                  ],
                ),
              ],
            )
          : Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 4 * standardSizedBoxHeight),
                  Text(
                    'No Previous Profiles',
                    style: TextStyle(
                      fontSize: secondaryTitles,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4 * standardSizedBoxHeight),
                  CircularProgressIndicator(),
                  SizedBox(height: 4 * standardSizedBoxHeight),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Tooltip(
                        message: 'Create A New Profile',
                        child: IconButton(
                          icon: Icon(Icons.add_circle_outline_rounded),
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(context, RightToLeftPageRoute(page: NewProfilePage(backToProfile: false)), (Route<dynamic> route) => false);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
