import 'package:flutter/material.dart';
import 'Context/ApplicationContentContext.dart';

class ApplicationContentList extends StatefulWidget {
  final List<dynamic> jobs;
  final List<dynamic> profiles;

  const ApplicationContentList({
    super.key,
    required this.jobs,
    required this.profiles,
  });

  @override
  ApplicationContentListState createState() => ApplicationContentListState();
}

class ApplicationContentListState extends State<ApplicationContentList> {
  Map<String, bool> checkedJobs = {};
  Map<String, bool> checkedProfiles = {};
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
    checkedItems.forEach((key, value) {
      if (key != selectedKey) {
        checkedItems[key] = false;
      }
    });
  }

  void updateCheckedProfiles(String profileName, bool value) {
    setState(() {
      disableOthers(checkedProfiles, profileName);
      checkedProfiles[profileName] = value;
    });
  }

  void updateCheckedJobs(String jobName, bool value) {
    setState(() {
      disableOthers(checkedJobs, jobName);
      checkedJobs[jobName] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final jobs = widget.jobs;
    final profiles = widget.profiles;

    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            jobsBoxSliver(context),
            jobsSliverList(jobs, checkedJobs, updateCheckedJobs),
            profilesBoxSliver(context),
            profilesSliverList(profiles, checkedProfiles, updateCheckedProfiles),
          ],
        ),
      ),
    );
  }
}
