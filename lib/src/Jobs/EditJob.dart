import 'package:flutter/material.dart';
import '../Context/Jobs/EditJobContext.dart';
import '../Utilities/JobUtils.dart';

class EditJobPage extends StatelessWidget {
  // Job Name
  final String jobName;
  const EditJobPage({required this.jobName, super.key});
  @override
  // Main Widget
  Widget build(BuildContext context) {
    Job prevJob = Job(name: jobName);
    prevJob.LoadJobData();
    return Scaffold(
      appBar: appBar(context, prevJob),
      body: editJobContent(context, prevJob),
      bottomNavigationBar: bottomAppBar(context, prevJob),
    );
  }
}
