import 'package:flutter/material.dart';
import 'Context/NewJobContext.dart';
import '../Utilities/JobUtils.dart';

class NewJobPage extends StatelessWidget {
  const NewJobPage({super.key});
  @override
  Widget build(BuildContext context) {
    Job newJob = Job();
    return Scaffold(
      appBar: appBar(context),
      body: newJobContent(context, newJob),
      bottomNavigationBar: bottomAppBar(context, newJob),
    );
  }
}
