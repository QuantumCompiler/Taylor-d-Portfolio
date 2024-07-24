import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../Applications/Applications.dart';
import '../../Globals/Globals.dart';
import '../../Jobs/Jobs.dart';
import '../../Profiles/Profiles.dart';
import '../../Utilities/GlobalUtils.dart';
import '../../Utilities/JobUtils.dart';
import '../../Utilities/ProfilesUtils.dart';

AlertDialog GenAlertDialogWithIcon(String title, String content, IconData? icon) {
  return AlertDialog(
    title: Text(
      title,
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    ),
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 50.0,
        ),
        SizedBox(height: standardSizedBoxHeight),
        Text(content),
      ],
    ),
  );
}

AlertDialog NewProfileDialog(BuildContext context, Profile profile, bool? backToProfile, TextEditingController nameController) {
  return AlertDialog(
    title: Text(
      'Save New Profile',
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    ),
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Choose A Name For Your New Profile',
          style: TextStyle(
            fontSize: secondaryTitles,
          ),
          textAlign: TextAlign.center,
        ),
        TextFormField(
          controller: nameController,
          keyboardType: TextInputType.multiline,
          maxLines: 1,
          decoration: InputDecoration(hintText: 'Enter name here...'),
        ),
      ],
    ),
    actions: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          SizedBox(width: standardSizedBoxWidth),
          ElevatedButton(
            child: Text('Save Profile'),
            onPressed: () async {
              final masterDir = await getApplicationDocumentsDirectory();
              final currDir = Directory('${masterDir.path}/Profiles/${nameController.text}');
              if (await currDir.exists()) {
                Navigator.of(context).pop();
                await showDialog(
                  context: context,
                  builder: (context) {
                    return GenAlertDialogWithIcon(
                      "Profile ${nameController.text} Already Exists!",
                      "Please select a different name for this profile",
                      Icons.error,
                    );
                  },
                );
              } else {
                try {
                  await profile.CreateProfile(nameController.text);
                  if (backToProfile == true) {
                    Navigator.pushAndRemoveUntil(context, LeftToRightPageRoute(page: ProfilePage()), (Route<dynamic> route) => false);
                  } else if (backToProfile == false) {
                    Navigator.pushAndRemoveUntil(context, LeftToRightPageRoute(page: ApplicationsPage()), (Route<dynamic> route) => false);
                  }
                  await showDialog(
                      context: context,
                      builder: (context) {
                        return GenAlertDialogWithIcon(
                          'Profile ${profile.name}',
                          'Written Successfully',
                          Icons.check_circle_outline,
                        );
                      });
                } catch (e) {
                  await showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('Error'),
                        content: Text('An error occurred while creating the profile. Please try again. $e'),
                        actions: [
                          ElevatedButton(
                            child: Text('OK'),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      );
                    },
                  );
                }
              }
            },
          ),
        ],
      ),
    ],
  );
}

AlertDialog DeleteJobDialog(BuildContext context, List<Job> jobs, int index, Function setState) {
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
}

AlertDialog DeleteProfileDialog(BuildContext context, List<Profile> profiles, int index, Function setState) {
  return AlertDialog(
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Delete Profile ${profiles[index].name}?',
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
          'Are you sure that you would like to delete this profile?\nThis cannot be undone.',
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
                  await DeleteProfile(profiles[index].name);
                  setState(
                    () {
                      profiles.removeAt(index);
                    },
                  );
                  Navigator.of(context).pop();
                } catch (e) {
                  throw ('Error in deleting ${profiles[index].name}');
                }
              },
            ),
          ],
        ),
      ],
    ),
  );
}

AlertDialog EditJobDialog(BuildContext context, Job job, bool? backToJobs) {
  return AlertDialog(
    title: Text(
      'Overwrite Job',
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    ),
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Choose A Name For Your Job',
          style: TextStyle(
            fontSize: secondaryTitles,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: standardSizedBoxHeight),
        TextFormField(
          controller: job.nameController,
          keyboardType: TextInputType.multiline,
          maxLines: 1,
          decoration: InputDecoration(hintText: 'Enter name here...'),
        ),
      ],
    ),
    actions: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          SizedBox(width: standardSizedBoxWidth),
          ElevatedButton(
            child: Text('Overwrite Job'),
            onPressed: () async {
              try {
                await job.CreateJob(job.nameController.text);
                if (backToJobs == true) {
                  Navigator.pushAndRemoveUntil(context, LeftToRightPageRoute(page: JobsPage()), (Route<dynamic> route) => false);
                } else if (backToJobs == false) {
                  Navigator.pushAndRemoveUntil(context, LeftToRightPageRoute(page: ApplicationsPage()), (Route<dynamic> route) => false);
                }
                await showDialog(
                  context: context,
                  builder: (context) {
                    return GenAlertDialogWithIcon(
                      "Job ${job.name}",
                      "Written Successfully",
                      Icons.check_circle_outline,
                    );
                  },
                );
              } catch (e) {
                throw ("Error occurred in overwriting ${job.nameController.text} job");
              }
            },
          ),
        ],
      )
    ],
  );
}

