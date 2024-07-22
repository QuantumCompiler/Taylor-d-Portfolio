import 'package:flutter/material.dart';
import '../Context/Jobs/JobContentContext.dart';
import '../Globals/Globals.dart';
import '../Utilities/JobUtils.dart';

class JobContentPage extends StatelessWidget {
  final Job job;
  final String title;
  final JobContentType type;
  final List<GlobalKey> keyList;
  const JobContentPage({
    super.key,
    required this.job,
    required this.title,
    required this.type,
    required this.keyList,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: JobContentAppBar(context, type, job.name),
      body: JobContentEntry(job: job, type: type, keyList: keyList),
      bottomNavigationBar: JobContentBottomAppBar(context, type, job, keyList),
    );
  }
}
