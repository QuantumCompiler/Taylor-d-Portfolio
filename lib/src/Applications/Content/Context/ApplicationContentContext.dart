import 'package:flutter/material.dart';
// import '../../Globals/ApplicationsGlobals.dart';
import '../../../Globals/Globals.dart';
import '../../../Themes/Themes.dart';

class JobListItem extends StatefulWidget {
  final String jobName;
  final bool isChecked;
  final Function(bool) onChanged;

  const JobListItem({
    Key? key,
    required this.jobName,
    required this.isChecked,
    required this.onChanged,
  }) : super(key: key);

  @override
  JobListItemState createState() => JobListItemState();
}

class JobListItemState extends State<JobListItem> {
  late bool isChecked;

  @override
  void initState() {
    super.initState();
    isChecked = widget.isChecked;
  }

  @override
  void didUpdateWidget(JobListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isChecked != widget.isChecked) {
      isChecked = widget.isChecked;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.jobName),
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

SliverToBoxAdapter jobsBoxSliver(BuildContext context) {
  return SliverToBoxAdapter(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 20),
        Text(
          'Select Job To Use In Application',
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

SliverList jobsSliverList(List<dynamic> jobs, Map<String, bool> checkedJobs, Function(String, bool) onChanged) {
  return SliverList(
    delegate: SliverChildBuilderDelegate(
      (context, index) {
        final jobName = jobs[index].path.split('/').last;
        checkedJobs.putIfAbsent(jobName, () => false);
        return ProfileListItem(
          profileName: jobName,
          isChecked: checkedJobs[jobName]!,
          onChanged: (value) {
            onChanged(jobName, value);
          },
        );
      },
      childCount: jobs.length,
    ),
  );
}

class ProfileListItem extends StatefulWidget {
  final String profileName;
  final bool isChecked;
  final Function(bool) onChanged;

  const ProfileListItem({
    Key? key,
    required this.profileName,
    required this.isChecked,
    required this.onChanged,
  }) : super(key: key);

  @override
  ProfileListItemState createState() => ProfileListItemState();
}

class ProfileListItemState extends State<ProfileListItem> {
  late bool isChecked;

  @override
  void initState() {
    super.initState();
    isChecked = widget.isChecked;
  }

  @override
  void didUpdateWidget(ProfileListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isChecked != widget.isChecked) {
      isChecked = widget.isChecked;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.profileName),
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

SliverToBoxAdapter profilesBoxSliver(BuildContext context) {
  return SliverToBoxAdapter(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 20),
        Text(
          'Select Profile To Use In Application',
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

SliverList profilesSliverList(List<dynamic> profiles, Map<String, bool> checkedProfiles, Function(String, bool) onChanged) {
  return SliverList(
    delegate: SliverChildBuilderDelegate(
      (context, index) {
        final profileName = profiles[index].path.split('/').last;
        checkedProfiles.putIfAbsent(profileName, () => false);
        return ProfileListItem(
          profileName: profileName,
          isChecked: checkedProfiles[profileName]!,
          onChanged: (value) {
            onChanged(profileName, value);
          },
        );
      },
      childCount: profiles.length,
    ),
  );
}
