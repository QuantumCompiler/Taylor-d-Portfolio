import 'package:flutter/material.dart';
import '../Context/Jobs/NewJobContext.dart';
import '../Utilities/JobUtils.dart';

class NewJobPage extends StatefulWidget {
  const NewJobPage({super.key});

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
      appBar: NewJobAppBar(context),
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
            keyList.add(jobDescriptionKey);
            keyList.add(otherInfoKey);
            keyList.add(roleKey);
            return NewJobContent(context, newJob, keyList);
          }
        },
      ),
    );
  }
}
