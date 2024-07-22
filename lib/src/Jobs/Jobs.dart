import 'package:flutter/material.dart';
import '../Context/Jobs/JobsContext.dart';
import '../Utilities/GlobalUtils.dart';
import '../Utilities/JobUtils.dart';

class JobsPage extends StatefulWidget {
  const JobsPage({super.key});
  @override
  JobsPageState createState() => JobsPageState();
}

class JobsPageState extends State<JobsPage> {
  Future<List<Job>> jobsFuture = RetrieveSortedJobs();
  List<Job> jobs = [];

  Future<void> _refreshJobs() async {
    List<Job> updatedJobs = await RetrieveSortedJobs();
    if (mounted) {
      setState(() {
        jobs = updatedJobs;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _refreshJobs();
  }

  @override
  Widget build(BuildContext context) {
    _refreshJobs();
    return Scaffold(
      appBar: JobsAppBar(context, jobs),
      body: FutureBuilder<List<Job>>(
        future: jobsFuture,
        builder: (context, AsyncSnapshot<List<Job>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('No Data'));
          } else {
            jobs = snapshot.data!;
            return JobContent(context, jobs, setState);
          }
        },
      ),
    );
  }
}
