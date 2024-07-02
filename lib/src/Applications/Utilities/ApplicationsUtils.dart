import 'dart:io';
import 'package:flutter/material.dart';
import '../Globals/ApplicationsGlobals.dart';
import '../../Dashboard/Dashboard.dart';
import '../../Jobs/Edit/EditJob.dart';
import '../../Globals/Globals.dart';
import '../../Profiles/Edit/EditProfile.dart';
import '../../Themes/Themes.dart';
import 'package:path/path.dart' as p;

class ApplicationContent {
  List<Directory> jobs;
  List<Directory> profiles;
  Map<String, bool> checkedJobs;
  Map<String, bool> checkedProfiles;

  ApplicationContent({
    required this.jobs,
    required this.profiles,
    required this.checkedJobs,
    required this.checkedProfiles,
  });

  void updateJobs(List<Directory> newJobs) {
    jobs = newJobs;
  }

  void updateProfiles(List<Directory> newProfiles) {
    profiles = newProfiles;
  }
}

class ApplicationContentList extends StatefulWidget {
  final ApplicationContent content;
  final Function refreshData;

  const ApplicationContentList({
    super.key,
    required this.content,
    required this.refreshData,
  });

  @override
  ApplicationContentListState createState() => ApplicationContentListState();
}

class ApplicationContentListState extends State<ApplicationContentList> {
  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void disableOthers(Map<String, bool> checkedItems, String selectedKey) {
    checkedItems.forEach(
      (key, value) {
        if (key != selectedKey) {
          checkedItems[key] = false;
        }
      },
    );
  }

  void updateChecked(Map<String, bool> items, bool value, String key) {
    setState(
      () {
        disableOthers(items, key);
        items[key] = value;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * applicationsContainerWidth,
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            boxSliver(context, 'Select Job To Use In Application'),
            sliverList(widget.content, widget.content.jobs, widget.content.checkedJobs, updateChecked, widget.refreshData),
            boxSliver(context, 'Select Profile To Use In Application'),
            sliverList(widget.content, widget.content.profiles, widget.content.checkedProfiles, updateChecked, widget.refreshData)
          ],
        ),
      ),
    );
  }
}

class ApplicationListItem extends StatefulWidget {
  final String name;
  final ApplicationContent content;
  final bool isChecked;
  final Function(bool) onChanged;
  final Function refreshData;

  const ApplicationListItem({
    super.key,
    required this.name,
    required this.content,
    required this.isChecked,
    required this.onChanged,
    required this.refreshData,
  });

  @override
  ApplicationListItemState createState() => ApplicationListItemState();
}

class ApplicationListItemState extends State<ApplicationListItem> {
  late bool isChecked;

  @override
  void initState() {
    super.initState();
    isChecked = widget.isChecked;
  }

  @override
  void didUpdateWidget(ApplicationListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isChecked != widget.isChecked) {
      isChecked = widget.isChecked;
    }
  }

  Future<void> updateJobsAndProfiles() async {
    await widget.refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.name),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) {
              if (isJob(widget.content, widget.name)) {
                return EditJobPage(jobName: widget.name);
              } else if (isProfile(widget.content, widget.name)) {
                return EditProfilePage(profileName: widget.name);
              } else {
                return Dashboard();
              }
            },
          ),
        );
        await updateJobsAndProfiles();
      },
      trailing: Checkbox(
        value: isChecked,
        onChanged: (bool? value) {
          if (value != null) {
            setState(() {
              isChecked = value;
            });
            widget.onChanged(value);
          }
        },
      ),
    );
  }
}

SliverToBoxAdapter boxSliver(BuildContext context, String title) {
  return SliverToBoxAdapter(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: standardSizedBoxHeight),
        Text(
          title,
          style: TextStyle(
            color: themeTextColor(context),
            fontSize: secondaryTitles,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: standardSizedBoxHeight),
      ],
    ),
  );
}

SliverList sliverList(ApplicationContent content, List<dynamic> items, Map<String, bool> checkedItems, Function(Map<String, bool>, bool, String) onChanged, Function refreshData) {
  return SliverList(
    delegate: SliverChildBuilderDelegate(
      (context, index) {
        final names = items[index].path.split('/').last;
        checkedItems.putIfAbsent(names, () => false);
        return ApplicationListItem(
          content: content,
          name: names,
          isChecked: checkedItems[names]!,
          onChanged: (value) {
            onChanged(checkedItems, value, names);
          },
          refreshData: refreshData,
        );
      },
      childCount: items.length,
    ),
  );
}

String? getCheckedItem(Map<String, bool> items) {
  String? checked;
  items.forEach(
    (key, value) {
      if (value) {
        checked = key;
      }
    },
  );
  return checked;
}

bool verifyValidInput(ApplicationContent content) {
  bool jobValid = content.checkedJobs.values.contains(true);
  bool profilesValid = content.checkedProfiles.values.contains(true);
  bool valid = jobValid && profilesValid;
  return valid;
}

bool isJob(ApplicationContent content, String name) {
  for (int i = 0; i < content.jobs.length; i++) {
    String jobPath = content.jobs[i].toString();
    String jobName = p.basename(jobPath).trim().replaceAll("'", "");
    if (jobName == name) {
      return true;
    }
  }
  return false;
}

bool isProfile(ApplicationContent content, String name) {
  for (int i = 0; i < content.profiles.length; i++) {
    String profilePath = content.profiles[i].toString();
    String profileName = p.basename(profilePath).trim().replaceAll("'", "");
    if (profileName == name) {
      return true;
    }
  }
  return false;
}
