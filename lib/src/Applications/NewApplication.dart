import 'package:flutter/material.dart';
import '../Context/Globals/GlobalContext.dart';
import '../Utilities/ApplicationsUtils.dart';
import '../Context/Applications/NewApplicationContext.dart';

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
      body: NewApplicationContent(context, widget.newApp, updateState, finishedRecs),
      bottomNavigationBar: BottomNav(context),
    );
  }
}
