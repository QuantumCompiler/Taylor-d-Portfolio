import 'package:flutter/material.dart';
import 'Context/ApplicationsContext.dart';

class ApplicationsPage extends StatelessWidget {
  const ApplicationsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: applicationsContent(context),
    );
  }
}
