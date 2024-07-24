import 'package:flutter/material.dart';
import '../Context/Applications/NewApplicationContext.dart';
import '../Globals/Globals.dart';
// import '../Utilities/ApplicationsUtils.dart';
// import '../Utilities/JobUtils.dart';
// import '../Utilities/ProfilesUtils.dart';

class NewApplicationPage extends StatefulWidget {
  const NewApplicationPage({super.key});

  @override
  NewApplicationPageState createState() => NewApplicationPageState();
}

class NewApplicationPageState extends State<NewApplicationPage> {
  List<DropdownMenuEntry> menuEntries = openAIEntries;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NewApplicationAppBar(context),
      body: NewApplicationContent(context, openAIEntries),
    );
  }
}
