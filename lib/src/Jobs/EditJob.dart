import 'package:flutter/material.dart';
import 'package:taylord_portfolio/src/Context/Globals/GlobalContext.dart';
import '../Context/Jobs/EditJobContext.dart';
import '../Utilities/JobUtils.dart';

class EditJobPage extends StatefulWidget {
  late String jobName;
  final bool backToJobs;
  EditJobPage({
    super.key,
    required this.jobName,
    this.backToJobs = true,
  });

  @override
  EditJobPageState createState() => EditJobPageState();
}

class EditJobPageState extends State<EditJobPage> {
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
      appBar: EditJobAppBar(context, widget.jobName, widget.backToJobs),
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
            return EditJobContent(context, previousJob, keyList, widget.backToJobs);
          }
        },
      ),
      bottomNavigationBar: FutureBuilder<Job>(
        future: previousJob,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            return BottomNav(context);
          } else {
            return Container();
          }
        },
      ),
    );
  }
}
