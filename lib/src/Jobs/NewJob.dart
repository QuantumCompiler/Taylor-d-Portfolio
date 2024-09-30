import 'package:flutter/material.dart';
import '../Context/Globals/GlobalContext.dart';
import '../Context/Jobs/NewJobContext.dart';
import '../Utilities/JobUtils.dart';

class NewJobPage extends StatefulWidget {
  final bool backToJobs;
  const NewJobPage({
    super.key,
    this.backToJobs = true,
  });

  @override
  NewJobPageState createState() => NewJobPageState();
}

class NewJobPageState extends State<NewJobPage> {
  late Future<Job> futureJob;
  late List<GlobalKey> keyList;

  @override
  void initState() {
    super.initState();
    keyList = [];
    futureJob = Job.Init(newJob: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NewJobAppBar(context, widget.backToJobs),
      body: FutureBuilder<Job>(
        future: futureJob,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('No Job Found'));
          } else {
            Job newJob = snapshot.data!;
            final GlobalKey<DescriptionJobEntryState> jobDescriptionKey = GlobalKey<DescriptionJobEntryState>();
            final GlobalKey<OtherInfoJobEntryState> otherInfoKey = GlobalKey<OtherInfoJobEntryState>();
            final GlobalKey<RoleJobEntryState> roleKey = GlobalKey<RoleJobEntryState>();
            final GlobalKey<SkillsJobEntryState> skillsKey = GlobalKey<SkillsJobEntryState>();
            keyList.add(jobDescriptionKey);
            keyList.add(otherInfoKey);
            keyList.add(roleKey);
            keyList.add(skillsKey);
            return NewJobContent(context, newJob, keyList, widget.backToJobs);
          }
        },
      ),
      bottomNavigationBar: FutureBuilder<Job>(
        future: futureJob,
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
