import 'package:flutter/material.dart';
import '../Context/JobContext.dart';

class JobsPage extends StatelessWidget {
  const JobsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: jobsContent(context),
    );
  }
}
