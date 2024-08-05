import 'package:flutter/material.dart';
import '../Utilities/ApplicationsUtils.dart';
import '../Context/Applications/NewApplicationContext.dart';
// import '../Utilities/ApplicationsUtils.dart';
// import '../Utilities/JobUtils.dart';
// import '../Utilities/ProfilesUtils.dart';

class NewApplicationPage extends StatefulWidget {
  final Application newApp;
  const NewApplicationPage({
    super.key,
    required this.newApp,
  });

  @override
  NewApplicationPageState createState() => NewApplicationPageState();
}

class NewApplicationPageState extends State<NewApplicationPage> {
  bool finishedRecs = false;

  void updateState() {
    setState(() {
      finishedRecs = !finishedRecs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NewApplicationAppBar(context),
      body: finishedRecs ? NewApplicationRecsContent(context, widget.newApp, updateState) : NewApplicationContent(context, widget.newApp, updateState),
      bottomNavigationBar: finishedRecs ? NewApplicationCompileBottomAppBar(context, widget.newApp, updateState) : NewApplicationBottomAppBar(context, widget.newApp, updateState),
    );
  }
}
