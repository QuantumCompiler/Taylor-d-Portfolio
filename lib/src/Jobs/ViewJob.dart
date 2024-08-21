import 'package:flutter/material.dart';
import '../Context/Jobs/ViewJobContext.dart';
import '../Utilities/ApplicationsUtils.dart';
import '../Utilities/JobUtils.dart';

class ViewJobPage extends StatefulWidget {
  late String jobName;
  late Application app;
  ViewJobPage({
    super.key,
    required this.app,
    required this.jobName,
  });

  @override
  ViewJobPageState createState() => ViewJobPageState();
}

class ViewJobPageState extends State<ViewJobPage> {
  late Future<Job> previousJob;
  late List<GlobalKey> keyList;

  @override
  void initState() {
    super.initState();
    keyList = [];
    previousJob = Job.Init(name: widget.jobName, newJob: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ViewJobAppBar(context, widget.jobName, widget.app),
      body: FutureBuilder<Job>(
        future: previousJob,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('No Job Data Found'));
          } else {
            final previousJob = snapshot.data!;
            final GlobalKey<DescriptionJobEntryState> jobDescriptionKey = GlobalKey<DescriptionJobEntryState>();
            final GlobalKey<OtherInfoJobEntryState> otherInfoKey = GlobalKey<OtherInfoJobEntryState>();
            final GlobalKey<RoleJobEntryState> roleKey = GlobalKey<RoleJobEntryState>();
            final GlobalKey<SkillsJobEntryState> skillsKey = GlobalKey<SkillsJobEntryState>();
            keyList.add(jobDescriptionKey);
            keyList.add(otherInfoKey);
            keyList.add(roleKey);
            keyList.add(skillsKey);
            return ViewJobContent(context, previousJob, keyList);
          }
        },
      ),
    );
  }
}