AlertDialog EditProfileDialog(BuildContext context, Profile profile, bool? backToProfile) {
  return AlertDialog(
    title: Text(
      'Overwrite Profile',
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    ),
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Choose A Name For Your Profile',
          style: TextStyle(
            fontSize: secondaryTitles,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: standardSizedBoxHeight),
        TextFormField(
          controller: profile.nameController,
          keyboardType: TextInputType.multiline,
          maxLines: 1,
          decoration: InputDecoration(hintText: 'Enter name here...'),
        ),
      ],
    ),
    actions: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          SizedBox(width: standardSizedBoxWidth),
          ElevatedButton(
            child: Text('Overwrite Profile'),
            onPressed: () async {
              try {
                await profile.CreateProfile(profile.nameController.text);
                if (backToProfile == true) {
                  Navigator.pushAndRemoveUntil(context, LeftToRightPageRoute(page: ProfilePage()), (Route<dynamic> route) => false);
                } else if (backToProfile == false) {
                  Navigator.pushAndRemoveUntil(context, LeftToRightPageRoute(page: ApplicationsPage()), (Route<dynamic> route) => false);
                }
                await showDialog(
                  context: context,
                  builder: (context) {
                    return GenAlertDialogWithIcon(
                      "Profile ${profile.name}",
                      "Written Successfully",
                      Icons.check_circle_outline,
                    );
                  },
                );
              } catch (e) {
                throw ("Error occurred in overwriting ${profile.nameController.text} profile");
              }
            },
          ),
        ],
      )
    ],
  );
}

AlertDialog NewJobDialog(BuildContext context, Job job, bool? backToJobs, TextEditingController nameController) {
  return AlertDialog(
    title: Text(
      'Save New Job',
      style: TextStyle(
        fontSize: appBarTitle,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    ),
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Choose A Name For Your New Job',
          style: TextStyle(
            fontSize: secondaryTitles,
          ),
          textAlign: TextAlign.center,
        ),
        TextFormField(
          controller: nameController,
          keyboardType: TextInputType.multiline,
          maxLines: 1,
          decoration: InputDecoration(hintText: 'Enter name here...'),
        ),
      ],
    ),
    actions: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          SizedBox(width: standardSizedBoxWidth),
          ElevatedButton(
            child: Text('Save Job'),
            onPressed: () async {
              final masterDir = await getApplicationDocumentsDirectory();
              final currDir = Directory('${masterDir.path}/Jobs/${nameController.text}');
              if (await currDir.exists()) {
                Navigator.of(context).pop();
                await showDialog(
                  context: context,
                  builder: (context) {
                    return GenAlertDialogWithIcon(
                      "Job ${nameController.text} Already Exists!",
                      "Please select a different name for this job",
                      Icons.error,
                    );
                  },
                );
              } else {
                try {
                  await job.CreateJob(nameController.text);
                  if (backToJobs == true) {
                    Navigator.pushAndRemoveUntil(context, LeftToRightPageRoute(page: JobsPage()), (Route<dynamic> route) => false);
                  } else if (backToJobs == false) {
                    Navigator.pushAndRemoveUntil(context, LeftToRightPageRoute(page: ApplicationsPage()), (Route<dynamic> route) => false);
                  }
                  await showDialog(
                      context: context,
                      builder: (context) {
                        return GenAlertDialogWithIcon(
                          'Job ${job.name}',
                          'Written Successfully',
                          Icons.check_circle_outline,
                        );
                      });
                } catch (e) {
                  await showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('Error'),
                        content: Text('An error occurred while creating the job. Please try again. $e'),
                        actions: [
                          ElevatedButton(
                            child: Text('OK'),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      );
                    },
                  );
                }
              }
            },
          ),
        ],
      ),
    ],
  );
}

Future<DateTime?> SelectDate(BuildContext context) async {
  final DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(1900),
    lastDate: DateTime(3000),
  );
  if (pickedDate != null) {
    return DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
  }
  return DateTime.now();
}

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> GenSnackBar(BuildContext context, String content) {
  return ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            content,
          ),
        ],
      ),
      duration: Duration(seconds: 1),
    ),
  );
}
